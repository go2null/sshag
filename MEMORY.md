# Memory

Project-specific decisions and issues, with the reasoning behind them.

## Decisions

### Everything lives in one file

`sshag.sh` is deliberately monolithic. It must be sourceable from
`.profile`, `.bashrc`, and `.zshrc` with a single line, and installable
by downloading one file, so splitting it into a library would defeat
both.

### POSIX `sh`, no bashisms

The file is sourced into whatever login shell the user has. `pipefail`
is enabled only behind a subshell probe because older shells abort with
"set: Illegal option -o pipefail".

### Sourced detection lives in a function

`sshag_is_sourced` compares `${0##*/}` to `sshag.sh`. Under zsh, `$0`
inside a function is the function name rather than the script path,
which is what makes the check work there; at main-script scope zsh looks
identical to being executed. Any change must be tested in sh, bash, and
zsh, both sourced and executed.

Two logic bugs have already been fixed here (`a53c3a9`, `42d13fe`).
Treat it as fragile.

### Load-once guard

`sshag_function_is_defined && sshag_is_sourced && return 0 || :` lets the
same source line be added to every dot profile without re-running.
`return` at file scope is only legal when sourced, hence that ordering.

### Explicit return codes and trailing `|| :`

The style is `cmd && return 0 || return 1`, and `... && return 0 || :`
where execution continues. The `|| :` is not noise: without it a failing
last command aborts a caller running under `set -e`. Introduced in
`fa4dc98` and `e643931`.

### stdout is reserved

All messages go to stderr through the `print_*` helpers, because stdout
is meant to carry only the socket path when the script is run in a
subshell (`export SSH_AUTH_SOCK="$(sh sshag.sh)"`). `print_fatal` exits
1; every other `print_*` returns 0 so it never poisons a caller's status.

### Install path follows UAPI

`/usr/local/lib` for root, `$XDG_LIB_HOME` otherwise (`8fa6c8b`,
`fa87e23`). `sshag_install_migrate` is called once per historical path
(v1.3.0, v2.0.0, v3.0.0) so existing users are relocated silently.
Those calls are intentional, not dead code.

### OpenSSH pre-7.2 support is intentional

`sshag_ssh` honours `AddKeysToAgent` from ssh_config if present, else
probes for support by running `ssh -o AddKeysToAgent` and grepping for
"missing argument", else falls back to parsing `ssh -v` output for the
identity file. The probe exists because a shared ssh_config may be used
on machines whose OpenSSH predates the option and would barf on it.

## Known issues

* `README.md` says the output "will always consist of just the socket
  location", but `sshag_agent_print_notice` prints only an instructional
  message. Decide which behaviour is correct before changing either
* Uninstall rewrites user dotfiles with `sed -i.bak` and leaves `.bak`
  files behind; unwritable files are skipped with a warning only
* Several functions assign unprefixed globals (`dir`, `keys`,
  `ssh_opts`, `user_host`, `agent_socket`, `file`) that leak into the
  user's interactive shell, since the file is sourced there
* `CHANGELOG.md` is still in Keep a Changelog form with emoji and commit
  hashes in entries, contrary to the Common Changelog convention.
  Converting it is a separate, deliberate change — ask first
