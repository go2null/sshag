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

### Explicit return codes, and no `set -e`

Every command whose status matters must state both outcomes explicitly.
One of these three forms, and nothing else:

```sh
cmd && true_handler || false_handler   # both outcomes handled
cmd && true_handler || :               # only success is interesting
cmd || false_handler                   # only failure is interesting
```

The trailing `|| :` is not noise. `cmd && true_handler` on its own ends
on a failing status whenever `cmd` fails, so a "handled" failure still
propagates: it becomes the function's return value, and it aborts a
caller running under `set -e`. The `|| :` absorbs it.

The third form needs no such guard, and must not be given one. `cmd ||
false_handler` already ends on the handler's status, so appending
`&& :` is a no-op that adds nothing under `set -e` either.

Introduced in `fa4dc98` and `e643931`.

The `return_0` branch was opened to add `set -e` instead. That was
removed and will not come back:

* When the file is sourced, `set -e` stays in effect in the user's
  interactive shell, where the next failing command kills their session
* A trailing `set +e` does not fix it. It clobbers rather than restores,
  silently disabling `errexit` for a caller that had it on. A correct
  restore must save `$-` first
* Even a correct restore is unreachable on the paths that matter. The
  file ends in a bare `sshag "$@"` hook, `sshag` returns from many
  branches, and `print_fatal` calls `exit`. Any of those skips the
  restore and leaks `errexit`
* `set -e` is suppressed inside `&&`/`||` chains and `if` conditions,
  which is where nearly every command in this script lives, so it would
  rarely fire anyway
* Its behaviour for failures inside functions differs between dash,
  bash, and zsh, all three of which must be supported

If `errexit` is ever wanted, scope it to the executed path only
(`sshag_is_sourced || set -e`), where there is no caller to corrupt.

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

### Changelog follows Common Changelog

Converted from Keep a Changelog. Only `Changed`, `Added`, `Removed`,
`Fixed` are used, in that order, and there is no `Unreleased` section:
entries are added under the release they ship in. Entries are
imperative, self-describing without their heading, and carry commit
links in parentheses at the end. Do not paste `git log` output, and do
not record dotfile or formatting churn.

Note that release tags are inconsistent in this repo: `0.0.0` through
`2.0.0` are unprefixed, `v3.0.0` onward carry a `v`. The comparison
links reflect that; check the actual tag before adding a new one.

## Known issues

* `README.md` says the output "will always consist of just the socket
  location", but `sshag_agent_print_notice` prints only an instructional
  message. Decide which behaviour is correct before changing either
* Uninstall rewrites user dotfiles with `sed -i.bak` and leaves `.bak`
  files behind; unwritable files are skipped with a warning only
* Several functions assign unprefixed globals (`dir`, `keys`,
  `ssh_opts`, `user_host`, `agent_socket`, `file`) that leak into the
  user's interactive shell, since the file is sourced there
