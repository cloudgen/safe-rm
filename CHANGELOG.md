# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
