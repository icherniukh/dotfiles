#!/usr/bin/env bash
#
# Checks the terminal AI rewrite widgets in dot_config/zsh/slop.zsh.
#
# The widget behavior is exercised in a pty, because a ZLE widget only runs
# on a real terminal. The model is stubbed out: the point is the shell
# mechanics (bindings registered, instruction read, buffer replaced), not the
# model output.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
widget="${repo_root}/dot_config/zsh/slop.zsh"
slop_script="${repo_root}/dot_scripts/executable_slop"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK:   $*"; }

[[ -f "$widget" ]] || fail "missing $widget"
[[ -f "$slop_script" ]] || fail "missing $slop_script"

# The script must be executable in the source tree so chezmoi keeps the mode.
[[ -x "$slop_script" ]] || fail "$slop_script is not executable"

# --- Static checks -------------------------------------------------------

# Ctrl-X Ctrl-S is XOFF: the terminal swallows the following keystroke.
if grep -q "'\^X\^S'" "$widget"; then
  fail "widget binds Ctrl-X Ctrl-S (XOFF); use Ctrl-X Ctrl-E"
fi

grep -q "bindkey '\^X\^E' _slop_rewrite_widget" "$widget" \
  || fail "missing Ctrl-X Ctrl-E binding"
grep -q "bindkey '\^X\^I' _slop_instruct_widget" "$widget" \
  || fail "missing Ctrl-X Ctrl-I binding"
grep -q "_slop_enter_widget" "$widget" \
  || fail "missing accept-line override for the ai: prefix"

# The instruction must be read in the current shell, not in a subshell.
if grep -qE '_slop_read_line.*\$\(|=\$\(_slop_read_line' "$widget"; then
  fail "instruction read inside a command substitution; newline will not end the read"
fi

# The widget file must be sourced by managed shell config.
if ! grep -q "zsh/slop.zsh" "${repo_root}/dot_config/zsh/functions.zsh"; then
  fail "slop.zsh is not sourced from dot_config/zsh/functions.zsh"
fi

# `plz` must default to a model the Codex CLI accepts.
if ! grep -q "gpt-6-luna" "${repo_root}/dot_scripts/executable_plz"; then
  fail "plz does not default to gpt-6-luna"
fi

ok "static checks passed"

# --- Live widget check ---------------------------------------------------

# A stub `plz` that echoes a marker, so the test does not call a model.
stub_bin="${tmpdir}/bin"
mkdir -p "$stub_bin"
cat > "${stub_bin}/plz" <<'STUB'
#!/usr/bin/env bash
cat >/dev/null
echo "REWRITTEN_BY_STUB"
STUB
chmod +x "${stub_bin}/plz"

cat > "${tmpdir}/harness.py" <<'PY'
import os, pty, select, sys, time

steps = eval(sys.argv[1])
pid, fd = pty.fork()
if pid == 0:
    os.environ["TERM"] = "xterm-256color"
    os.environ["PATH"] = os.environ["STUB_PATH"] + ":" + os.environ["PATH"]
    os.execvp("zsh", ["zsh", "-f", "-i"])

out = []


def pump(duration):
    end = time.time() + duration
    while time.time() < end:
        ready, _, _ = select.select([fd], [], [], 0.1)
        if not ready:
            continue
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            return
        if not chunk:
            return
        out.append(chunk)


for keys, wait in steps:
    os.write(fd, keys.encode())
    pump(wait)
pump(1.0)
sys.stdout.write(b"".join(out).decode(errors="replace"))
PY

run_case() {
  local name="$1" steps="$2"
  local output
  output="$(STUB_PATH="$stub_bin" python3 "${tmpdir}/harness.py" "$steps")"
  if [[ "$output" != *REWRITTEN_BY_STUB* ]]; then
    echo "$output" | tail -5 >&2
    fail "$name: widget did not put the rewrite in the buffer"
  fi
  ok "$name"
}

# Ctrl-X Ctrl-E rewrites the buffered command line.
run_case "Ctrl-X Ctrl-E rewrites the buffer" \
  "[('source ${widget}\n', 1.0), ('echo hi\n', 0.6), ('echo text', 0.6), ('\x18', 0.3), ('\x05', 0.8)]"

# Ctrl-X Ctrl-I asks for the instruction, then rewrites.
run_case "Ctrl-X Ctrl-I prompts then rewrites" \
  "[('source ${widget}\n', 1.0), ('echo text', 0.6), ('\x18', 0.3), ('\x09', 0.6), ('make it plain\n', 0.3), ('DONE', 1.5)]"

# The ai: prefix prompts on Enter, then rewrites.
run_case "ai: prefix prompts then rewrites" \
  "[('source ${widget}\n', 1.0), ('ai: some text\n', 0.8), ('make it plain\n', 0.3), ('DONE', 1.5)]"

# An ordinary command still runs.
output="$(STUB_PATH="$stub_bin" python3 "${tmpdir}/harness.py" \
  "[('source ${widget}\n', 1.0), ('echo ORDINARY_COMMAND_RAN\n', 0.8)]")"
[[ "$output" == *ORDINARY_COMMAND_RAN* ]] || fail "ordinary command execution broke"
ok "ordinary commands still run"

echo "all checks passed"
