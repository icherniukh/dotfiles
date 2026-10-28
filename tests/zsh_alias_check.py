#!/usr/bin/env python3
"""Exercise dynamic aliases with isolated HOME and real create-only chezmoi apply."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory(prefix="zsh-alias-check-") as tmp:
    home = Path(tmp) / "home"
    config = home / "custom-config"
    source = Path(tmp) / "source"
    zsh_config = config / "zsh"
    zsh_config.mkdir(parents=True)
    (source / "dot_config/zsh").mkdir(parents=True)
    for name in ("aliases.zsh", "functions.zsh"):
        shutil.copyfile(ROOT / "dot_config/zsh" / name, zsh_config / name)
    seed = "create_private_user-aliases.zsh"
    shutil.copyfile(ROOT / "dot_config/zsh" / seed, source / "dot_config/zsh" / seed)
    env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(config), ZDOTDIR=str(home))
    env.pop("ZSH_CONFIG_DIR", None)
    startup = 'ZSH_CONFIG_DIR="$XDG_CONFIG_HOME/zsh"\nsource "$ZSH_CONFIG_DIR/aliases.zsh"\nsource "$XDG_CONFIG_HOME/zsh/functions.zsh"\n'
    (home / ".zshrc").write_text(startup)

    def shell(code, stdin="", success=True):
        result = subprocess.run(["zsh", "-fic", code], input=stdin, text=True,
                                capture_output=True, env=env)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result.stdout

    def apply():
        # Target the XDG-independent fixture .config path for create_ semantics.
        subprocess.run(["chezmoi", "--config", str(Path(tmp) / "empty.toml"),
                        "--source", str(source), "--destination", str(home),
                        "--persistent-state", str(Path(tmp) / "state.boltdb"),
                        "apply", "--exclude=scripts"], check=True, env=env,
                       capture_output=True, text=True)

    assert "Custom Aliases" in shell('source "$ZDOTDIR/.zshrc"; lsa')
    apply()
    assert (home / ".config/zsh/user-aliases.zsh").exists()
    # Use the seed in the custom XDG directory for the behavioral checks.
    shutil.copyfile(home / ".config/zsh/user-aliases.zsh", zsh_config / "user-aliases.zsh")
    command = "printf '%s\\n' \"it's $HOME\";\nprintf '%s\\n' '\\ literal'"
    env["ALIAS_COMMAND"] = command
    shell('source "$ZDOTDIR/.zshrc"; addalias demo-alias "$ALIAS_COMMAND"; [[ $aliases[demo-alias] == $ALIAS_COMMAND ]]', "A quoted command\n")
    alias_file = zsh_config / "user-aliases.zsh"
    content = alias_file.read_bytes()
    assert len(content.splitlines()) == 5, content
    shell('source "$ZDOTDIR/.zshrc"; [[ $aliases[demo-alias] == $ALIAS_COMMAND ]]')
    listing = shell('source "$ZDOTDIR/.zshrc"; lsa')
    assert "demo-alias" in listing and "A quoted command" in listing, listing
    assert "hz " not in listing, listing
    # Adding one alias must not source an unrelated user-edited command again.
    with alias_file.open("a") as f:
        f.write('\nprint -r -- SHOULD_NOT_RUN\n')
    assert "SHOULD_NOT_RUN" not in shell('source "$XDG_CONFIG_HOME/zsh/functions.zsh"; addalias second "echo second"', "Second description\n")
    alias_file.write_bytes(content)
    for name in ("demo-alias", "addalias", "lsa", "hz", "GLOBAL_TEST", "suffix_test", "bad;name", "-option", "a=b", "two words", ""):
        env["BAD_NAME"] = name
        shell('source "$ZDOTDIR/.zshrc"; alias -g GLOBAL_TEST=cat; alias -s suffix_test=cat; addalias "$BAD_NAME" "echo wrong"', "Duplicate\n", success=False)
        assert alias_file.read_bytes() == content
    # Also reject a persisted duplicate in a shell that has not loaded it yet.
    shell('source "$XDG_CONFIG_HOME/zsh/functions.zsh"; addalias demo-alias "echo wrong"', "Duplicate\n", success=False)
    shell('source "$ZDOTDIR/.zshrc"; addalias canceled "echo wrong"', success=False)
    assert alias_file.read_bytes() == content
    # A later chezmoi apply leaves additions byte-identical.
    fixture_file = home / ".config/zsh/user-aliases.zsh"
    fixture_file.write_bytes(content)
    apply()
    assert fixture_file.read_bytes() == content
    # A failed append must not activate the alias or report success.
    alias_file.unlink()
    alias_file.mkdir()
    shell('source "$XDG_CONFIG_HOME/zsh/functions.zsh"; addalias writefailed "echo wrong"; [[ $? != 0 && ! ${+aliases[writefailed]} == 1 ]]', "Failure\n")

print("PASS: dynamic aliases, quoting, fresh shells, listing, collisions, failures, create-only apply")
