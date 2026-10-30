#!/usr/bin/env python3
"""Check the real postinstall snippet with an echo-only mise stub: no installs."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib


ROOT = Path(__file__).resolve().parents[1]
with (ROOT / "dot_config/mise/config.toml").open("rb") as config:
    hook = tomllib.load(config)["hooks"]["postinstall"]

with tempfile.TemporaryDirectory(prefix="mise-postinstall-") as directory:
    work = Path(directory)
    stub = work / "mise"
    stub.write_text('''#!/bin/sh
printf '%s\\n' "$*" >> "$MISE_TEST_LOG"
exit "$MISE_TEST_STATUS"
''')
    stub.chmod(0o755)
    log = work / "calls"
    shells = dict.fromkeys(filter(None, (shutil.which(name) for name in ("sh", "bash", "dash"))))
    for shell in shells:
        for tools, status, expected in (
            ([], 0, []),
            ([{"name": "node"}], 0, []),
            ([{"name": "gem:colorls"}], 0, []),
            ([{"name": "ruby"}], 0, ["install --force gem:colorls"]),
            ([{"name": "ruby"}, {"name": "node"}], 0, ["install --force gem:colorls"]),
            ([{"name": "ruby"}], 7, ["install --force gem:colorls"]),
        ):
            log.write_text("")
            env = {**os.environ, "PATH": str(work) + os.pathsep + os.environ["PATH"],
                   "MISE_INSTALLED_TOOLS": json.dumps(tools),
                   "MISE_TEST_LOG": str(log), "MISE_TEST_STATUS": str(status)}
            result = subprocess.run([shell, "-c", hook], env=env, text=True, capture_output=True)
            assert result.returncode == status, (shell, tools, result.stderr)
            assert log.read_text().splitlines() == expected, (shell, tools)
        # A missing parser must fail clearly instead of silently skipping Ruby.
        log.write_text("")
        env = {**os.environ, "PATH": str(work),
               "MISE_INSTALLED_TOOLS": json.dumps([{"name": "ruby"}]),
               "MISE_TEST_LOG": str(log), "MISE_TEST_STATUS": "0"}
        result = subprocess.run([shell, "-c", hook], env=env, text=True, capture_output=True)
        assert result.returncode == 127 and "jq is required" in result.stderr
        assert not log.read_text()
        env["PATH"] += os.pathsep + os.environ["PATH"]
        env["MISE_INSTALLED_TOOLS"] = "{broken"
        result = subprocess.run([shell, "-c", hook], env=env, text=True, capture_output=True)
        assert result.returncode != 0 and not log.read_text(), result.stderr
print("Mise postinstall: PASS (non-Ruby no-op, colorls rebuild, failure propagation, missing jq, malformed event; "
      + "/".join(Path(shell).name for shell in shells) + ")")
