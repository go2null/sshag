# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog]
and this project adheres to [Semantic Versioning].


## [1.3.1] - 2018-02-19
### Added
- *go2null*: Added support for [pearl] shell package manager.

### Changed
- *go2null*: Replaced regular `git` tags with annotated tags with changelog.
- *go2null*: Moved **History** section from `README.markdown` to `CHANGELOG.md`.
- *go2null*: Renamed `README.markdown` to `README.md`.


## [1.3.0] - 2018-01-17
### Added
- *go2null*: Allow passing arguments/options to `ssh`.
- *go2null*: New `install` and `update` functions.


## [1.2.1] - 2017-10-07
## Added
- *go2null*: Check if `ssh` supports `AddKeysToAgent` flag.

## Changed
- *go2null*: Fixed detection of identity files.
- *go2null*: Fixed grep error when config file not found.


## [1.2.0] - 2016-08-25
### Added
- *go2null*: Search `$TMPDIR` for agents as well, per OpenSSH man page.
- *go2null*: Accept socket passed in.
- *go2null*: Can now use `sshag user@domain` instead of `ssh user@domain`.

### Changed
- *go2null*: Make script POSIX compliant.


## [1.1.0] - 2011-02-20
### Added
- *intuited*: Made it convenient to run the script in a subshell.


## [1.0.0] - 2010-07-26
### Added
- *intuited*: Add readme and license documents.

### Changed
- *intuited*: Renamed from `sagent` to `sshag`.


## [0.0.0] - 2010-05-14
### Added
- *Zed*: http://superuser.com/a/141241


[Keep a Changelog]: http://keepachangelog.com
[Semantic Versioning]: http://semver.org
[pearl]: https://github.com/pearl-core/pearl#installation
