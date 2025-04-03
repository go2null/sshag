# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog]
and this project adheres to [Semantic Versioning].

## [Unreleased]
### Added
### Changed
* _go2null_: 💄 removed extra whitespace from keys list
### Deprecated
### Removed
### Fixed
### Security

## [3.0.1] - 2025-04-03
### Fixed
* _go2null_: ✏️ removed example code

## [3.0.0] - 2025-04-03
### Added
* _go2null_: ✨ runs ssh-add automatically when shell starts
* _go2null_: ✨ migrate existing installs to the new location
### Changed
* _go2null_: __BREAKING__: 💥 install to XDG_DATA_DIR/lib Directory
### Fixed
* _go2null_: 🐛 fix detecting when sourced in ZSH

## [2.0.0] - 2022-04-01
### Fixed
* _go2null_: Fix bug #2 path to LICENSE.
### Added
* _go2null_: Ability to uninstall.
### Changed
* _go2null_: __BREAKING__: install now defaults to _system_ only if running as `root`.
* _go2null_: __BREAKING__: install now defaults to `~/.local/lib` per `systemd` standard.

## [1.3.1] - 2018-02-19
### Added
* _go2null_: Added support for [pearl] shell package manager.
### Changed
* _go2null_: Replaced regular `git` tags with annotated tags with changelog.
* _go2null_: Moved __History__ section from `README.markdown` to `CHANGELOG.md`.
* _go2null_: Renamed `README.markdown` to `README.md`.

## [1.3.0] - 2018-01-17
### Added
* _go2null_: Allow passing arguments/options to `ssh`.
* _go2null_: New `install` and `update` functions.

## [1.2.1] - 2017-10-07
## Added
* _go2null_: Check if `ssh` supports `AddKeysToAgent` flag.
## Changed
* _go2null_: Fixed detection of identity files.
* _go2null_: Fixed grep error when config file not found.

## [1.2.0] - 2016-08-25
### Added
* _go2null_: Search `$TMPDIR` for agents as well, per OpenSSH man page.
* _go2null_: Accept socket passed in.
* _go2null_: Can now use `sshag user@domain` instead of `ssh user@domain`.
### Changed
* _go2null_: Make script POSIX compliant.

## [1.1.0] - 2011-02-20
### Added
* _intuited_: Made it convenient to run the script in a subshell.

## [1.0.0] - 2010-07-26
### Added
* _intuited_: Add readme and license documents.
### Changed
* _intuited_: __BREAKING__: Renamed from `sagent` to `sshag`.

## [0.0.0] - 2010-05-14
### Added
* _Zed_: http://superuser.com/a/141241


[Keep a Changelog]:    http://keepachangelog.com
[Semantic Versioning]: http://semver.org
[pearl]:               https://github.com/pearl-core/pearl#installation

[Unreleased]: https://github.com/go2null/sshag/compare/3.0.1...HEAD
[3.0.1]:      https://github.com/go2null/sshag/compare/3.0.0...3.0.1
[3.0.0]:      https://github.com/go2null/sshag/compare/2.0.0...3.0.0
[2.0.0]:      https://github.com/go2null/sshag/compare/1.3.0...2.0.0
[1.3.1]:      https://github.com/go2null/sshag/compare/1.3.0...1.3.1
[1.3.0]:      https://github.com/go2null/sshag/compare/1.2.1...1.3.0
[1.2.1]:      https://github.com/go2null/sshag/compare/1.2.0...1.2.1
[1.2.0]:      https://github.com/go2null/sshag/compare/1.1.0...1.2.0
[1.1.0]:      https://github.com/go2null/sshag/compare/1.0.0...1.1.0
[1.0.0]:      https://github.com/go2null/sshag/compare/0.0.0...1.0.0
[0.0.0]:      https://github.com/go2null/sshag/releases/tag/0.0.0
