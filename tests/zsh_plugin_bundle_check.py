#!/usr/bin/env python3
"""A failed Antidote generator must preserve the working bundle and allow retry."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory(prefix="antidote-bundle-") as directory:
    work = Path(directory)
    cache, zdot = work / "cache", work / "zsh"
    cache.mkdir()
    (zdot / ".antidote").mkdir(parents=True)
    (zdot / ".antidote/antidote.zsh").write_text('''antidote() {
  print attempt >> "$BUNDLE_TEST_LOG"
  if [[ $BUNDLE_TEST_FAIL == 1 ]]; then
    print PARTIAL_BUNDLE
    return 7
  fi
  print '# VALID_BUNDLE'
}
''')
    source = zdot / ".zsh_plugins.txt"
    source.write_text("fixture/plugin\n")
    bundle = cache / "plugins.zsh"
    bundle.write_text("# LAST_WORKING_BUNDLE\n")
    os.utime(bundle, (time.time() - 10, time.time() - 10))
    original, modified = bundle.read_bytes(), bundle.stat().st_mtime_ns
    log = work / "calls"
    env = {**os.environ, "ZDOTDIR": str(zdot), "ZSH_CACHE_DIR": str(cache),
           "XDG_CACHE_HOME": str(cache), "ZSH_CONFIG_DIR": str(work / "config"),
           "BREW_PREFIX": str(work / "missing-brew"), "PATH": os.defpath,
           "TERM_PROGRAM": "", "GHOSTTY_RESOURCES_DIR": "", "BUNDLE_TEST_LOG": str(log)}

    def load(fail):
        result = subprocess.run([shutil.which("zsh"), "-fc", 'source "$1"; true', "--",
                                 str(ROOT / "dot_config/zsh/plugins.zsh")],
                                env={**env, "BUNDLE_TEST_FAIL": str(fail)},
                                capture_output=True, text=True)
        assert result.returncode == 0, result.stderr
        assert not list(cache.glob("plugins.zsh.*"))

    load(1)
    assert bundle.read_bytes() == original and bundle.stat().st_mtime_ns == modified
    load(0)
    assert bundle.read_text() == "# VALID_BUNDLE\n"
    load(1)
    assert bundle.read_text() == "# VALID_BUNDLE\n" and len(log.read_text().splitlines()) == 2
    bundle.unlink()
    load(1)
    assert not bundle.exists()
    load(0)
    assert bundle.read_text() == "# VALID_BUNDLE\n" and len(log.read_text().splitlines()) == 4

print("Antidote bundle: PASS (failure preserves bytes/mtime, retries, successful replacement, cleanup)")
