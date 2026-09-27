# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-09-27

### Added

- First safe-rm release, specialized from the selfmanaged Type 0 architecture (self-install, self-update, self-uninstall, about, `out_*`, companion SHA-256)
- `rm` checks each path and refuses the login home and anything inside it, `/home` and anything inside it, `/usr/bin` and anything inside it, and other system directories
- A refusal exits non-zero, removes nothing (including paths in the same command that would have been allowed), and tells the operator to stop and not retry with `rm`, `/bin/rm`, or `/usr/bin/rm`
- `--dry-run` reports whether each path exists and whether removal is allowed, and does not remove anything
- Domain law `requirement-domain-safe-rm` and dry-run suite `tests/run_dry_run.sh` (`TP-SRM-01` .. `TP-SRM-19`)

### Security

- The program does not replace `/bin/rm` or `/usr/bin/rm`
- `src/safe-rm.sha256` is the companion digest for this ship unit

The bootstrap changelog for the inherited Type 0 line stays with the selfmanaged reference tree.
