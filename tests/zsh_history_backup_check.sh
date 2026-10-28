#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
script="$repo_root/dot_scripts/executable_backup-zsh-history-weekly"
source_file="$tmpdir/source history"
destination="$tmpdir/private backups"
printf ': 1700000000:0;echo first\\\nsecond\n' > "$source_file"
first="$(sh "$script" "$source_file" "$destination")"
gzip -dc "$first" | cmp - "$source_file"
second="$(sh "$script" "$source_file" "$destination")"
[[ "$first" != "$second" && -f "$first" && -f "$second" ]]
: > "$source_file"
if sh "$script" "$source_file" "$destination" 2>/dev/null; then
  echo 'Empty history must not produce a backup' >&2
  exit 1
fi
python3 - "$destination" "$first" <<'PY'
from pathlib import Path
import sys
directory, archive = map(Path, sys.argv[1:])
assert directory.stat().st_mode & 0o777 == 0o700
assert archive.stat().st_mode & 0o777 == 0o600
assert not list(directory.glob('.history-*'))
PY
echo 'Weekly history backup: PASS (roundtrip, unique copies, empty input, permissions)'

python3 - "$repo_root" <<'PY'
import configparser
import fnmatch
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
service_path = '.config/systemd/user/zsh-history-backup.service'
timer_path = '.config/systemd/user/zsh-history-backup.timer'
launchagent_path = 'Library/LaunchAgents/dev.dotfiles.zsh-history-backup.plist'

def unit(path):
    config = configparser.ConfigParser(interpolation=None)
    config.read(root / ('dot_config/' + path[len('.config/'):]))
    return config

service = unit(service_path)
assert service['Service']['Type'] == 'oneshot'
assert service['Service']['ExecStart'] == '"%h/.scripts/backup-zsh-history-weekly"'
assert service['Service']['UMask'] == '0077'
timer = unit(timer_path)
assert timer['Timer']['OnCalendar'] == 'Sun *-*-* 12:00:00'
assert timer['Timer'].getboolean('Persistent')
assert timer['Install']['WantedBy'] == 'timers.target'

for os_name in ('linux', 'darwin', 'freebsd'):
    def render(path):
        return subprocess.check_output([
            'chezmoi', 'execute-template', '--source', str(root),
            '--override-data', json.dumps({'chezmoi': {'os': os_name}}),
            '--file', str(root / path),
        ], text=True)

    patterns = render('.chezmoiignore').splitlines()
    def ignored(path):
        return any(fnmatch.fnmatchcase(path, p) for p in patterns if p and not p.startswith('#'))

    assert ignored(service_path) == (os_name != 'linux'), os_name
    assert ignored(timer_path) == (os_name != 'linux'), os_name
    assert ignored(launchagent_path) == (os_name != 'darwin'), os_name
    assert not ignored('.scripts/backup-zsh-history-weekly'), os_name
    hook = render('run_after_enable-zsh-history-backup.sh.tmpl')
    if os_name == 'linux':
        linux_hook = hook
    else:
        assert not hook.strip(), os_name
    if os_name == 'darwin':
        plist = plistlib.loads(render(launchagent_path + '.tmpl').encode())
        assert plist['StartCalendarInterval'] == {'Weekday': 0, 'Hour': 12, 'Minute': 0}
        assert plist['ProgramArguments'][0].endswith('/.scripts/backup-zsh-history-weekly')

# Real isolated chezmoi applies, with systemctl stubbed: no local jobs are started.
missing_cli = subprocess.run(['/bin/sh', '-s'], input=linux_hook, text=True,
                             env={**os.environ, 'PATH': ''}, capture_output=True)
assert missing_cli.returncode == 0 and 'Skipping history backup timer' in missing_cli.stderr
with tempfile.TemporaryDirectory(prefix='chezmoi-history-') as directory:
    tmp = Path(directory)
    source, destination, bin_dir = (tmp / name for name in ('source', 'home', 'bin'))
    bin_dir.mkdir()
    destination.mkdir()
    for relative in (
        'run_after_enable-zsh-history-backup.sh.tmpl',
        'dot_scripts/executable_backup-zsh-history-weekly',
        'dot_config/systemd/user/zsh-history-backup.service',
        'dot_config/systemd/user/zsh-history-backup.timer',
    ):
        target = source / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / relative, target)
    config = tmp / 'chezmoi.toml'
    config.write_text('')
    log = tmp / 'systemctl.log'
    stub = bin_dir / 'systemctl'
    stub.write_text('''#!/bin/sh
set -eu
for file in .scripts/backup-zsh-history-weekly .config/systemd/user/zsh-history-backup.service .config/systemd/user/zsh-history-backup.timer; do
    test -f "$BACKUP_DEST/$file" || exit 90
done
test -x "$BACKUP_DEST/.scripts/backup-zsh-history-weekly" || exit 91
printf '%s\\n' "$*" >> "$SYSTEMCTL_LOG"
case "$*" in
    '--user show-environment') exit "$MANAGER_STATUS" ;;
    '--user daemon-reload') exit "$RELOAD_STATUS" ;;
    '--user enable --now zsh-history-backup.timer') exit "$ENABLE_STATUS" ;;
    *) exit 99 ;;
esac
''')
    stub.chmod(0o755)
    command = [
        shutil.which('chezmoi'), '--config', str(config), '--source', str(source),
        '--destination', str(destination), '--cache', str(tmp / 'cache'),
        '--persistent-state', str(tmp / 'state.boltdb'),
        '--override-data', json.dumps({'chezmoi': {'os': 'linux'}}), 'apply',
    ]
    calls = ['--user show-environment', '--user daemon-reload',
             '--user enable --now zsh-history-backup.timer']
    for manager, reload, enable, success, expected in (
        (1, 0, 0, True, calls[:1]),  # skip without a user manager
        (0, 0, 0, True, calls),     # retry the previously skipped activation
        (0, 0, 0, True, calls),     # repeat apply remains safe
        (0, 7, 0, False, calls[:2]), # reload failures stop activation
        (0, 0, 8, False, calls),    # enable failures are not swallowed
    ):
        log.write_text('')
        env = {**os.environ, 'PATH': str(bin_dir) + os.pathsep + os.environ['PATH'],
               'BACKUP_DEST': str(destination), 'SYSTEMCTL_LOG': str(log),
               'MANAGER_STATUS': str(manager), 'RELOAD_STATUS': str(reload),
               'ENABLE_STATUS': str(enable)}
        result = subprocess.run(command, env=env, text=True, capture_output=True)
        assert (result.returncode == 0) == success, result.stderr
        assert log.read_text().splitlines() == expected, result.stderr
        if manager:
            assert 'Skipping history backup timer' in result.stderr
    log.write_text('')
    scoped = subprocess.run(command + [str(destination / timer_path)],
                            env=env, text=True, capture_output=True)
    assert scoped.returncode == 0, scoped.stderr
    assert not log.read_text(), 'A file-only apply must not run the root after-script'
PY
echo 'Weekly history scheduling: PASS (units, platform selection, apply ordering, activation retries/errors)'
