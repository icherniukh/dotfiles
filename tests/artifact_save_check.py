#!/usr/bin/env python3
"""Save collisions and source failures must never replace earlier artifacts."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "dot_scripts/executable_artifact-save"
ZSH = shutil.which("zsh")

with tempfile.TemporaryDirectory(prefix="artifact-save-") as directory:
    work = Path(directory)
    binaries, artifacts = work / "bin", work / "artifacts with spaces"
    binaries.mkdir()
    stubs = {
        "date": '#!/bin/sh\nprintf "%s\\n" "2026-10-28-120000"\n',
        "cat": '#!/bin/sh\n/bin/cat\nexit "${ARTIFACT_TEST_READ_STATUS:-0}"\n',
        "pbpaste": '#!/bin/sh\nprintf "%s\\n" clipboard\nexit "${ARTIFACT_TEST_CLIP_STATUS:-0}"\n',
    }
    for name, text in stubs.items():
        path = binaries / name
        path.write_text(text)
        path.chmod(0o700)
    env = {**os.environ, "PATH": str(binaries) + os.pathsep + os.defpath,
           "ZDOTDIR": str(work), "ARTIFACTS_DIR": str(artifacts)}

    def save(text, *args, **overrides):
        return subprocess.run([ZSH, str(SCRIPT), *args], input=text, text=True,
                              capture_output=True, env={**env, **overrides})

    saved = []
    for content in ("first draft\n", "second draft\n"):
        result = save(content, "same name")
        assert result.returncode == 0, result.stderr
        path = Path(result.stdout.strip())
        assert path.suffix == ".md" and path.read_text() == content
        assert path.stat().st_mode & 0o777 == 0o600
        saved.append(path)
    assert saved[0] != saved[1] and saved[0].read_text() == "first draft\n"
    before = {path.name: path.read_bytes() for path in artifacts.iterdir()}
    for text, args, overrides, status in (
        ("partial input", ["same name"], {"ARTIFACT_TEST_READ_STATUS": "7"}, 7),
        ("", ["-c", "same name"], {"ARTIFACT_TEST_CLIP_STATUS": "9"}, 9),
        ("", ["same name"], {}, 1),
    ):
        result = save(text, *args, **overrides)
        assert result.returncode == status and not result.stdout, result
        assert {path.name: path.read_bytes() for path in artifacts.iterdir()} == before
    result = save("ignored stdin", "-c", "clipboard")
    assert result.returncode == 0 and Path(result.stdout.strip()).read_text() == "clipboard\n"
    assert not list(artifacts.glob(".artifact-*"))

print("Artifact saves: PASS (same-second uniqueness, content, permissions, failed input/clipboard, cleanup)")
