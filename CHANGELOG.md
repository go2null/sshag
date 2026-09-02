# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog], and this project adheres to
[Semantic Versioning].

## [4.0.0] - 2026-09-02

_This release moves installations to the UAPI lib directory. Existing
installations are migrated automatically on update._

### Changed

* **Breaking:** Install into the lib directory specified by the [UAPI
  file system hierarchy] rather than the XDG data directory, which has
  no place for architecture-dependent files
  ([`0eb9228`](https://github.com/go2null/sshag/commit/0eb9228))
* **Breaking:** Resolve the full install path, including the `sshag`
  directory, in one place, so it no longer differs between install,
  update, and removal
  ([`d9026b7`](https://github.com/go2null/sshag/commit/d9026b7))
* State both outcomes of every command whose status matters, so a
  handled failure no longer propagates to the caller
  ([`6396461`](https://github.com/go2null/sshag/commit/6396461),
  [`8f2cb0b`](https://github.com/go2null/sshag/commit/8f2cb0b))
* Always end socket lookup with a usable agent, starting one when none
  can be reused
  ([`1689afa`](https://github.com/go2null/sshag/commit/1689afa))
* Detect sourcing from the script name alone, dropping the
  zsh-specific evaluation-context check
  ([`576848d`](https://github.com/go2null/sshag/commit/576848d),
  [`aea8879`](https://github.com/go2null/sshag/commit/aea8879))
* Dispatch on the first argument only, instead of classifying every
  argument in a loop
  ([`d52e8e5`](https://github.com/go2null/sshag/commit/d52e8e5))

### Fixed

* Start the agent before connecting to a host, so passing a `user@host`
  directly no longer prompts for the key passphrase
  ([`98ed0d2`](https://github.com/go2null/sshag/commit/98ed0d2))
* Stop treating the arguments a login shell passes when sourcing the
  file as a hostname
  ([`503de89`](https://github.com/go2null/sshag/commit/503de89))
* Report success when the script is sourced a second time, so adding it
  to several dot profiles does not look like a failure
  ([`7711e17`](https://github.com/go2null/sshag/commit/7711e17))
* Leave `SSH_AUTH_SOCK` untouched while vetting a candidate socket, and
  name the socket under test in the resulting warnings
  ([`a0fd541`](https://github.com/go2null/sshag/commit/a0fd541))
* Restore the tracing setup and argument dispatch dropped by an earlier
  simplification
  ([`1eb6a11`](https://github.com/go2null/sshag/commit/1eb6a11))

## [3.0.3] - 2025-04-17

_No user-facing changes._

## [3.0.2] - 2025-04-04

### Changed

* Remove extra whitespace from the list of loaded keys
* Update the pearl package configuration to the current standard

## [3.0.1] - 2025-04-03

### Fixed

* Remove example code left in the script

## [3.0.0] - 2025-04-02

### Changed

* **Breaking:** Install into `XDG_DATA_DIR/lib`, migrating existing
  installations to the new location

### Added

* Run `ssh-add` automatically when the shell starts

### Fixed

* Detect correctly when the script is sourced under zsh

## [2.0.0] - 2022-04-02

### Changed

* **Breaking:** Install system-wide only when running as `root`
* **Breaking:** Install to `~/.local/lib`, per the systemd standard

### Added

* Add the ability to uninstall

### Fixed

* Correct the path to `LICENSE` (#2)

## [1.3.1] - 2018-02-19

### Changed

* Move the history section out of the readme and into this changelog

### Added

* Add support for the [pearl] shell package manager

## [1.3.0] - 2018-01-17

### Added

* Allow passing arguments and options through to SSH
* Add `install` and `update` subcommands

## [1.2.1] - 2017-10-07

### Added

* Check whether SSH supports the `AddKeysToAgent` option

### Fixed

* Correct the detection of identity files
* Suppress the `grep` error raised when the config file is absent

## [1.2.0] - 2016-08-25

### Changed

* Make the script POSIX compliant

### Added

* Search `$TMPDIR` for agents as well, per the OpenSSH man page
* Accept an agent socket passed as an argument
* Accept `sshag user@domain` as a replacement for `ssh user@domain`

## [1.1.0] - 2011-02-20

### Added

* Make it convenient to run the script in a subshell (_intuited_)

## [1.0.0] - 2010-07-26

### Changed

* **Breaking:** Rename from `sagent` to `sshag` (_intuited_)

### Added

* Add readme and license documents (_intuited_)

## [0.0.0] - 2010-05-14

_Initial release, from the [original answer] on superuser.com (_Zed_)._

[Common Changelog]: https://common-changelog.org
[Semantic Versioning]: https://semver.org
[UAPI file system hierarchy]: https://uapi-group.org/specifications/specs/linux_file_system_hierarchy/#locallib
[original answer]: https://superuser.com/a/141241
[pearl]: https://github.com/pearl-core/pearl#installation

[4.0.0]: https://github.com/go2null/sshag/compare/v3.0.3...v4.0.0
[3.0.3]: https://github.com/go2null/sshag/compare/v3.0.2...v3.0.3
[3.0.2]: https://github.com/go2null/sshag/compare/v3.0.1...v3.0.2
[3.0.1]: https://github.com/go2null/sshag/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/go2null/sshag/compare/2.0.0...v3.0.0
[2.0.0]: https://github.com/go2null/sshag/compare/1.3.1...2.0.0
[1.3.1]: https://github.com/go2null/sshag/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/go2null/sshag/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/go2null/sshag/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/go2null/sshag/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/go2null/sshag/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/go2null/sshag/compare/0.0.0...1.0.0
[0.0.0]: https://github.com/go2null/sshag/releases/tag/0.0.0
