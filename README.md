# safe-rm - Guarded replacement for the system rm

![Version](https://img.shields.io/badge/Version-1.0.15-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20v2.10.*-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/safe-rm?style=flat-square)](https://github.com/cloudgen/safe-rm)

safe-rm is a guarded replacement for the system `rm` command, so a person, a script, or an automated agent cannot wipe the machine or a login home with one `rm -rf`.

| Who | What happens |
|-----|----------------|
| You | You, a script, or an automated agent types `rm`. This program checks every path before anything is deleted. |
| `origin-rm` | The original remover. Setup saves it under that name. It runs only after every path in the command is allowed. |
| The system `rm` | After setup, the `rm` people type is this program. A shell alias does not cover `sh -c "rm …"` or a direct `/bin/rm`. Those calls reach this guard. |

**It stops these deletes**

- The system directories themselves: `/`, `/usr`, `/bin`, `/sbin`, `/etc`, `/var`, `/boot`, `/root`, `/lib`, `/lib64`, `/opt`, `/dev`, `/proc`, and `/sys`. `/usr/bin` and anything inside it are refused, including a symlink that lands there.
- The login home, any directory that contains that home, `/home`, and every account home recorded in the password database (`/etc/passwd`, and the same homes from `getent passwd`).
- The text `$HOME`, `${HOME}`, or `~` when the shell did not expand it. Those still mean the login home.
- `.` and `..` when that directory would otherwise be allowed (`rm -rf .`, `rm -rf ..`). Name the folder itself. `$HOME/.` is still the login home.

**It still allows these deletes**

- A named folder inside an account home, such as a cache directory. The home directory itself stays refused.
- A folder outside the refused trees, such as a directory under `/tmp`.
- A file inside `/etc`, such as `/etc/hostname`. That file is not the `/etc` directory. A folder inside `/var`, such as `/var/log`, is not the `/var` directory.
- A name that starts with `-`, once it is a path: `rm -- -file` or `./-file`. Before `--`, that token is a switch.

If the shell expands `$HOME/*` before this program starts, each child arrives as its own path. A named folder inside the home is allowed, so that expanded list can clear the home. Name the one folder you mean.

If one path in the command is refused, no path is removed. The error says `STOP` and tells you not to retry with `rm`, `/bin/rm`, or `/usr/bin/rm`.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| See whether a folder may be removed | Nothing is deleted. You learn whether the path exists and whether removal is allowed. | `safe-rm rm --dry-run /tmp/my-folder` |
| Remove an ordinary folder | The remover runs only when every path is allowed. | `safe-rm rm -r /tmp/my-folder` |
| Touch a home directory or `/usr/bin` | The command stops. Nothing is removed. | `safe-rm rm --dry-run "$HOME"` |
| Remove a folder inside the login home | The home directory itself stays refused. The named folder may be removed. | `safe-rm rm --dry-run "$HOME/.cache"` |

The program file people install is `src/safe-rm`. It is one POSIX `/bin/sh` script. You do not install Python, Node, or another language.

## Features

- **System directories and account homes stay.** The guard refuses the directories listed above, the login home, any ancestor that contains that home, and every account home in the password database.
- **A named folder inside the home may go.** A cache directory, or another folder you name inside the login home, may be removed. The home directory itself may not.
- **Setup replaces the system `rm`.** On Linux, `safe-rm setup` moves `/usr/bin/rm` and `/bin/rm` aside to `origin-rm` and points `rm` at this program, so a non-interactive `sh -c "rm …"` hits the guard. This login also gets `~/.local/bin/rm`. macOS, Alpine, and Termux are described under Platform Compatibility, because their system `rm` cannot be renamed the same way.
- **One refusal cancels the whole command.** Every path is resolved and classified before `origin-rm` runs. One disallowed path removes nothing.
- **`--dry-run` only looks.** It reports whether each path exists and whether removal is allowed, and it deletes nothing.
- **The same script manages itself.** `self-install`, a SHA-256 companion check, `self-update`, and `self-uninstall` are built in. Linux, macOS, Alpine (BusyBox), and Termux are supported. Git Bash and Windows keep the home guard and leave the system `rm` in place.

## Where to use it

### Strongly recommended

**Agent sandboxes.** Docker, LXC, and a remote virtual machine are where this guard earns its keep. trash-cli, rip, and the Perl safe-rm are usually a shell alias or an `rm` placed earlier on `PATH`. An automated agent often runs a direct subshell, `/bin/sh -c "/bin/rm -rf /"`, which never consults an alias or `PATH`. On Linux, `safe-rm setup` replaces `/bin/rm` and `/usr/bin/rm`, so that absolute call goes through this program and `/` is refused. macOS leaves Apple's `/bin/rm` in place, so this is the recommendation for a Linux container or VM.

**A small system with no extra language.** Alpine images, BusyBox, and Termux often have no Python, Cargo, or Go. This program is one POSIX `/bin/sh` file and runs there without those runtimes. On Alpine, setup points `/bin/rm` at this program and keeps BusyBox as `origin-rm`. On Termux, setup points `$PREFIX/bin/rm` at this program and does not call `sudo`.

**An empty variable that becomes `/`.** When `UNSET_VAR` is empty, `rm -rf "${UNSET_VAR}/"` is the path `/`. The guard refuses `/` and removes nothing. When the star sits outside the quotes, `rm -rf ${UNSET_VAR}/*`, the shell expands it to the children of `/`. That list includes a refused directory, so the whole command stops and nothing is removed. The quoted form `rm -rf "${UNSET_VAR}/*"` is the single name `/*`, not `/`. A missing file of that name is allowed. Do not build a path from an empty variable.

### Use caution

**A daily Linux workstation or a production host.** Setup renames the distribution's `/bin/rm` to `origin-rm` and puts a symlink in its place. apt, dnf, apk, and pacman check the hashes of packaged files and own `/bin/rm`. An upgrade of coreutils or base-files can replace that symlink, or report that `/bin/rm` no longer matches the package. Root can run `safe-rm reset` to point `/bin/rm` and `/usr/bin/rm` back at `origin-rm` without deleting `origin-rm`. A later `setup` points them at the guard again. The packaged file is still not restored; `safe-rm restore` is the command that moves `origin-rm` back to the `rm` name.

**A build that calls `rm` thousands of times.** `make clean`, `cargo clean`, and a test run start this shell for every `rm`. Each call resolves the paths and reads the password database. A compiled `rm` does not pay that cost.

**A trash bin with undo.** This program is a check that runs before deletion. An allowed path is handed to `origin-rm` and unlinked. There is no recycle bin and no undo. trash-cli and rip are the tools that keep a trash bin you can restore.

### Comparison

| Use case | cloudgen/safe-rm | Debian safe-rm (Perl or Rust) | trash-cli (Python) | rip (Rust) |
|----------|------------------|-------------------------------|--------------------|------------|
| Absolute `/bin/rm` inside `/bin/sh -c` | Yes, after Linux setup replaces `/bin/rm` and `/usr/bin/rm` | No. It is a symlink earlier on `PATH` | No. It is a different command, or an alias | No. It is an alias or an earlier `PATH` entry |
| Extra runtime | None. One `/bin/sh` file | Perl or a Rust runtime | Python 3 | A compiled Rust binary (Cargo to build) |
| Systems | Linux, macOS, Alpine, BusyBox, Termux | Linux first | Linux, macOS | Linux, macOS |
| Undo | No. A refused path stays. An allowed path is unlinked by `origin-rm` | No. A refusal list only | Yes. Freedesktop trash | Yes. A graveyard directory |
| Effect on the packaged `rm` | High on Linux. Setup replaces `/bin/rm` and `/usr/bin/rm` | Low. A wrapper under `/usr/local/bin` | Low | Low |

macOS leaves Apple's `/bin/rm` in place, so the first row is the Linux setup. Debian safe-rm's own manual tells you to link `rm` to `safe-rm` in a directory ahead of `/bin` on `PATH`.

## Quick Installation

Runtime version: `VERSION="1.0.15"` in `src/safe-rm`.

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

The program downloads the companion `https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm.sha256` by itself. The algorithm is SHA-256. The digest is the first field of `src/safe-rm.sha256`. Human output shows the companion link, the expected value, and the result.

| Result | What happens |
|--------|----------------|
| Match | The install continues |
| Mismatch | The install stops. The mismatched file is not installed |
| Companion missing | A warning is printed and the install continues |

A missing companion means the bytes were not checked. This companion is not a vendor signature.

From a checkout, `$0` is this file, not a shell. `install` copies that file and does not download:

```sh
sudo src/safe-rm install --force
src/safe-rm install
```

Root copies it into `/usr/local/bin/` (mode `0755`). This login copies it into `${HOME}/.local/bin/` (mode `0700`). The place step does not call `sudo`. On Linux, `safe-rm setup` calls `sudo` only to move `/usr/bin/rm` and `/bin/rm`. `sudo` on the install command is what makes the copy global.

```sh
./src/safe-rm self-install
safe-rm about
```

- This login's install lands in `${HOME}/.local/bin/safe-rm` (mode `0700`), writes the home guard (`safe-rm`, an `rm` symlink, and `origin-rm`), and creates a missing `~/.profile` that sources `~/.bashrc`. The `~/.local/bin` PATH line lives on `~/.bashrc`. Zsh keeps that line on `~/.zshenv`. On Linux the install then asks `sudo` to move the system `rm`.
- Root install lands in `/usr/local/bin/safe-rm` (mode `0755`) and runs both layers. When `SUDO_USER` is set, the home guard is that account's `~/.local/bin`.
- `self-update` runs the same setup, including when the bin copy is already current.
- When `origin-rm` is already present, that setup replaces the guard and does not move `origin-rm` again. When it is absent, setup performs the first move.
- On a terminal, no arguments opens the numbered list (same as `safe-rm menu`).
- A pipe, `--quiet`, or `--json` with no arguments still places the program.
- Online install checks `src/safe-rm.sha256` when the companion is on the same channel.

### Advanced

An automation pin can require an exact digest. Set `CHECKSUM` only when you already hold that digest from somewhere other than this download. A mismatch stops the install. Fetching the digest from the same URL and pinning it is the same check the program already performs. `help` and `about` do not list that pin.

### Main menu

After install, on a terminal:

```text
$ safe-rm
[INFO] **safe-rm**(*1.0.15*) — Guarded rm that refuses login homes and system directories
1. **remove-guard**: *check a path and remove it only when it is allowed*
8. **self-management**: *this CLI install, version, update, uninstall*
9. Exit
Choice:
```

**1** opens the remove-guard board:

```text
[INFO] **safe-rm**(*1.0.15*) — remove-guard
11. **rm**: *check each path and remove only when every path is allowed*
0. Back
```

**11** lists each immediate subfolder of the current directory, then one number to type a path. The sample below was a temporary directory that held `cache` and `notes`. Your numbers are the folders where you are. That path runs the same guard as `safe-rm rm`.

```text
[INFO] **safe-rm**(*1.0.15*) — remove-guard
[INFO] Current path: /tmp/safe-rm-menu-demo
1. **cache**: */tmp/safe-rm-menu-demo/cache*
2. **notes**: */tmp/safe-rm-menu-demo/notes*
3. **custom-path**: *type a path*
0. Back
```

**8** opens self-management. **81** is not listed.

```text
[INFO] **safe-rm**(*1.0.15*) — self-management
82. **version**: *show current version*
83. **about**: *show detailed diagnostics*
84. **version-check**: *compare local vs remote version*
85. **self-update**: *update safe-rm to a newer remote version, then run setup when this login may*
86. **self-uninstall**: *remove safe-rm*
87. **self-install**: *copy this file into /usr/local/bin or ${HOME}/.local/bin, then run setup when this login may*
0. Back
```

Choose a number, or type the command name. `9` leaves the program. `0` on a submenu goes back. After a command finishes, the front board is shown again. A number that is not on the list prints an error and lets you choose again.

## Usage

Each command is also a switch with the same name: `help` and `--help`, `version` and `--version`, and the same pair for `about`, `version-check`, `self-update`, `self-uninstall`, `self-install`, `install`, `menu`, `main`, `setup`, `restore`, and `rm`. On `safe-rm`, the bare word and the switch are the same command. When `rm` is this program, only the switch is that command: `rm --version` prints this version, and `rm version` removes a link named `version`. The same split applies to every other command word. The remover's own text is `origin-rm --version`.

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
safe-rm reset             # root or sudo: point system rm at origin-rm when that file exists
safe-rm rm --dry-run <path>
safe-rm rm -r <path>     # real remove only when every path is allowed
```

`--quiet` hides the allowed-path notes. A refusal is still printed. `--json` prints one object on stdout with `dry_run`, `removed`, `exists`, `verdict`, and `class`. `removed` is `false` during a dry-run. `--debug` adds detail.

Scratch for one run lives in a cache folder named for this login and this process. On Linux that folder is under `/dev/shm/cache/` when that directory can be created, then `/tmp/cache/`, then `~/.cache`. Git Bash and Mac use their own chains. A folder that cannot be created is skipped with no warning. Durable data for this login is `~/.local/safe-rm`. `safe-rm about` prints the folder that was used, the preferred folder, the fallbacks, and persistence.

### Which paths the guard checks

| Path | Verdict |
|------|---------|
| Any account home (`rm -rf` of that directory) | Refused. Removing the home directory deletes everything in it |
| A named folder inside any account home, such as a cache directory | Allowed. That folder is not the home directory |
| `/home` | Refused. It is the parent of the homes |
| The text `$HOME`, `${HOME}`, or `~` | Refused. Those stand for the login home even when the shell did not expand them |
| The text `$HOME/...`, `${HOME}/...`, or `~/...` | Allowed. Those stand for a folder inside the login home |
| `/usr/bin` and anything inside it | Refused. Removing it breaks programs. A symlink that lands on `/usr/bin` is the same refusal |
| `/`, `/usr`, `/bin`, `/sbin`, `/etc`, `/var`, `/boot`, `/root`, `/lib`, `/lib64`, `/opt`, `/dev`, `/proc`, `/sys` | Refused. System directories |
| On Termux: `$PREFIX`, `$PREFIX/bin` and anything inside it, and exactly `$PREFIX/etc`, `$PREFIX/var`, `$PREFIX/lib`, `$PREFIX/lib64`, `$PREFIX/opt`, `$PREFIX/sbin`, `$PREFIX/boot` | Refused. These stand for the Linux rows above. A folder inside `$PREFIX/var`, and `$PREFIX/share`, `$PREFIX/include`, `$PREFIX/tmp`, and `$PREFIX/libexec`, may be removed |
| `.` or `..` as the final component (`rm -rf .`, `rm -rf ..`, `./`, `../`) | Refused when the directory would otherwise be allowed. Name the folder. `$HOME/.` is still the login home. `leaf/../leaf` is `leaf` |
| A file whose name starts with `-` | A path after `--`, or as `./-file`. Before `--` it is a switch |

## Examples

```sh
safe-rm rm --dry-run /tmp/my-folder
safe-rm --dry-run rm -rf /tmp/my-folder
safe-rm --json rm --dry-run /tmp/my-folder
```

Human output says whether the path exists and whether removal is allowed. JSON is one object on stdout. `removed` is `false` during a dry-run.

```sh
safe-rm rm --dry-run "$HOME"          # refused: the login home
safe-rm rm --dry-run "$HOME/.cache"   # allowed: a named folder inside the home
safe-rm rm --dry-run .                # refused: '.' would remove the current directory
safe-rm rm -- -file                   # a file whose name starts with -
```

A real delete uses the same paths without `--dry-run`, and only when every path is allowed. The success line names the caller and each path. On a terminal those names are italic. A script that was executed is named. A file that was only sourced is the shell, such as `-bash`, and the path is still named:

```sh
safe-rm rm -r /tmp/my-folder
```

## Platform Compatibility

The home guard is written on every supported host: `${HOME}/.local/bin/safe-rm` (mode `0700`), an `rm` symlink to it, and `origin-rm`. `safe-rm restore` puts the system file back, then removes the home `rm` and `origin-rm`.

**Linux.** Setup then re-execs through `sudo` and moves `/usr/bin/rm` and `/bin/rm` to `origin-rm`. A directory with no `rm` does not cancel the other. When `/bin` and `/usr/bin` are the same directory, one `rm` and one `origin-rm` suffice. The real delete is one exec of `origin-rm` with the switches you typed, then `--`, then the allowed paths. This program does not exec `/usr/bin/rm`, `/bin/rm`, or `$PREFIX/bin/rm`.

**macOS.** `/bin/rm` stays Apple's binary. Setup does not call `sudo` and does not replace `/bin/rm` or `/usr/bin/rm`. The home `origin-rm` execs `/bin/rm`. A bare `rm` hits the guard when `~/.local/bin` is ahead of `/bin` on `PATH`. `sudo rm` and an absolute `/bin/rm` stay Apple's `rm`.

**Alpine and BusyBox.** `/bin` and `/usr/bin` are different directories. The `rm` people type is `/bin/rm`, a symlink to BusyBox. `/usr/bin/rm` is often absent, so `which rm` prints `/bin/rm`. Setup does not stop because `/usr/bin` has no `rm`, and it does not create `/usr/bin/rm`. It does not rename the BusyBox symlink to `origin-rm`, because BusyBox would then refuse to remove files. After setup, `/bin/rm` points at this program and `/bin/origin-rm` runs `busybox rm`. `safe-rm restore` puts the BusyBox symlink back.

**Termux.** `which rm` prints `/data/data/com.termux/files/usr/bin/rm`. That is `$PREFIX/bin/rm`. It is not `/usr/bin/rm` or `/bin/rm`. This login owns that directory. Setup moves that file and does not call `sudo`. It does not move `/usr/bin/rm` or `/bin/rm`. After setup, `$PREFIX/bin/rm` points at this program and `$PREFIX/bin/origin-rm` is the remover. When `rm` is a symlink to `coreutils`, `toybox`, or `busybox`, that symlink is not renamed, because those programs would then refuse to remove files. `origin-rm` runs that program's `rm`. `safe-rm restore` puts the original file back.

The same blacklist applies under `$PREFIX`. `$PREFIX` stands for `/usr`. `$PREFIX/bin` and anything inside it stand for `/usr/bin` (Termux keeps `/bin` there too). These directories are refused exactly, the same way `/var` is refused: `$PREFIX/etc`, `$PREFIX/var`, `$PREFIX/lib`, `$PREFIX/lib64`, `$PREFIX/opt`, `$PREFIX/sbin`, and `$PREFIX/boot`. `rm -rf $PREFIX/var` stops. A folder inside `$PREFIX/var`, such as `$PREFIX/var/log`, may be removed. `$PREFIX/share`, `$PREFIX/include`, `$PREFIX/tmp`, and `$PREFIX/libexec` may be removed. `/`, `/dev`, `/proc`, and `/sys` stay the Linux paths. The login home stays refused.

**Git Bash and Windows.** Setup writes the home guard and does not move the system `rm`.

## Related Projects

The defensive style is [CIAO](https://github.com/cloudgen/ciao) (Caution, Intentional, Anti-fragile, Over-protect).

## Contributing

Issues and changes go to [cloudgen/safe-rm](https://github.com/cloudgen/safe-rm).

The remove suite is dry-run, except one check that execs a fixture remover under `/tmp/safe-rm-swap.*` and leaves the path in place:

```sh
sh tests/run_dry_run.sh
```

It does not delete the login home, `/usr/bin`, or the temporary folder it creates for the allowed-path check.

## License

MIT. The full text is [LICENSE.md](LICENSE.md).

## Last Update

2026-09-30 — a finished remove names the caller and each path, for version 1.0.15.
