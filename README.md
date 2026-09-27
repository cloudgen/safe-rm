# safe-rm

![Version](https://img.shields.io/badge/Version-1.0.8-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20v2.10.*-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/safe-rm?style=flat-square)](https://github.com/cloudgen/safe-rm)

**safe-rm** is a POSIX `/bin/sh` program. `rm -rf` is too dangerous to leave as the raw binary, so setup moves that binary aside to `origin-rm` and points `rm` at this guard. It keeps the selfmanaged lifecycle: place itself, update itself, remove itself, and the numbered menu. `rm -rf` of any account home is refused, because that deletes the whole home. A folder inside any account home, such as a cache directory, may be removed. A refusal is an `out_*` error that tells you to stop.

The program people install is `src/safe-rm`. The lifecycle and `out_*` come from the **selfmanaged** bootstrap. The swap, `origin-rm`, and `restore` are the 2023 safe-rm setup. `safe-rm setup` is for an admin login on a Linux host. It checks `/usr/bin/rm` and `/bin/rm`. A directory with no `rm` does not cancel the other. It moves a regular `rm` aside to `origin-rm` and points `rm` at this program. On Termux, `which rm` is `$PREFIX/bin/rm` and this login runs that setup. `safe-rm restore` puts that file back. The test of that table uses a scratch directory under `/tmp` and does not delete a directory.

## Alpine

On Alpine, `/bin` and `/usr/bin` are different directories. The `rm` people type is `/bin/rm`, a symlink to BusyBox. `/usr/bin/rm` is often absent, so `which rm` prints `/bin/rm` and `rm --version` is BusyBox text.

`safe-rm setup` checks both paths. It does not stop because `/usr/bin` has no `rm`, and it does not create `/usr/bin/rm`. It does not rename the BusyBox symlink to `origin-rm`, because BusyBox would then refuse to remove files. After setup, `/bin/rm` points at this program and `/bin/origin-rm` runs `busybox rm`. `safe-rm restore` puts the BusyBox symlink back.

## Termux

On Termux, `which rm` prints `/data/data/com.termux/files/usr/bin/rm`. That is `$PREFIX/bin/rm`. It is not `/usr/bin/rm` or `/bin/rm`. This login owns that directory.

`safe-rm setup` moves that file and does not call `sudo`. It does not ask for an admin login. It does not move `/usr/bin/rm` or `/bin/rm`. After setup, `$PREFIX/bin/rm` points at this program and `$PREFIX/bin/origin-rm` is the remover. When `rm` is a symlink to `coreutils`, `toybox`, or `busybox`, that symlink is not renamed, because those programs would then refuse to remove files. `origin-rm` runs that program's `rm`. `safe-rm restore` puts the original file back.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| See whether a folder may be removed | Nothing is deleted. You learn whether the path exists and whether removal is allowed | `safe-rm rm --dry-run /tmp/my-folder` |
| Remove an ordinary folder | Runs only when every path is allowed | `safe-rm rm -r /tmp/my-folder` |
| Touch a home directory or `/usr/bin` | The command stops. Nothing is removed | `safe-rm rm --dry-run "$HOME"` |
| Remove a folder inside any account home | Allowed. The home directory itself stays refused | `safe-rm rm --dry-run "$HOME/.cache"` |

## Which paths the guard checks

| Path | Verdict |
|------|---------|
| Any account home (`rm -rf` of that directory) | Refused. Removing the home directory deletes everything in it |
| A named folder inside any account home, such as a cache directory | Allowed. That folder is not the home directory |
| `/home` | Refused. It is the parent of the homes |
| The text `$HOME`, `${HOME}`, or `~` | Refused. Those stand for the login home even when the shell did not expand them |
| The text `$HOME/...`, `${HOME}/...`, or `~/...` | Allowed. Those stand for a folder inside the login home |
| `/usr/bin` and anything inside it | Refused. Removing it breaks programs. A symlink that lands on `/usr/bin` is the same refusal |
| `/`, `/usr`, `/bin`, `/sbin`, `/etc`, `/var`, `/boot`, `/root`, `/lib`, `/lib64`, `/opt`, `/dev`, `/proc`, `/sys` | Refused. System directories |

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

Runtime version: `VERSION="1.0.8"` in `src/safe-rm`.

Channel default:

```text
https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm
```

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm | sh
```

Root, when this machine has it:

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm | sudo sh
```

With no `CHECKSUM` set, that download checks the companion `https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm.sha256` (SHA-256, first field). A match continues. A mismatch stops the install. A missing companion warns and continues. From a checkout, `$0` is this file, not a shell. `install` copies that file and does not download:

```sh
sudo src/safe-rm install --force
src/safe-rm install
```

Root copies it into `/usr/local/bin/`. This login copies it into `${HOME}/.local/bin/`. The program does not run `sudo` itself. `sudo` on the command is what makes the copy global.

```sh
./src/safe-rm self-install
safe-rm about
```

- Non-root install lands in `${HOME}/.local/bin/safe-rm` (mode `0700`)
- Root install lands in `/usr/local/bin/safe-rm` (mode `0755`)
- When `origin-rm` is already present, that root install also replaces `/usr/bin/safe-rm` (the file `rm` runs) with this program. It does not move `origin-rm` again
- On a terminal, no arguments opens the numbered list (same as `safe-rm menu`)
- A pipe, `--quiet`, or `--json` with no arguments still places the program
- Online install checks `src/safe-rm.sha256` when the companion is on the same channel

At a terminal the front board is:

```text
safe-rm(1.0.8) — Guarded rm that refuses login homes and system directories
1. remove-guard: check a path and remove it only when it is allowed
8. self-management: this CLI install, version, update, uninstall
9. Exit
```

**1** opens:

```text
safe-rm(1.0.8) — remove-guard
11. rm: check each path and remove only when every path is allowed
0. Back
```

**11** lists each subfolder of the current path as a number, then one number to type a path. That path runs the same guard as `safe-rm rm`. **8** opens version, about, version-check, self-update, self-uninstall, and self-install (**82–87**). **81** is not listed. **9** leaves. **0** steps back. A wrong number reprints that board.

Messages go through `out_*` (`--quiet`, `--json`, `--debug`). Do not look for a second printer.

Scratch for one run lives in a cache folder named for this login and this process. On Linux that folder is under `/dev/shm/cache/` when that directory can be created, then `/tmp/cache/`, then `~/.cache`. Git Bash and Mac use their own chains. A folder that cannot be created is skipped with no warning. Durable data for this login is `~/.local/safe-rm`. `safe-rm about` prints the folder that was used, the preferred folder, the fallbacks, and persistence.

## Usage

Each command is also a switch with the same name: `help` and `--help`, `version` and `--version`, `self-install` and `--self-install`, and the same pair for `about`, `version-check`, `self-update`, `self-uninstall`, `install`, `menu`, `main`, `setup`, `restore`, and `rm`. On `safe-rm`, the bare word and the switch are the same command. When `rm` is this program, only the switch is that command: `rm --version` prints this version, and `rm version` removes a link named `version`. The same split applies to every other command word. The remover's own text is `origin-rm --version`.

```sh
safe-rm                  # terminal: numbered menu; pipe: install-ensure
safe-rm menu             # same menu; help when there is no terminal
safe-rm help
safe-rm about
safe-rm version           # same as safe-rm --version
safe-rm --help
safe-rm self-install       # same as safe-rm --self-install
rm --version               # when rm is this program: this version
rm version                 # when rm is this program: a path named version
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
