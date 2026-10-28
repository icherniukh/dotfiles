#!/usr/bin/env python3
"""Check Bash 3 staging, ignored files, cleanup and hk status propagation."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="hk-staging-check-") as directory:
    work = Path(directory)
    repo, scratch, home, binaries = (work / name for name in ("repo", "tmp", "home", "bin"))
    for path in (repo, scratch, home, binaries):
        path.mkdir()
    scripts = repo / "dot_scripts"
    scripts.mkdir()
    for name in ("hk-chezmoi-staging", "hk-dotfiles-secrets"):
        shutil.copy2(ROOT / "dot_scripts" / ("executable_" + name), scripts)
    config = repo / "dot_config"
    config.mkdir()
    (repo / "hk.pkl").write_text("// fixture\n")
    (repo / ".gitignore").write_text("*.secret\n")
    (config / "tracked.conf").write_text("tracked\n")
    (config / "space file.conf").write_text("untracked\n")
    (config / "ignored.secret").write_text("never copy\n")
    (config / "notes.md").write_text("excluded documentation\n")
    (config / "external-link").symlink_to(config / "ignored.secret")
    env = {**os.environ, "HOME": str(home), "TMPDIR": str(scratch),
           "PATH": str(binaries) + os.pathsep + os.environ["PATH"],
           "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
           "HK_DOTFILES_ROOT": str(repo), "HK_TEST_LOG": str(work / "calls")}
    subprocess.run(["git", "init", "-q", str(repo)], env=env, check=True)
    subprocess.run(["git", "-C", str(repo), "add", "dot_config/tracked.conf"], env=env, check=True)
    stage_command = ["/bin/bash", str(scripts / "executable_hk-chezmoi-staging"), str(repo)]
    stage = Path(subprocess.check_output(stage_command, env=env, text=True).strip())
    try:
        assert (stage / "dot_config/tracked.conf").read_text() == "tracked\n"
        assert (stage / "dot_config/space file.conf").read_text() == "untracked\n"
        for name in ("ignored.secret", "notes.md", "external-link"):
            assert not (stage / "dot_config" / name).exists(), name
    finally:
        shutil.rmtree(stage)
    stub = binaries / "hk"
    stub.write_text('''#!/bin/sh
printf '%s\n%s\n' "$PWD" "$*" > "$HK_TEST_LOG"
exit "$HK_TEST_STATUS"
''')
    stub.chmod(0o755)
    wrapper = ["/bin/bash", str(scripts / "executable_hk-dotfiles-secrets")]
    for args, expected in (([], "check --step gitleaks --step detect_private_key --all"),
                           (["check", "--all"], "check --all"),
                           (["--all"], "check --all")):
        for status in (0, 7):
            result = subprocess.run(wrapper + args, env={**env, "HK_TEST_STATUS": str(status)},
                                    capture_output=True, text=True)
            assert result.returncode == status, result.stderr
            location, actual = (work / "calls").read_text().splitlines()
            assert actual == expected and Path(location).parent == scratch
            assert not Path(location).exists(), "wrapper leaked its staging directory"
            assert not list(scratch.iterdir())
    result = subprocess.run(stage_command[:-1] + [str(work / "missing")], env=env, capture_output=True)
    assert result.returncode and not list(scratch.iterdir()), "staging failure must clean up"

print("hk staging: PASS (Bash 3, tracked/untracked, ignored files, symlinks, cleanup, status)")
