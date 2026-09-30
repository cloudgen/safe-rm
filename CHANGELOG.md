# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.15] - 2026-09-30

### Changed

- A finished remove names the caller and each path. The line is `Caller <caller> removed <path>.` On a terminal the caller and each path are italic. Two removes are two lines, so a script started from the shell shows which script removed which path. A file that was only sourced, with no path left on the shell command, is reported as that shell (`-bash`), and the path is still named

## [1.0.14] - 2026-09-30

### Added

- `safe-rm reset` (and `--reset`) is for root, or for the Linux `sudo` re-exec. When `origin-rm` already exists, it replaces the system `rm` with a symlink to `origin-rm`. `/bin/rm` then points at `/bin/origin-rm`, and the same for `/usr/bin`. `origin-rm` and `safe-rm` stay. A missing `origin-rm` changes nothing. On Termux this login does that for `$PREFIX/bin` and does not call `sudo`. macOS does not call `sudo`. The home `rm` link is left as it is. A later `setup` points the system `rm` back at `safe-rm`

## [1.0.13] - 2026-09-30

### Added

- The README states the purpose in plain language: what the guard refuses, what a named folder inside a login home may still lose, where setup is the right tool, and where a package-managed host or a trash bin is a better fit. A comparison table covers an absolute `/bin/rm` inside `/bin/sh -c`, extra runtimes, systems, undo, and the effect on the packaged `rm`

### Fixed

- An operand whose final component is `.` or `..` is refused when that directory would otherwise be allowed. `rm -rf .` and `rm -rf ..` no longer pass the check and then depend on the remover. Naming the directory still removes it. `$HOME/.` stays the login-home refusal. A `..` in the middle of a path, as in `leaf/../leaf`, stays the resolved directory
- Account-home matching uses `grep -Fxq` for an exact line. If `grep` is missing or errors, the same list is read in the shell, so a missing `grep` does not allow an account home

## [1.0.12] - 2026-09-30

### Fixed

- The remove check's scratch directory `safe-rm-work.*` is mode `0700`. `mktemp -d` applies the process umask, so a mask that strips the owner execute bit (such as `0177` on Termux) left that directory `drw-------`. The check could not write its path list, and the directory stayed behind under the cache folder, including `${HOME}/.cache/cache-safe-rm-$$`

## [1.0.11] - 2026-09-29

### Added

- `safe-rm setup` keeps two layers. A finished `self-install` or `self-update` runs this setup. This login writes `${HOME}/.local/bin/safe-rm` (mode `0700`), a `rm` symlink, and `origin-rm`, with no `sudo`. On Linux, setup then re-execs this program through `sudo` and moves `/usr/bin/rm` and `/bin/rm` to `origin-rm`. macOS, Termux, Git Bash, and Windows cmd do not call `sudo`. macOS leaves `/bin/rm` in place. On macOS the home `origin-rm` execs `/bin/rm`. On Linux the home `origin-rm` is a copy of the original remover, taken before that move
- Profile-ensure creates a missing `~/.profile` (mode `0644`) that sources `~/.bashrc`. An existing `.profile` stays as it is. Path-ensure writes `export PATH="${HOME}/.local/bin:$PATH"` once on `~/.bashrc`, on `~/.zshenv` when zsh applies, and on Fish. Uninstall leaves `.profile` in place and removes those PATH blocks only when `~/.local/bin` is empty

## [1.0.10] - 2026-09-28

### Fixed

- `sudo safe-rm self-update` wrote the new program to `/usr/local/bin/safe-rm` and left `rm` on the older `/usr/bin/safe-rm`. A finished `self-install` or `self-update` now runs `setup` when this login may, so `rm` is the file just placed. That includes an already-current `self-update`. A non-root place does not run `setup` and does not stop with the admin-login error. On Termux, this login's place runs the `$PREFIX/bin` setup

## [1.0.9] - 2026-09-27

### Fixed

- On Termux, `rm -rf $PREFIX/var` was allowed. `$PREFIX` stands for `/usr`, so that path is the same kind of directory as `/var`. The guard now refuses `$PREFIX`, `$PREFIX/bin` and anything inside it, and the exact directories `$PREFIX/etc`, `$PREFIX/var`, `$PREFIX/lib`, `$PREFIX/lib64`, `$PREFIX/opt`, `$PREFIX/sbin`, and `$PREFIX/boot`. A folder inside `$PREFIX/var`, such as `$PREFIX/var/log`, stays allowed. `$PREFIX/share`, `$PREFIX/include`, `$PREFIX/tmp`, and `$PREFIX/libexec` stay allowed

## [1.0.8] - 2026-09-27

### Fixed

- On Termux, `which rm` is `$PREFIX/bin/rm` (`/data/data/com.termux/files/usr/bin/rm`). `safe-rm setup` was refusing that host with `That needs an admin login` because it only looked at `/usr/bin/rm` and `/bin/rm`. This login now moves `$PREFIX/bin/rm` and does not call `sudo`. A symlink to `coreutils`, `toybox`, or `busybox` is not renamed; `$PREFIX/bin/origin-rm` runs that program's `rm`

## [1.0.7] - 2026-09-27

### Fixed

- `safe-rm setup` checks `/usr/bin/rm` and `/bin/rm`. A directory with no `rm` does not cancel the other. On Alpine those paths differ: `/bin/rm` is BusyBox and `/usr/bin/rm` is often absent. That symlink is not renamed to `origin-rm`, because BusyBox would then refuse to remove files. `/bin/origin-rm` runs `busybox rm`, and `/bin/rm` points at this program

## [1.0.6] - 2026-09-27

### Changed

- `install` and `self-install`, when this file is not started by a shell, copy that file and do not download. Root (`sudo src/safe-rm install --force`) copies it into `/usr/local/bin/`. This login copies it into `${HOME}/.local/bin/`. A shell pipe still downloads

## [1.0.5] - 2026-09-27

### Changed

- On the command named `rm`, a bare command word is a path again. `rm version` removes a link named `version`. `rm --version` still prints this version. The same split applies to `help`, `about`, `version-check`, `self-update`, `self-uninstall`, `self-install`, `install`, `menu`, `main`, `setup`, and `restore`
- `safe-rm version` and `safe-rm --version` stay this program's version. `-restore` stays the 2023 restore token

## [1.0.4] - 2026-09-27

### Added

- Each command is also a switch: `help` and `--help`, `version` and `--version`, `self-install` and `--self-install`, and the same pair for `about`, `version-check`, `self-update`, `self-uninstall`, `install`, `menu`, `main`, `setup`, `restore`, and `rm`
- When this program is the `rm` people type, `rm version` and `rm --version` print this version. They do not remove a file named `version`. `origin-rm --version` is still the remover's own text

## [1.0.3] - 2026-09-27

### Fixed

- `rm` after setup is `/usr/bin/safe-rm`. A root `self-install` used to write only `/usr/local/bin/safe-rm`, so `rm -rf` still ran the older guard and reported `Unknown command or flag: -rf`
- When `origin-rm` is already present, a root place and a later `setup` replace that guard with this program. They do not move `origin-rm` again. A non-root place does not write it

## [1.0.2] - 2026-09-27

### Added

- Choice **11** lists the subfolders of the current path, then a number to type a path. **0** steps back without removing
- Scratch for this run is a cache folder named for this login and this process. On Linux the preferred folder is under `/dev/shm/cache/`, then `/tmp/cache/`, then `~/.cache`. Git Bash uses `/tmp/cache/` then `AppData/Local/Temp`. Mac uses `/tmp/cache/`, then `~/Library/Caches`, then `~/cache`. Persistence stays `~/.local/safe-rm`
- `safe-rm about` prints the cache folder that was used, the preferred folder, the fallbacks for this host, and persistence. A skipped tier is silent

### Changed

- About no longer labels scratch as Storage (effective) or Storage (fallback)

## [1.0.1] - 2026-09-27

### Added

- `safe-rm setup` checks whether `/usr/bin/origin-rm` or `/bin/origin-rm` already holds the original `rm`. An admin login moves that binary aside and points `rm` at this program. A second setup does not move it again
- `safe-rm restore` and `-restore` put `origin-rm` back as `rm`
- Interactive `safe-rm --debug` opens the main menu. `--debug` is not a command

### Security

- A non-admin `setup` moves nothing
- The swap test uses `/tmp/safe-rm-swap.*` and does not remove a directory

## [1.0.0] - 2026-09-27

### Added

- First safe-rm release, specialized from the selfmanaged Type 0 architecture (self-install, self-update, self-uninstall, about, `out_*`, companion SHA-256)
- `rm` checks each path and refuses the login home itself, `/home`, another login's folder under `/home`, `/usr/bin` and anything inside it, and other system directories. A folder inside the login home may be removed
- A refusal exits non-zero, removes nothing (including paths in the same command that would have been allowed), and tells the operator to stop and not retry with `rm`, `/bin/rm`, or `/usr/bin/rm`
- `--dry-run` reports whether each path exists and whether removal is allowed, and does not remove anything
- Domain law `requirement-domain-safe-rm` and dry-run suite `tests/run_dry_run.sh` (`TP-SRM-01` .. `TP-SRM-19`)
- On a terminal, no arguments (and `menu` / `main`) opens the same numbered board as selfmanaged: **1** remove-guard (**11** `rm`), **8** self-management (**82–87**), **9** Exit. A pipe, quiet, or json run with no arguments still places the program

### Changed

- A folder inside the login home, such as `${HOME}/.cache`, is allowed. The login home directory itself stays refused
- Every account home recorded in `/etc/passwd` is refused the same way as the login home
- Domain requirement 1.1.0 restores the 2023 setup: move the system `rm` to `origin-rm`, point `rm` at this program, and `restore` puts the original binary back. A folder inside any account home is allowed. The ship unit does not perform the swap yet

### Security

- The 1.0.0 ship unit does not yet replace `/bin/rm` or `/usr/bin/rm`. Domain law 1.1.0 requires that swap
- `src/safe-rm.sha256` is the companion digest for this ship unit

The bootstrap changelog for the inherited Type 0 line stays with the selfmanaged reference tree.
