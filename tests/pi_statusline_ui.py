#!/usr/bin/env python3
"""Exercise the managed footer in real, network-denied Pi; never send a prompt."""
import argparse
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import time

SOURCE = Path(__file__).resolve().parents[1] / "dot_pi" / "agent"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--candidate", type=Path,
                    default=Path.home() / ".pi/agent/npm/node_modules/@sentixx/pi-info")
args = parser.parse_args()
pi = shutil.which("pi")
assert pi and shutil.which("tmux") and shutil.which("sandbox-exec"), "Requires Pi, tmux and macOS sandbox-exec"

# Check the modifier against synthetic settings, including versioned duplicates.
original = {"theme": "preserve", "other": {"keep": True}, "packages": [
    "npm:unrelated", {"source": "npm:@reedchan/statusline@1.11.3",
                      "extensions": ["extensions/statusline/index.ts"]},
    "npm:@sentixx/pi-info@0.7.0"]}
modifier = ["python3", str(SOURCE / "modify_settings.json")]
modified = subprocess.check_output(modifier, input=json.dumps(original).encode())
assert subprocess.check_output(modifier, input=modified) == modified
expected = {**original, "packages": ["npm:unrelated", "npm:@sentixx/pi-info@0.8.0"]}
assert json.loads(modified) == expected, "Modifier changed unrelated settings or kept duplicate footers"
assert json.loads(subprocess.check_output(modifier, input=b"")) == {
    "packages": ["npm:@sentixx/pi-info@0.8.0"]}, "Empty settings must initialize safely"
assert subprocess.run(modifier, input=b"{broken", capture_output=True).returncode, "Malformed settings must fail"

with tempfile.TemporaryDirectory(prefix="pi-statusline-") as directory:
    root = Path(directory).resolve()
    home = root / "home"
    agent = home / ".pi/agent"
    agent.mkdir(parents=True)
    repo = home / "footer-fixture"
    primary = home / "primary"
    git_env = {"HOME": str(home), "PATH": os.defpath,
               "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null"}
    def git(*parts):
        subprocess.run(["git", *parts], env=git_env, check=True)
    git("init", "-q", "-b", "fixture-main", str(primary))
    git("-C", str(primary), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
        "-c", "commit.gpgsign=false", "commit", "-q", "--allow-empty", "-m", "fixture")
    git("-C", str(primary), "worktree", "add", "-q", "-b", "fixture-branch", str(repo))
    assert (repo / ".git").is_file(), "Fixture must exercise a linked worktree"
    package = root / "pi-info"
    shutil.copytree(args.candidate, package)
    extensions = [package / "extensions/statusline.ts"]
    for name, entry in [("pi-sticky-header", "sticky-header.ts"), ("pi-pretty-tui", "extensions/index.ts")]:
        target = root / name
        shutil.copytree(Path.home() / ".pi/agent/npm/node_modules" / name, target)
        extensions.append(target / entry)
    shutil.copy2(SOURCE / "pi-info-renderer.ts", agent)
    config = (SOURCE / "pi-info.json.tmpl").read_text().replace("{{ .chezmoi.homeDir }}", str(home))
    (agent / "pi-info.json").write_text(config)
    (agent / "settings.json").write_text(json.dumps({
        "theme": "dark", "tuiMode": "fullscreen", "defaultThinkingLevel": "high",
        "lastChangelogVersion": "1.4.0", "collapseChangelog": True,
    }))
    fixture = root / "fixture.ts"
    fixture.write_text('''import { writeFileSync } from "node:fs";
export default function(pi) {
  pi.registerProvider("footer-fixture", {
    api: "openai-completions", baseUrl: "http://127.0.0.1:1", apiKey: "fake-offline-key",
    models: [{ id: "gpt-6.1-sol", name: "gpt-6.1-sol", reasoning: true,
      thinkingLevelMap: { xhigh: "xhigh" },
      input: ["text"], contextWindow: 200000, maxTokens: 8192,
      cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0} }],
    streamSimple() { writeFileSync(process.env.HOME + "/MODEL_CALLED", "ERROR");
      throw new Error("No model calls permitted in footer test"); },
  });
  pi.on("session_start", (_, ctx) => ctx.ui.setStatus("fixture", "fixture-status"));
  pi.registerCommand("effort", { handler: async (args) => { pi.setThinkingLevel(args.trim()); } });
}''')
    extensions.append(fixture)
    # OS enforcement supplements temporary HOME/XDG/agent-dir and --offline.
    profile = root / "sandbox.sb"
    profile.write_text(f'''(version 1)
(allow default)
(deny network*)
(deny file-write*)
(allow file-write* (subpath "{root}") (literal "/dev/null") (literal "/dev/tty"))
(deny file-read* (subpath "{Path.home() / '.pi'}") (subpath "{Path.home() / '.ssh'}") (subpath "{Path.home() / '.config'}"))
''')
    environment = {
        "HOME": str(home), "PI_CODING_AGENT_DIR": str(agent), "TMPDIR": str(root),
        "XDG_CONFIG_HOME": str(home / ".config"), "XDG_CACHE_HOME": str(home / ".cache"),
        "XDG_DATA_HOME": str(home / ".local/share"), "XDG_STATE_HOME": str(home / ".local/state"),
        "PATH": os.defpath, "TERM": "xterm-256color", "COLORTERM": "truecolor", "LANG": "en_US.UTF-8",
        "PI_SKIP_VERSION_CHECK": "1", "PI_OFFLINE": "1",
    }
    command = ["/usr/bin/env", "-i", *[f"{key}={value}" for key, value in environment.items()],
               "/usr/bin/sandbox-exec", "-f", str(profile), pi,
               "--offline", "--no-session", "--no-extensions", "--no-skills", "--no-prompt-templates",
               "--provider", "footer-fixture", "--model", "gpt-6.1-sol", "--thinking", "high"]
    for extension in extensions:
        command += ["-e", str(extension)]
    socket = str(root / "tmux.sock")

    def tmux(*parts):
        return subprocess.check_output(["tmux", "-S", socket, "-f", "/dev/null", *parts], text=True)

    def capture(ansi=False):
        return tmux("capture-pane", "-p", *( ["-e"] if ansi else []), "-t", "test:0.0")

    def wait_for(predicate, label, timeout=20):
        deadline = time.monotonic() + timeout
        text = ""
        while time.monotonic() < deadline:
            text = capture()
            if predicate(text):
                return text
            time.sleep(0.1)
        raise AssertionError(f"{label}\n{text}")

    def keys(*parts):
        tmux("send-keys", "-t", "test:0.0", *parts)

    try:
        tmux("new-session", "-d", "-s", "test", "-x", "160", "-y", "40", "-c", str(repo),
             shlex.join(command))
        text = wait_for(lambda s: all(part in s for part in (
            "gpt-6.1-sol:high", "fixture-branch", "footer-fixture", "fixture-status")),
            "Compact footer, git branch, or extension status did not load")
        assert "ctx " in text
        assert not re.search(r"\b(?:Last|Cost|Today|Input|Output|TTFT|Avg)\b", text), text
        assert not re.search(r"(?:error|failed|cannot find)", text, re.I), text
        # Effort uses a distinct ANSI color, not merely the model's cyan.
        ansi = capture(ansi=True)
        def effort_color(screen, level):
            match = re.search(r"gpt-6\.1-sol(?:\x1b\[[0-9;]*m)*:((?:\x1b\[[0-9;]*m)+)" + level, screen)
            assert match, screen
            return match[1]

        high_color = effort_color(ansi, "high")
        keys("/effort xhigh", "Enter")
        wait_for(lambda s: "gpt-6.1-sol:xhigh" in s, "Effort update not rendered")
        assert effort_color(capture(ansi=True), "xhigh") != high_color, "Effort colors must differ by level"
        keys("/reload", "Enter")
        text = wait_for(lambda s: "Reloaded" in s or "reloaded" in s, "Reload did not complete")
        assert "gpt-6.1-sol:xhigh" in text, text
        assert text.count("gpt-6.1-sol:xhigh") == 1, text
        assert not re.search(r"(?:error|failed|cannot find)", text, re.I), text
        tmux("resize-window", "-t", "test:0", "-x", "60", "-y", "30")
        wait_for(lambda s: "ctx " in s or "gpt-6.1" in s, "Narrow terminal did not render")
        keys("C-d")
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if subprocess.run(["tmux", "-S", socket, "has-session", "-t", "test"],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
                break
            time.sleep(0.1)
        else:
            raise AssertionError("Pi failed to exit cleanly")
        assert not (home / "MODEL_CALLED").exists(), "Unexpected model call"
        print("Pi statusline: PASS (isolated real Pi, worktree branch, colors, effort updates, reload, resize, clean exit; no model calls)")
    finally:
        subprocess.run(["tmux", "-S", socket, "kill-server"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
