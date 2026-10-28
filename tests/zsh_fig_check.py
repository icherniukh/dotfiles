#!/usr/bin/env python3
"""Check FIGlet helpers with stubbed binaries and an isolated shell."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory(prefix="zsh-fig-") as directory:
    home = Path(directory)
    fonts = home / "fonts"
    fonts.mkdir()
    (fonts / "fixture.flf").touch()
    log = home / "calls"
    stub = f"""#!{sys.executable}
import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
with open(os.environ['FIG_TEST_LOG'], 'a') as log:
    log.write(json.dumps([name, *sys.argv[1:]]) + '\\n')
if name == 'figlet':
    if sys.argv[1:] == ['-I2']:
        print(os.environ['FIG_TEST_FONTS'])
    else:
        print('BANNER')
    sys.exit(int(os.environ.get('FIG_TEST_STATUS', '0')))
sys.stdout.write(sys.stdin.read())
"""
    for name in ("figlet", "lolcat"):
        target = home / name
        target.write_text(stub)
        target.chmod(0o755)
    env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
           "PATH": str(home) + os.pathsep + os.environ["PATH"], "COLUMNS": "91",
           "FIG_TEST_LOG": str(log), "FIG_TEST_FONTS": str(fonts)}

    def run(command, status=0):
        log.write_text("")
        result = subprocess.run(["zsh", "-fc", 'source "$1"; ' + command, "--",
                                 str(ROOT / "dot_config/zsh/functions.zsh")],
                                input="piped input", text=True, capture_output=True, env=env)
        assert result.returncode == status, result.stderr
        return result, [json.loads(line) for line in log.read_text().splitlines()]

    result, calls = run("fig -l")
    assert "slant" in result.stdout and not calls
    result, calls = run("fig -f doom hello")
    assert ["figlet", "-w", "91", "-c", "-f", "doom", "hello"] in calls
    assert result.stdout == "BANNER\n"
    _, calls = run("fig -a -A hello")
    assert ["figlet", "-w", "91", "-c", "-f", "fixture", "hello"] in calls
    assert any(call[0] == "lolcat" and "-a" in call for call in calls)
    _, calls = run("fig")
    assert any(call[0] == "figlet" and call[-1] != "hello" for call in calls)
    run("fig -f", 2)
    run("fig --invalid", 2)
    env["FIG_TEST_STATUS"] = "7"
    run("fig -f doom hello", 7)

print("FIGlet helpers: PASS (fonts, flags, stdin, width, pipeline failure)")
