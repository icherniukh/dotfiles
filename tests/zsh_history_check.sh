#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

HOME="$tmpdir" XDG_STATE_HOME="$tmpdir/state" XDG_CACHE_HOME="$tmpdir/cache" \
  zsh -fic '
    set -e
    # Simulate the macOS defaults that run after .zshenv.
    HISTSIZE=2000; SAVEHIST=1000
    source "$1/dot_config/zsh/env.zsh"
    source "$1/dot_config/zsh/options.zsh"
    [[ $HISTSIZE -gt 1000000 && $SAVEHIST -gt 1000000 ]]
    [[ -o appendhistory && -o sharehistory && -o histsavebycopy && -o histfcntllock ]]
    [[ ! -o incappendhistory && ! -o incappendhistorytime && ! -o histexpiredupsfirst ]]
    for n in {1..1600}; do print -s -- "history-test-$n"; done
    # print -s leaves its last event pending until another event starts.
    print -s -- history-test-pending
    fc -W "$HISTFILE"
    fc -p "$HISTFILE" "$HISTSIZE" "$SAVEHIST"
    print -r -- "Reloaded test history events: ${#history}"
    [[ ${#history} -eq 1600 ]]
    # Daily snapshots are private hard copies and are not overwritten.
    source "$1/dot_config/zsh/env.zsh"
    snapshot="$XDG_STATE_HOME/zsh/snapshots/history-$(date +%F)"
    [[ -f "$snapshot" && ! -L "$snapshot" ]]
    cmp "$snapshot" "$HISTFILE"
    print -s -- "history-test-later"
    fc -W "$HISTFILE"
    source "$1/dot_config/zsh/env.zsh"
    fc -p "$snapshot" "$HISTSIZE" "$SAVEHIST"
    print -r -- "Snapshot test history events: ${#history}"
    [[ ${#history} -eq 1600 ]]
    # Do not let the test shell write back to the protected snapshot on exit.
    HISTFILE=
    print "History retention and immutable daily snapshot: PASS"
  ' -- "$repo_root"

# Child processes must not inherit HISTFILE: an interactive bash would trim it to 500 lines.
for config in dot_zshenv dot_config/zsh/env.zsh; do
  HOME="$tmpdir" XDG_STATE_HOME="$tmpdir/state" XDG_CACHE_HOME="$tmpdir/cache" \
    HISTFILE=/inherited/history zsh -fc '
      source "$1/$2"
      [[ $HISTFILE == "$XDG_STATE_HOME/zsh/history" ]]
      [[ -z "$(/bin/sh -c "printf %s \"\${HISTFILE-}\"")" ]]
    ' -- "$repo_root" "$config"
done
echo "HISTFILE stays private to zsh: PASS"

# A long-lived writer must not trim a larger history recovered while it is open.
python3 - "$repo_root" <<'PY'
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

repo = Path(sys.argv[1])

def seed(path, count):
    path.write_text(''.join(f': {1700000000+i}:0;retention-fixture-{i}\n' for i in range(count)))

for fixed in (False, True):
    with tempfile.TemporaryDirectory(prefix='zsh-writer-check-') as directory:
        root = Path(directory)
        state = root / 'state/zsh'
        state.mkdir(parents=True)
        history = state / 'history'
        seed(history, 3000)
        (root / '.zshenv').write_text((repo / 'dot_zshenv').read_text())
        (root / '.zsh_history').symlink_to(history)
        rc = f'HISTFILE={history}\nHISTSIZE=2000; SAVEHIST=1000\nPS1="PROBE> "\n'
        if fixed:
            rc += f'source {repo}/dot_config/zsh/env.zsh\nsource {repo}/dot_config/zsh/options.zsh\n'
        (root / '.zshrc').write_text(rc)
        env = dict(os.environ, HOME=str(root), ZDOTDIR=str(root),
                   XDG_CONFIG_HOME=str(root / 'config'), XDG_DATA_HOME=str(root / 'data'),
                   XDG_STATE_HOME=str(root / 'state'), XDG_CACHE_HOME=str(root / 'cache'),
                   TERM_PROGRAM='history-check')
        process = subprocess.Popen(['zsh', '-i'], env=env, stdin=subprocess.PIPE,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)
        try:
            ready = root / 'ready'
            process.stdin.write(f'print ready > {ready}\n')
            process.stdin.flush()
            deadline = time.monotonic() + 10
            while not ready.exists() and time.monotonic() < deadline:
                time.sleep(0.02)
            assert ready.exists(), 'test shell failed to initialize'
            recovered = history.with_name('recovered')
            seed(recovered, 5000)
            os.replace(recovered, history)
            process.communicate('exit\n', timeout=10)
            count = history.read_bytes().count(b'\n')
            assert count > 5000 if fixed else count == 1000, (fixed, count)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
print('Stale writer reproduction and corrected retention: PASS')
PY
