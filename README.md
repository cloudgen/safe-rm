# safe-rm

![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20v2.10.*-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/safe-rm?style=flat-square)](https://github.com/cloudgen/safe-rm)

**safe-rm** is a POSIX `/bin/sh` program you install for yourself. It can place itself on your PATH, update itself, and remove itself. Its extra job is a guarded `rm`: it refuses a login home, anything under `/home`, `/usr/bin`, and other system directories, and it says so in an error that tells you to stop.

The program people install is `src/safe-rm`. The architecture (self-install, `out_*` messages, checksum, empty command line means install) comes from the **selfmanaged** bootstrap. This product does not replace `/bin/rm` or `/usr/bin/rm`.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| See whether a folder may be removed | Nothing is deleted. You learn whether the path exists and whether removal is allowed | `safe-rm rm --dry-run /tmp/my-folder` |
| Remove an ordinary folder | Runs only when every path is allowed | `safe-rm rm -r /tmp/my-folder` |
| Touch a login home or `/usr/bin` | The command stops. Nothing is removed | `safe-rm rm --dry-run "$HOME"` |

## What is refused

| Path | Why |
|------|-----|
| The login home, and anything inside it | A recursive remove here destroys projects and local files |
| `/home` and anything inside `/home` | That is a login's files, including another user's home |
| The text `$HOME`, `${HOME}`, or `~` | Those stand for a login home even when the shell did not expand them |
| `/usr/bin` and anything inside it | Removing it breaks programs. A symlink that lands on `/usr/bin` is the same refusal |
| `/`, `/usr`, `/bin`, `/sbin`, `/etc`, `/var`, `/boot`, `/root`, `/lib`, `/lib64`, `/opt`, `/dev`, `/proc`, `/sys` | System directories |

If one path in the command is refused, **no** path is removed. The error says `STOP` and tells you not to retry with `rm`, `/bin/rm`, or `/usr/bin/rm`.

A folder outside those trees, such as a directory under `/tmp`, may be removed. `--dry-run` still removes nothing.

## Dry-run

```sh
safe-rm rm --dry-run /tmp/my-folder
safe-rm --dry-run rm -rf /tmp/my-folder
safe-rm --json rm --dry-run /tmp/my-folder
```

Human output says whether the path exists and whether removal is allowed. JSON is one object on stdout with `dry_run`, `removed`, `exists`, `verdict`, and `class`. `removed` is `false` during a dry-run.

`--quiet` hides the allowed-path chatter. A refusal is still printed.

## Install

Runtime version: `VERSION="1.0.0"` in `src/safe-rm`.

Channel default:

```text
https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm
```

That one-liner works after this file is published on that channel. From a checkout, copy the file you have:

```sh
./src/safe-rm self-install
safe-rm about
```

- Non-root install lands in `~/.local/bin/safe-rm` (mode `0700`)
- Root install lands in `/usr/local/bin/safe-rm` (mode `0755`)
- Empty command line means install-ensure, not help and not a remove
- Online install checks `src/safe-rm.sha256` when the companion is on the same channel

Messages go through `out_*` (`--quiet`, `--json`, `--debug`). Do not look for a second printer.

## Usage

```sh
safe-rm                  # no arguments: install-ensure
safe-rm help
safe-rm about
safe-rm version
safe-rm self-install
safe-rm version-check
safe-rm self-update
safe-rm self-uninstall
safe-rm rm --dry-run <path>
safe-rm rm -r <path>     # real remove only when every path is allowed
```

## Tests

The remove suite is dry-run only:

```sh
sh tests/run_dry_run.sh
```

It does not delete the login home, `/usr/bin`, or the temporary folder it creates for the allowed-path check.
