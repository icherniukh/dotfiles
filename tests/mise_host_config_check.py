#!/usr/bin/env python3
"""Shared pins stay on the VPS baseline; chezmoi preserves working host overrides."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]
assert "tools" not in tomllib.loads((ROOT / "dot_config/mise/config.toml").read_text())
tools = tomllib.loads((ROOT / "dot_config/mise/conf.d/00-shared.toml").read_text())["tools"]
baseline = {"node": "24", "python": "3.13", "ruby": "3.4", "bun": "1.3.14", "hk": "1.51.0"}
assert {name: tools[name] for name in baseline} == baseline
assert "pi" not in tools and "oh-my-pi" not in tools

with tempfile.TemporaryDirectory(prefix="mise-host-") as directory:
    work = Path(directory)
    source, destination = work / "source", work / "destination"
    shared_source = source / "dot_config/mise/conf.d/00-shared.toml"
    shared_source.parent.mkdir(parents=True)
    shared_source.write_text(f'[tools]\nnode = "{tools["node"]}"\n')
    (shared_source.parent.parent / "config.toml").write_text('[settings]\ncolor=true\n')
    shutil.copyfile(ROOT / ".chezmoiignore", source / ".chezmoiignore")
    # Even an accidentally added source override must not replace runtime data.
    (shared_source.parent / "host.toml").write_text('[tools]\nnode = "wrong"\n')
    host = destination / ".config/mise/conf.d/host.toml"
    host.parent.mkdir(parents=True)
    host.write_text('[tools]\nnode = "26"\n')
    original = host.read_bytes()
    config = work / "chezmoi.toml"
    config.touch()
    subprocess.run(["chezmoi", "--config", str(config), "--source", str(source),
                    "--destination", str(destination), "--cache", str(work / "chezmoi-cache"),
                    "--persistent-state", str(work / "state.boltdb"), "apply", "--exclude=scripts"],
                   capture_output=True, text=True, check=True)
    assert host.read_bytes() == original
    for version in ("24.0.0", "26.0.0"):
        binary = work / f"data/installs/node/{version}/bin/node"
        binary.parent.mkdir(parents=True)
        binary.write_text("#!/bin/sh\nexit 0\n")
        binary.chmod(0o700)
    env = {**os.environ, "XDG_CONFIG_HOME": str(destination / ".config"),
           "MISE_CONFIG_DIR": str(host.parent.parent),
           "MISE_DATA_DIR": str(work / "data"), "MISE_CACHE_DIR": str(work / "mise-cache"),
           "MISE_OFFLINE": "1", "MISE_AUTO_INSTALL": "0", "MISE_NOT_FOUND_AUTO_INSTALL": "0"}
    env.pop("MISE_GLOBAL_CONFIG_FILE", None)
    for version in ("26.0.0", "24.0.0"):
        result = subprocess.run([shutil.which("mise"), "which", "node"], cwd=work,
                                env=env, capture_output=True, text=True, check=True, timeout=10)
        assert result.stdout.strip() == str(work / f"data/installs/node/{version}/bin/node"), result
        if host.exists():
            host.unlink()

print("Mise host config: PASS (shared baseline, ignored host data, native override/fallback selection; no installs)")
