# AGENTS.md

`sshag` is a single POSIX shell file that finds, reuses, or starts an
`ssh-agent`, and can wrap `ssh` so the right key is loaded first. It is
both a sourceable include and an executable script, plus a self-contained
installer/updater/uninstaller.

Read `MEMORY.md` before non-trivial changes; it records why the fragile
parts are the way they are, and the open issues.

## Layout

* `sshag.sh` — the entire program (~430 lines). Everything lives here
* `pearl-config/` — hooks for the [pearl] package manager;
  `config.sh` sources `sshag.sh`, `hooks.sh` runs it post-install/update
* `README.md`, `CHANGELOG.md`, `LICENSE` (CC BY-SA 2.5, attributed to a
  superuser.com answer)

There is no build system, no test suite, no CI, and no dependencies
beyond `ssh`, `ssh-add`, `ssh-agent`, `git`, and coreutils.

## Commands

```sh
sh sshag.sh install [DIR]     # git clone + wire into shell profiles
sshag update                  # git pull in the install dir
sshag remove                  # rm -rf + strip lines from profiles
shellcheck sshag.sh           # the only lint; keep it clean
sh -x sshag.sh                # trace; PS4 is preset to show file:line
```

Verify changes under several shells, since sourced-vs-executed detection
differs per shell:

```sh
sh sshag.sh ; bash -c '. ./sshag.sh' ; zsh -c '. ./sshag.sh'
```

## Architecture

`sshag.sh` ends with a bare `sshag "$@"` hook, so merely sourcing or
running the file executes the dispatcher. `sshag()` picks a mode:

* __sourced, or `$1` is an existing path__ — get/vet a socket, then
  print or add keys
* __`install`/`update`/`uninstall`/`remove`__ — installer path
* __any other argument__ — treated as `user@host`, goes to `sshag_ssh`
* __no arguments, executed__ — prints usage notice only

Socket resolution order in `sshag_agent_get_socket`: the passed socket,
then `$SSH_AUTH_SOCK`, then any socket found under `/tmp` and `$TMPDIR`
matching `*/ssh-*/agent.*` owned by the current uid, then a fresh
`ssh-agent`. Vetting runs `ssh-add -l` in a subshell; exit code `2`
means a dead socket, which is deleted from disk.

`sshag_ssh` covers OpenSSH older than 7.2, which lacks `AddKeysToAgent`.
`sshag_install_*` resolves a UAPI lib directory and migrates installs
from historical paths. See `MEMORY.md` for the rationale of both.

## Conventions

* __POSIX `sh` only.__ No bashisms
* __Tabs for indentation__, LF endings, 80-column limit (`.editorconfig`)
* __Function naming is hierarchical__ — `sshag_<area>_<action>`
  (`sshag_agent_*`, `sshag_ssh_*`, `sshag_install_*`). Helpers that are
  not sshag-specific drop the prefix (`check_commands`, `print_*`)
* __All output goes to stderr__ via the `print_*` helpers; stdout is
  reserved. Never add a bare `printf` to stdout
* __Explicit return codes; never `set -e`.__ Every command whose status
  matters states both outcomes, in one of exactly three forms:

  ```sh
  cmd && true_handler || false_handler   # both outcomes handled
  cmd && true_handler || :               # only success is interesting
  cmd || false_handler                   # only failure is interesting
  ```

  The trailing `|| :` is mandatory, not decorative: it absorbs the
  failing status that would otherwise become the function's return
  value and abort a caller running under `set -e`. Never write
  `|| false_handler && :` — the `&& :` is a no-op, since the `||` form
  already ends on the handler's status. `set -e` is banned in this file
  because it leaks into the sourcing shell; see `MEMORY.md`
* __`shellcheck` directives are inline and commented__ with why they are
  disabled; follow that pattern rather than silencing globally
* Avoid introducing new unprefixed shell variables — the file is sourced
  into interactive shells, so they leak into the user's environment

[pearl]: https://github.com/pearl-core/pearl
