#!/usr/bin/env python3
"""Exercise real ZLE with temporary HOME/XDG paths and an isolated tmux server.

Uses installed tools and an existing autosuggestions script; never installs plugins.
Set ZSH_AUTOSUGGESTIONS_FILE if the script is outside Antidote's default cache.
"""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
ENV = {
    key: value for key, value in os.environ.items()
    if key not in {"TMUX", "HISTFILE", "ZDOTDIR", "FPATH", "TERM_PROGRAM", "GHOSTTY_RESOURCES_DIR"}
    and not key.startswith(("ZSH_", "FZF_"))
}


def tmux(*args):
    return subprocess.check_output(
        ["tmux", "-S", SOCKET, "-f", "/dev/null", *args], env=ENV, text=True
    )


def screen():
    return tmux("capture-pane", "-p", "-t", "test").rstrip()


def wait_for(predicate, description):
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        value = screen()
        if predicate(value):
            return value
        time.sleep(0.05)
    raise AssertionError(f"{description}\n{screen()}")


def keys(*args):
    tmux("send-keys", "-t", "test", *args)


with tempfile.TemporaryDirectory(prefix="zle-") as directory:
    work = Path(directory)
    SOCKET = str(work / "tmux.sock")
    cache = (Path.home() / "Library/Caches" if sys.platform == "darwin"
             else Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")))
    antidote = Path(os.environ.get("ANTIDOTE_HOME", cache / "antidote"))
    autosuggestions = Path(os.environ.get(
        "ZSH_AUTOSUGGESTIONS_FILE",
        antidote / "github.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh",
    )).expanduser()
    if not autosuggestions.is_file():
        raise SystemExit("Set ZSH_AUTOSUGGESTIONS_FILE to an installed zsh-autosuggestions.zsh")
    shutil.copyfile(autosuggestions, work / "autosuggestions.zsh")
    multi_word = Path(os.environ.get(
        "ZSH_HISTORY_SEARCH_MULTI_WORD_DIR",
        antidote / "github.com/zdharma-continuum/history-search-multi-word",
    )).expanduser()
    if not (multi_word / "history-search-multi-word.plugin.zsh").is_file():
        raise SystemExit("Set ZSH_HISTORY_SEARCH_MULTI_WORD_DIR to an installed history-search-multi-word")
    shutil.copytree(multi_word, work / "multi-word", ignore=shutil.ignore_patterns(".git", "test"))
    substring_search = Path(os.environ.get(
        "ZSH_HISTORY_SUBSTRING_SEARCH_FILE",
        antidote / "github.com/zsh-users/zsh-history-substring-search/zsh-history-substring-search.zsh",
    )).expanduser()
    if not substring_search.is_file():
        raise SystemExit("Set ZSH_HISTORY_SUBSTRING_SEARCH_FILE to an installed zsh-history-substring-search.zsh")
    shutil.copyfile(substring_search, work / "substring-search.zsh")

    for variable, relative in {
        "HOME": "home", "XDG_CONFIG_HOME": "config", "XDG_CACHE_HOME": "cache",
        "XDG_STATE_HOME": "state", "XDG_DATA_HOME": "data", "XDG_RUNTIME_DIR": "run",
        "TMPDIR": "tmp", "TMUX_TMPDIR": "tmp",
    }.items():
        path = work / relative
        path.mkdir(mode=0o700, exist_ok=True)
        ENV[variable] = str(path)
    ENV["ZDOTDIR"] = ENV["HOME"]
    ENV["HISTFILE"] = str(work / "state/zsh/history")
    ENV["ANTIDOTE_HOME"] = str(work / "data/antidote")
    home = Path(ENV["HOME"])
    shutil.copyfile(ROOT / "dot_zshenv", home / ".zshenv")
    (home / ".zsh_plugins.txt").touch()
    bundle = work / "cache/zsh/plugins.zsh"
    bundle.parent.mkdir()
    bundle.write_text(f"source {shlex.quote(str(work / 'autosuggestions.zsh'))}\n"
                      f"source {shlex.quote(str(work / 'multi-word/history-search-multi-word.plugin.zsh'))}\n"
                      f"source {shlex.quote(str(work / 'substring-search.zsh'))}\n")
    fzf_config = work / "config/fzf/fzf.zsh"
    fzf_config.parent.mkdir()
    shutil.copyfile(ROOT / "dot_config/fzf/fzf.zsh", fzf_config)

    (work / "menu-alpha.txt").touch()
    (work / "menu-beta.txt").touch()
    init = work / "init.zsh"
    init.write_text(
        f"source {shlex.quote(str(ROOT / 'dot_config/zsh/env.zsh'))}\n"
        f"source {shlex.quote(str(ROOT / 'dot_config/zsh/options.zsh'))}\n"
        f"ZSH_CONFIG_DIR={shlex.quote(str(ROOT / 'dot_config/zsh'))}\n"
        'source "$ZSH_CONFIG_DIR/plugins.zsh"\n'
        f"fc -p {shlex.quote(str(work / 'history'))} 10000 10000\n"
        # Test ranking with deliberately conflicting recent and contextual matches.
        "print -s context-one; print -s 'echo chosen-context'; print -s context-two\n"
        "print -s 'echo chosen-recent'; print -s context-one; print -s placeholder\n"
        "_zsh_autosuggest_fetch_suggestion 'echo chosen-'\n"
        "[[ $suggestion == 'echo chosen-context' ]] || return 1\n"
        # Rendering tests below inspect literal screen contents, without gray hints.
        "ZSH_AUTOSUGGEST_STRATEGY=()\n"
        # Reproduce the late integration which used to steal Ctrl-R.
        'if command -v tv >/dev/null; then eval "$(tv init zsh)"; fi\n'
        f"cd {shlex.quote(directory)}\n"
        "PS1='TEST> '; RPROMPT=; bindkey -e; clear\n"
    )
    try:
        tmux("new-session", "-d", "-c", directory, "-x", "100", "-y", "30", "-s", "test", "zsh -f")
        keys(f"source {shlex.quote(str(init))}", "Enter")
        wait_for(lambda s: s == "TEST>", "shell initialization")
        keys("cat menu-", "Tab")
        wait_for(lambda s: "menu-alpha.txt" in s and "menu-beta.txt" in s, "file menu")
        keys("Escape")
        wait_for(lambda s: len(s.splitlines()) == 1 and s.startswith("TEST> cat menu-"),
                 "Escape must erase the list")
        keys("C-u", "cat newborn-", "Tab")
        wait_for(lambda s: s == "TEST> cat newborn-", "initial missing file")
        # Allow the no-match attempt to finish before creating a new file.
        time.sleep(0.3)
        (work / "newborn-file.txt").touch()
        keys("Tab")
        wait_for(lambda s: s == "TEST> cat newborn-file.txt", "new file on next Tab")
        keys("C-u", "cat menu-", "Tab", "Tab")
        wait_for(lambda s: "menu-alpha.txt" in s and "menu-beta.txt" in s, "menu selection")
        (work / "menu-gamma.txt").touch()
        keys("Escape")
        wait_for(lambda s: len(s.splitlines()) == 1 and "──" not in s, "selection dismissal")
        # A later Tab must see files created while a previous list was displayed.
        keys("C-u", "cat menu-", "Tab")
        wait_for(lambda s: "menu-gamma.txt" in s, "fresh listing after dismissal")
        if shutil.which("hunk"):
            keys("Escape", "C-u", "hunk --", "Tab")
            wait_for(lambda s: "--experimental" in s and "--version" in s, "Hunk native flags")
            keys("Escape", "C-u", "hunk diff --", "Tab")
            wait_for(lambda s: "--staged" in s and "--cached" in s, "Hunk diff flags")
        keys("Escape", "C-u", "claude --", "Tab")
        wait_for(lambda s: "--add-dir" in s and "--agent" in s, "Claude flags from --help")
        keys("Escape")
        wait_for(lambda s: len(s.splitlines()) == 1 and s.startswith("TEST> claude "),
                 "long menu dismissal")
        keys("C-u", "composio --", "Tab")
        wait_for(lambda s: "--help" in s and "--log-level" in s, "Composio flags from --help")
        # Up cycles plain history and ignores the typed text.
        keys("Escape", "C-u", "echo chosen-", "Up")
        wait_for(lambda s: s == "TEST> placeholder", "Up recalls the newest command, not a match")
        keys("Up")
        wait_for(lambda s: s == "TEST> context-one", "Up steps to the previous command")
        keys("C-u", "C-r", "chosen-")
        wait_for(lambda s: "echo chosen-recent" in s and "echo chosen-context" in s
                 and s.index("echo chosen-recent") < s.index("echo chosen-context"),
                 "Ctrl-R lists every match below the prompt, newest first, after late tv init")
        keys("Enter")
        wait_for(lambda s: s == "TEST> echo chosen-recent", "Enter puts the selected match on the line")
        keys("C-u")
        wait_for(lambda s: s == "TEST>", "line cleared after history search")
        keys(f"{{ bindkey '^R'; bindkey '^[[A' }} > {shlex.quote(str(work / 'bindings'))}", "Enter")
        wait_for(lambda s: (work / "bindings").exists(), "history binding probe")
        bindings = (work / 'bindings').read_text()
        assert 'history-search-multi-word' in bindings, bindings
        assert '_up_line_or_local_history' in bindings, bindings
        print("Completion/history UI: PASS (Escape, fresh files, flags, contextual suggestion, "
              "plain Up, multi-word Ctrl-R list)")
    finally:
        subprocess.run(
            ["tmux", "-S", SOCKET, "kill-server"], env=ENV, capture_output=True
        )
