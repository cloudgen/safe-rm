# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
