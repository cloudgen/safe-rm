**file**: docs/requirements/requirement-domain-safe-rm.md
**id**: RQ-DOMAIN-SAFE-RM
**Status**: Active (Version 1.2.17)
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **current domain SSOT** for **safe-rm**. The 2023 program already moved the system `rm` aside to `origin-rm` and made `rm` run the guard, because `rm -rf` is too dangerous to leave as the raw binary. The self-management lifecycle stays with that setup (self-install, self-update, self-uninstall, version, about, help, the numbered menu). The improvement over 2023 is a reviewed blacklist and product sentences through `out_*`.

It also exists because an agent once ran a recursive remove of the login home after a command-scoped `HOME=` prefix. The prefix did not apply to the later remove, and the login home was the target.

**Scope:** the protected-`rm` setup (`origin-rm`, the `rm` link, `restore`, `reset`), the command named `rm` (the same switches as `origin-rm`, including `-rf`), the `safe-rm rm` verb, `--dry-run`, refuse classes, messages that tell the operator to stop, and the help/about rows for that guard.
**Out of scope:** Checksum and storage (peer shell requirements). Any remove that the tests perform with the host remover. `TP-SRM-39` may exec a fixture `origin-rm` under `/tmp/safe-rm-swap.*` that exits 0 and does not unlink; the listed path remains. Dropping the 2023 swap. The one `sudo` this product runs is the measure-2 re-exec in §2.0.5, and the same re-exec for `restore` and `reset`, not a general admin shell.

### 1.1 Human-facing

**In one sentence:** Setup puts two guards in front of the original remover, which is saved as `origin-rm`: first `${HOME}/.local/bin/rm` for this login, then, except on macOS, the system `rm` (`/usr/bin/rm` and `/bin/rm`, or on Termux `$PREFIX/bin/rm`); `rm -rf` of any account home is refused, a folder inside any account home may be removed, and `--dry-run` does not call the remover.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person or agent who types `rm` | `cd ~/` then `mkdir test` then `rm -rf test` |
| The other role | The remover: `/usr/bin/origin-rm` or `/bin/origin-rm`. Called only after every path is allowed and `--dry-run` is off | Not used by the dry-run suite |
| Not this file | Self-update checksum and the `out_*` printer | Peer shell requirements |

| Includes | Excludes |
|----------|----------|
| Swap of system `rm` to this guard, `restore`, `reset`, refuse rules, dry-run report | Leaving the raw `rm` binary as the command people type after setup |
| One JSON object for `rm` when `--json` is set | A second printer beside `out_*` |

| Surface | What you open | What for |
|---------|---------------|----------|
| `safe-rm help` | Command | Remove-guard rows and Type 0 rows |
| `safe-rm rm --dry-run <path>` | Command | Exists, and whether removal is allowed, with nothing removed |
| `src/safe-rm` | Program file | `srm_*` guard |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Ask before deleting | The program reports existence and the verdict and deletes nothing | `safe-rm rm --dry-run <path>` |
| Hit a home directory | The program exits non-zero and removes nothing. A folder inside that home is a different path | `safe-rm rm --dry-run` on the home, then on a folder inside it |
| Put the original binary back | `origin-rm` becomes `rm` again and the guard link is removed | `safe-rm restore` |
| Point `rm` at the saved remover | `origin-rm` stays. `rm` becomes a symlink to it. `safe-rm` stays | `safe-rm reset` |
| See which script removed a path | The success line names the caller and each path. On a terminal those names are italic | after a real remove |
| Install or update this program | The place finishes, then setup runs measure 1 in the home bin and measure 2 through `sudo` when this host is Linux and this login is not root | `safe-rm self-install` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.0 What "rm" means in this file

Two different files. Do not mix them.

| Word in this file | Path | What it is |
|-------------------|------|------------|
| **the remover** | `origin-rm` beside the guard. System: `/usr/bin/origin-rm` or `/bin/origin-rm`. Termux: `$PREFIX/bin/origin-rm`. Home: `${HOME}/.local/bin/origin-rm` | The original `rm`, saved under the prefix name `origin-rm`. **This is what deletes.** There is no second file named `rm-original`. |
| **the command people type** | The first `rm` on `PATH`. After measure 1 that is `${HOME}/.local/bin/rm` when that directory is first. After measure 2, `/usr/bin/rm` and `/bin/rm` are the same guard. On Termux, `$PREFIX/bin/rm` | A symlink to this program. It checks the path. It does not delete. |

1. The real delete follows §2.0.5. On Termux it **MUST** exec `$PREFIX/bin/origin-rm` and **MUST NOT** exec `/usr/bin/origin-rm`, `/bin/origin-rm`, `/usr/bin/rm`, or `/bin/rm`. On any other host it **MUST** exec `/usr/bin/origin-rm` when that file is executable, otherwise `/bin/origin-rm` when that file is executable, otherwise `${HOME}/.local/bin/origin-rm`.
2. The real delete **MUST NOT** exec `/usr/bin/rm`, `/bin/rm`, `$PREFIX/bin/rm`, or `${HOME}/.local/bin/rm`. Those paths are this program after the layer that owns them is in place. On macOS `/bin/rm` stays Apple's binary; the home `origin-rm` is the program that execs it. The guard itself **MUST NOT** exec `/bin/rm`.
3. When `/bin/rm` and `/usr/bin/rm` were the same file, one system `origin-rm` exists. Calling either origin path that names that file is the same remover.
4. `--dry-run` **MUST NOT** exec `/usr/bin/origin-rm`, `/bin/origin-rm`, `$PREFIX/bin/origin-rm`, or `${HOME}/.local/bin/origin-rm`.

### 2.0.1 Before swapped and after swapped

This table is measure 2 on Linux. Setup **MUST** turn the Before column into the After column. `restore` **MUST** turn After back into Before. When `/bin` and `/usr/bin` are the same directory, `/bin/rm` and `/usr/bin/rm` are one file, and one `origin-rm` covers both. macOS does not use this table: `/bin/rm` stays Apple's binary (§2.0.5). The home layer is also §2.0.5.

| Path | Before swapped | After swapped |
|------|----------------|---------------|
| `/usr/bin/rm` | The original `rm` binary. This file deletes. | A symlink to `/usr/bin/safe-rm`. This is the guard. It does not delete. |
| `/bin/rm` | The original `rm` binary. Same file as `/usr/bin/rm` when the directories are the same. | A symlink to the `safe-rm` in that same directory. This is the guard. It does not delete. |
| `/usr/bin/origin-rm` | Absent | The original binary moved from `/usr/bin/rm`. **This is the remover.** |
| `/bin/origin-rm` | Absent | The original binary moved from `/bin/rm` when that file was not already `/usr/bin/rm`. Absent when one move covered both. **When this file exists, it is the remover.** |
| `/usr/bin/safe-rm` | Absent | This program, mode `0755`. |
| `/bin/safe-rm` | Absent | This program, mode `0755`, when `/bin` is a different directory from `/usr/bin`. Otherwise the same file as `/usr/bin/safe-rm`. |

### 2.0.2 Alpine: `/bin/rm` and `/usr/bin/rm` are different paths

Alpine keeps those two paths apart. The system `rm` is BusyBox. The command people type is `/bin/rm`, a symlink to BusyBox. `/usr/bin/rm` is often absent. Setup **MUST** treat that host as normal. It **MUST** check both paths. It **MUST NOT** stop with no `rm` in `/usr/bin` while `/bin/rm` exists. It **MUST NOT** create `/usr/bin/rm` when that path was absent.

| Path | Before swapped | After swapped |
|------|----------------|---------------|
| `/usr/bin/rm` | Absent | Stays absent |
| `/bin/rm` | Symlink to BusyBox. `rm --version` is BusyBox text | Symlink to `/bin/safe-rm`. This is the guard |
| `/usr/bin/origin-rm` | Absent | Stays absent |
| `/bin/origin-rm` | Absent | Runs `busybox rm`. This is the remover. It is not the BusyBox symlink renamed |
| `/usr/bin/safe-rm` | Absent | Stays absent |
| `/bin/safe-rm` | Absent | This program, mode `0755` |

`restore` on that host puts the BusyBox symlink back at `/bin/rm` and removes `/bin/origin-rm` and `/bin/safe-rm`. A host where `/bin` and `/usr/bin` are the same directory stays on the §2.0.1 table. Proof: `TP-SRM-29`.

### 2.0.3 Termux: `which rm` is `$PREFIX/bin/rm`

Termux does not keep `rm` at `/usr/bin/rm` or `/bin/rm`. `which rm` prints `$PREFIX/bin/rm`. On the reported phone that path is `/data/data/com.termux/files/usr/bin/rm`. `$PREFIX` is `/data/data/com.termux/files/usr` unless `PREFIX` is another directory matching `/data/*/com.termux/files/usr`. This login owns that directory. Setup **MUST** run as this login. It **MUST NOT** call `sudo`. It **MUST NOT** stop with `That needs an admin login`. It **MUST NOT** move `/usr/bin/rm` or `/bin/rm`.

Detect Termux when `TERMUX_VERSION` is set, or `PREFIX` matches `/data/*/com.termux/files/usr`, or `uname -a` contains `Android`, and `$PREFIX/bin` is a directory. The default `PREFIX` when `TERMUX_VERSION` is set and `PREFIX` is empty is `/data/data/com.termux/files/usr`. Tests pass `SRM_TERMUX_PREFIX=/tmp/safe-rm-swap.*` and do not set `TERMUX_VERSION`. A value outside that scratch directory is not Termux. Setup then stays on the Linux admin rule.

| Path | Before swapped | After swapped |
|------|----------------|---------------|
| `$PREFIX/bin/rm` | The Termux `rm`. A regular file, or a symlink whose target name is `coreutils`, `toybox`, or `busybox`. `which rm` prints this path | Symlink to `$PREFIX/bin/safe-rm`. This is the guard |
| `$PREFIX/bin/origin-rm` | Absent | The moved regular file, or a small program that runs `coreutils rm`, `toybox rm`, or `busybox rm`. **This is the remover.** It is not that symlink renamed |
| `$PREFIX/bin/safe-rm` | Absent | This program, mode `0755` |
| `/usr/bin/rm`, `/bin/rm` | Not the Termux `rm` | Stay untouched |

A symlink to `coreutils`, `toybox`, or `busybox` **MUST NOT** be renamed to `origin-rm`. Those programs choose the applet from the file name, so a file named `origin-rm` would not remove anything. Write `origin-rm` so it runs that program's `rm`, then point `$PREFIX/bin/rm` at this program. `restore` puts that symlink back and removes `$PREFIX/bin/origin-rm` and `$PREFIX/bin/safe-rm`.

A missing `$PREFIX/bin/rm` moves nothing. A second setup finds `origin-rm` already there, does not move it again, and replaces `$PREFIX/bin/safe-rm` when its bytes are not this program. A later `self-install` or `self-update` on Termux runs that setup. When `origin-rm` is already there it does not move it again and replaces `$PREFIX/bin/safe-rm` when its bytes are not the placed file. When `origin-rm` is absent, that place performs the first move. It does not call `sudo` and it does not write `/usr/bin/safe-rm`. Git Bash and Windows cmd do not run this Termux measure. Measure 1 still runs on those hosts (§2.0.5). Proof: `TP-SRM-30`.

### 2.0.4 Termux blacklist: `$PREFIX` stands for `/usr`

On Termux the Linux blacklist in §2.2 has the same meaning under `$PREFIX`. `$PREFIX` is the directory from §2.0.3 (`/data/data/com.termux/files/usr` on the reported phone). `rm -rf $PREFIX/var --dry-run` **MUST** refuse. With the default `PREFIX` that path is `/data/data/com.termux/files/usr/var`. Removing it is the same kind of remove as removing `/var`.

| Linux path | Termux path | Scope |
|------------|-------------|--------|
| `/usr` | `$PREFIX` | That directory only |
| `/usr/bin` and anything inside it | `$PREFIX/bin` and anything inside it | The tree. Termux also keeps the programs Linux keeps in `/bin` in this directory |
| `/bin` | `$PREFIX/bin` | Covered by the row above |
| `/sbin` | `$PREFIX/sbin` | That directory only. A name inside `$PREFIX/sbin` stays allowed, the same way a name inside `/sbin` stays allowed |
| `/etc` | `$PREFIX/etc` | That directory only |
| `/var` | `$PREFIX/var` | That directory only. A folder inside it, such as `$PREFIX/var/log`, stays allowed |
| `/lib` | `$PREFIX/lib` | That directory only |
| `/lib64` | `$PREFIX/lib64` | That directory only |
| `/opt` | `$PREFIX/opt` | That directory only |
| `/boot` | `$PREFIX/boot` | That directory only |
| `/root` | The login home | Already refused as the login home. There is no second prefix path |
| `/`, `/dev`, `/proc`, `/sys` | Those same Linux paths | Unchanged |

These paths stay allowed, because the Linux blacklist does not name them: `$PREFIX/share`, `$PREFIX/include`, `$PREFIX/tmp`, `$PREFIX/libexec`, and a folder strictly inside `$PREFIX/var`.

The inside-home allowance does not lift this list. `DENY-USR-BIN` and `DENY-HOST` stay refused when the path is also inside a home. Detection is the same rule as §2.0.3, including `SRM_TERMUX_PREFIX=/tmp/safe-rm-swap.*` for tests. A value outside that scratch directory does not apply this list. On a Linux host the `/usr`, `/var`, and `/usr/bin` rows stay in force with or without that test variable. Proof: `TP-SRM-31`.

### 2.0.5 Two layers, so the original remover is not the `rm` that runs

The name people type, and the absolute system path on a host that allows it, must both be this guard. The original remover is saved once per layer under the prefix name `origin-rm`, in the same directory as that layer's `rm`. Setup **MUST NOT** also create a suffix file named `rm-original`.

Setup runs the two measures in this order. Measure 1 always finishes before measure 2 starts.

| Order | Layer | Where | Who | `sudo` |
|-------|--------|--------|-----|--------|
| 1 | Home guard | `${HOME}/.local/bin/rm` → `safe-rm`, and `${HOME}/.local/bin/origin-rm` | This login, on every host | **MUST NOT** call `sudo` |
| 2 | System guard | Linux: `/usr/bin/rm` and `/bin/rm`. Termux: `$PREFIX/bin/rm` only | Linux: this login, through `sudo` when not already root. Termux: this login | Linux only, and only for this measure. macOS, Termux, Git Bash, and Windows cmd **MUST NOT** call `sudo` |

macOS does not get measure 2. `/bin` is on the sealed system volume. A root copy that creates a new name there fails with `Operation not permitted`. That was reported on macOS 15.3, where `which rm` is `/bin/rm`. Git Bash and Windows cmd do not get measure 2 either. Measure 1 still runs on those hosts.

#### Whose home

Measure 1 writes the home of the login who invoked setup, before any escalation. When this process is already root and `SUDO_USER` names an account, that account's home from the password database is the home. It is not root's home. The measure-2 child **MUST NOT** write that home and **MUST NOT** edit shell startup files.

#### Measure 1 — `${HOME}/.local/bin`

| Path | Before | After |
|------|--------|-------|
| `${HOME}/.local/bin/safe-rm` | Absent, or an older copy | This program, mode `0700` |
| `${HOME}/.local/bin/rm` | Absent | Symlink to `safe-rm` in the same directory. This is the home guard |
| `${HOME}/.local/bin/origin-rm` | Absent | The remover for this layer |

Create the directory when it is missing. When `origin-rm` is already present, leave it. When `safe-rm` is already present and its bytes differ, replace it. When `rm` already exists and is not a symlink to that `safe-rm`, stop. Write nothing further in that directory, and do not start measure 2.

Save `origin-rm` before any system path named `rm` is replaced:

- On macOS (`uname -s` is `Darwin`), `${HOME}/.local/bin/origin-rm` is a program that execs `/bin/rm` with the same arguments. `/bin/rm` is never replaced, so that exec is Apple's remover.
- On a host where measure 2 will replace `/bin/rm` or `/usr/bin/rm`, `${HOME}/.local/bin/origin-rm` is a copy of that original regular file, taken before the move. It **MUST NOT** be a script that execs `/bin/rm` or `/usr/bin/rm`. After the move those paths are the guard, and a script that called them would run this program again.
- When that system `rm` is a symlink to BusyBox, or on Termux a symlink whose target name is `coreutils`, `toybox`, or `busybox`, the home `origin-rm` is a program that runs that applet's `rm`. It is not that symlink renamed.

On the reported Mac, `PATH` lists `${HOME}/.local/bin`, then the pyenv shims, then `/opt/homebrew/bin`, then `/bin`, then `/usr/local/bin`. The home guard has to be `${HOME}/.local/bin/rm` because that directory is ahead of `/bin`. A guard placed only in `/usr/local/bin` is behind `/bin` on that `PATH` and is not the `rm` the shell runs. Setup **MUST NOT** write the guard into the pyenv shims directory or into `/opt/homebrew/bin`.

Measure 1 then runs **path-ensure** and **profile-ensure** in `requirement-shell-cli-self-install.md` §2.7. When this process `PATH` has `/bin` before `/usr/local/bin`, the block later shells source is `${HOME}/.local/bin` first and `/usr/local/bin` next, so `/usr/local/bin` is ahead of `/usr/bin` and `/bin`. The home guard stays `${HOME}/.local/bin/rm`. Setup does not install that guard as `/usr/local/bin/rm`. The block is written on `.bashrc`, `.zshrc`, `.zshenv`, `.profile`, and Fish. Profile-ensure creates a missing `.profile` that sources `.bashrc`. The PATH line stays outside that sample. The measure-2 child does not run either edit. Ship unit `1.0.12` still writes only the user-bin line on `.bashrc`, `.zshenv`, and Fish.

#### Measure 2 — system `rm`

| Host | What setup does |
|------|-----------------|
| Linux, and not Termux | When `id -u` is `0`, this process moves `/usr/bin/rm` and `/bin/rm` to `origin-rm` and points `rm` at `safe-rm`, per §2.0.1 and §2.0.2. When `id -u` is not `0`, setup re-execs this program through `sudo` for measure 2 only. The child is root. The child runs measure 2 and **MUST NOT** call `sudo` again |
| Termux | This login swaps `$PREFIX/bin` per §2.0.3. `/usr/bin/rm` and `/bin/rm` stay. No `sudo` |
| macOS | Stop after measure 1. `/bin/rm` and `/usr/bin/rm` stay Apple's `rm`. No `sudo` |
| Git Bash, Windows cmd | Stop after measure 1. No system path is moved. No `sudo` |

The Linux escalation is `sudo` on this program, limited to measure 2. It is not an interactive shell and it is not `sudo curl | sh`. The program **MUST NOT** read a password and **MUST NOT** put a password on the command line. `sudo` may prompt on the terminal itself. When `sudo` is missing, the operator declines, or `sudo` returns non-zero, measure 1 stays, setup says through `out_*` that `/usr/bin/rm` and `/bin/rm` were not moved, and setup exits non-zero. A later setup retries measure 2. A retry that finds `origin-rm` already present does not move it again.

The system `safe-rm` is mode `0755`. Its bytes are `${HOME}/.local/bin/safe-rm` when that file exists. A second setup whose invoker is not root still uses the same `sudo` re-exec to replace those bytes when they differ, because this login cannot write `/usr/bin` or `/bin`. When the bytes already match, the child changes nothing.

The numbered steps under "Protected rm" below are this measure. They are idempotent.

#### Real delete

When `--dry-run` is off and every path is allowed, exec one remover:

1. On Termux, `$PREFIX/bin/origin-rm`.
2. Otherwise `/usr/bin/origin-rm` when that file is executable, else `/bin/origin-rm` when that file is executable.
3. Otherwise `${HOME}/.local/bin/origin-rm`.

Pass every forwarded switch, in order, then `--`, then every allowed path. One command is one exec. **MUST NOT** exec `/usr/bin/rm`, `/bin/rm`, `$PREFIX/bin/rm`, or `${HOME}/.local/bin/rm`. On macOS the exec of Apple's `rm` happens inside `${HOME}/.local/bin/origin-rm`, not inside the guard.

#### `restore`

`restore` undoes measure 2 first, then measure 1.

- Linux system restore uses the same actor and the same `sudo` rule as measure 2. It puts `origin-rm` back as `rm` and removes that directory's `safe-rm`. When `sudo` fails, `${HOME}/.local/bin/rm` and `${HOME}/.local/bin/origin-rm` stay, and `restore` exits non-zero.
- Termux restore is this login, `$PREFIX/bin` only, with no `sudo`.
- macOS, Git Bash, and Windows cmd have no system paths to put back.
- Measure 1 restore, as this login and with no `sudo`, removes `${HOME}/.local/bin/rm` and `${HOME}/.local/bin/origin-rm`. It leaves `${HOME}/.local/bin/safe-rm`. `self-uninstall` owns that file.

#### `reset`

`reset` is not `restore`. The saved file stays named `origin-rm`. There is no file named `original-rm`.

`reset` checks that `origin-rm` already exists in the system directory. When it does, `reset` replaces `rm` with a symlink whose target is `origin-rm` (`/bin/rm` points at `/bin/origin-rm`, and the same for `/usr/bin` and, on Termux, `$PREFIX/bin`). It does not move `origin-rm`, and it does not remove `safe-rm`. When `origin-rm` is absent, `reset` does not create a link and does not change `rm`.

- Linux uses the same actor and the same `sudo` re-exec as measure 2. The child is root. When `sudo` fails, `/usr/bin/rm` and `/bin/rm` stay, and `reset` exits non-zero.
- Termux reset is this login, `$PREFIX/bin` only, with no `sudo`.
- macOS, Git Bash, and Windows cmd do not replace `/bin/rm`. `reset` changes nothing there and does not call `sudo`.
- `reset` does not change `${HOME}/.local/bin/rm`. A later `setup` points the system `rm` back at `safe-rm` when `origin-rm` is still there.

Shell startup lines stay until uninstall. Uninstall removes them only when `${HOME}/.local/bin` is empty.

#### Proof

`TP-SRM-33` is measure 1 with `HOME` inside `/tmp/safe-rm-swap.*`, as ship unit `1.0.11` implements it. Profile-ensure creates a missing `.profile` that sources `.bashrc` and leaves an existing body. Path-ensure writes the one-directory user-bin line in `.bashrc` once. A second run does not append that line again. The fixture is not executed. `sudo` is not called.

`TP-SRM-35` is the §2.7 PATH block from self-install `1.2.1`. `HOME` is inside `/tmp/safe-rm-swap.*`. When `PATH` has `/bin` before `/usr/local/bin`, `.bashrc`, `.zshrc`, `.zshenv`, and `.profile` each gain `export PATH="${HOME}/.local/bin:/usr/local/bin:$PATH"` once. Fish gains `set -gx PATH ${HOME}/.local/bin /usr/local/bin $PATH` once. `${HOME}/.local/bin` stays ahead of `/usr/local/bin`, and that `/usr/local/bin` is ahead of `/usr/bin`. When `/usr/local/bin` is already ahead of `/bin`, the block is only the user-bin line. An existing `.profile` body, including a marker, stays, and the profile-ensure sample does not contain the PATH line. A second run does not append again. The fixture is not executed. `sudo` is not called. Status: **TODO**. Ship unit `1.0.12` does not implement this proof.

`TP-SRM-34` is measure 2 under `/tmp/safe-rm-swap.*` with a sudo stand-in. The test does not run the real `sudo` and does not write the host `/bin` or `/usr/bin`. On the Linux stand-in, measure 1 finishes and the stand-in is then invoked for measure 2 only. On the Darwin stand-in, the stand-in is not invoked and the fixture that stands for `/bin/rm` stays. A BusyBox symlink is not renamed. Nothing in the fixture is executed.

Ship unit `1.0.11` implements the two-layer swap in this section. Ship unit `1.0.12` keeps that swap and sets the remove-check scratch directory to mode `0700` (`TP-SRM-36`). §2.6 records that the §2.7 PATH block added in `1.2.12` is not in that ship unit yet.

### 2.1 Specialized CLI subcommands

| Verb | Privilege | Meaning |
|------|-----------|---------|
| `rm` | The person who typed `rm`. The check itself does not switch account | Check every operand path. Remove only when every path is allowed and `--dry-run` is off, by exec of the remover in §2.0.5 |
| `restore` | This login for the home layer. For the system layer: the same `sudo` re-exec as measure 2 on Linux; this login on Termux for `$PREFIX/bin` only. No system restore on macOS, Git Bash, or Windows cmd | Undo measure 2, then remove `${HOME}/.local/bin/rm` and `${HOME}/.local/bin/origin-rm`. The 2023 token `-restore` is the same verb when this program is the `rm` people type |
| `reset` | The same `sudo` re-exec as measure 2 on Linux. This login on Termux for `$PREFIX/bin` only. No system reset on macOS, Git Bash, or Windows cmd | When `origin-rm` exists, point `rm` at it and leave `origin-rm` and `safe-rm`. When it is absent, change nothing |
| protected-rm setup | This login for measure 1. Measure 2 per §2.0.5 and `requirement-actor-role-subject.md` | Home guard first. Then the system swap on Linux and Termux. macOS stops after the home guard |

Interactive empty argv opens the numbered menu. It is not `rm`. A pipe, quiet, or json run with no arguments stays install-ensure of this CLI, then runs §2.0.5. Measure 1 runs as this login. On Linux, measure 2 uses the internal `sudo` re-exec when this login is not root. The system guard's bytes are the home file from measure 1 when that file exists. When `origin-rm` is absent, measure 2 performs the first move. When it is already present, measure 2 does not move it again. It is not a raw `rm`.

Sample: `safe-rm restore`  
Sample: `safe-rm reset`  
Sample: `safe-rm rm --dry-run <path>`  
Sample, when this program is the `rm` people type:

```
cd ~/
mkdir test
rm -rf test
```

`test` is a folder inside the login home. That folder may be removed. The login home is not the operand.

#### 2.1.1 Same switches as the remover

The command named `rm` (the basename of `$0` is `rm`) is the perfect replacement of the remover's command line. People do not type a second `rm` verb. `rm -rf test` is the remove. `safe-rm rm -rf test` is the same remove. `safe-rm` with no command stays the numbered menu or install-ensure. That split is not the command named `rm`.

The remover on this host accepts every switch in `origin-rm --help`, including clustered short switches. This guard accepts those same switches and any later switch the remover accepts. It does not keep a shorter list.

| Flag | Where | Behavior |
|------|--------|----------|
| `--dry-run` | On `rm`, or before or after the `safe-rm rm` verb | This guard's switch. Do not forward it. Do not exec `/usr/bin/origin-rm` or `/bin/origin-rm`. For each path, say whether it exists and whether removal is allowed |
| `--` | On the remove argument list | End of options. Later operands are paths, even when a name starts with `-` |
| Any other switch the remover accepts | On the remove argument list | Forward it unchanged, in the order given. A clustered short switch is one token: `-rf` is `-r` and `-f` together. A value glued with `=` stays on that token (`--interactive=never`, `--preserve-root=all`). The closed examples are `-f`, `--force`, `-i`, `-I`, `--interactive`, `--one-file-system`, `--no-preserve-root`, `--preserve-root`, `-r`, `-R`, `--recursive`, `-d`, `--dir`, `-v`, and `--verbose`. A switch not in that list is still forwarded, except a lifecycle verb switch in the next row |
| Lifecycle verb, or the same word as a switch | On `safe-rm`, before `--`. On the command named `rm`, only the `--` form, and `-restore` | On `safe-rm`, the bare word and the `--` switch are the command, not a path. On the command named `rm`, the `--` switch is the command and the bare word is a path: `rm version` removes a link named `version`, and `rm --version` prints this version. The pairs are `help`/`--help`, `version`/`--version`, `about`/`--about`, `version-check`/`--version-check`, `self-update`/`--self-update`, `self-uninstall`/`--self-uninstall`, `self-install`/`--self-install`, `install`/`--install`, `menu`/`--menu`, `main`/`--main`, `setup`/`--setup`, `restore`/`--restore`, and `rm`/`--rm` (the last pair only when the command name is not already `rm`). The same bare-word split applies to every pair. `-restore` is the 2023 token for `restore` on both command names. A `--` switch removes nothing and does not exec the remover. Do not open the menu unless the command is `menu` or `main`. A `--` switch mixed with a path or a remover switch removes nothing and exits `1` |
| `--help`, `--version` | Same as the lifecycle row | This program's help and version. They are not forwarded. `origin-rm --help` and `origin-rm --version` are the remover's own text |
| `--quiet`, `--json`, `--debug` | On `safe-rm`, or on the remove argument list as that whole token | This guard's switches. Do not forward them. On the command named `rm` they do not open the menu and they do not install |
| `-q` | On a remove argument list with no lifecycle verb | Not stolen as quiet. The remover has no `-q`. Forward the token. Beside a lifecycle verb, `-q` is quiet |

Rules:

1. If any path is refused, remove **no** path, including paths that would have been allowed. Do not exec the remover.
2. `--dry-run` never execs `/usr/bin/origin-rm`, `/bin/origin-rm`, `/usr/bin/rm`, or `/bin/rm`.
3. A prompt flag (`-i` inside a short cluster, or `--interactive` other than `never`) in real mode with no terminal is a fatal error. The command must not wait. A lifecycle verb, including `--help` and `--version`, is handled before that check.
4. No path operands is a fatal error, except a lifecycle `--` switch alone, or `-restore` alone. A bare lifecycle word on the command named `rm` is one path. Nothing is removed for a switch with no path. That command does not exec the remover.
5. On the command named `safe-rm`, a token that is not a command, not that command's `--` switch, not a guard switch, and not a remove switch or path after `rm` still fails via `out_die` and points at `safe-rm help`. A remove switch, including `-rf` and any other remover switch, is not that failure.
6. Product sentences use `out_info`, `out_success`, `out_error`, and `out_die`. The guard does not use `echo` or `printf` for those sentences. `origin-rm --help` and `origin-rm --version` are the remover's own text.
7. Exit `0` when every path is allowed and the remover exits `0` (dry-run exits `0` without calling the remover). Exit with the remover's status when the remover is called and fails. Exit `1` when any path is refused or the invocation is invalid.
8. When the basename of `$0` is `rm`, route the argument list to this remove before the numbered menu and before install-ensure, unless the list is a lifecycle `--` switch or `-restore`. No arguments, and `rm --debug` alone, are this remove (no path), not the menu and not install-ensure. `rm --version` is this program's version. `rm version` is a path named `version`, including a link. `safe-rm version` stays this program's version. `safe-rm` and `safe-rm --debug` stay the menu. The script still enters `app_main`. This is not a basename gate that skips `app_main` for `curl | sh` (`$0` there is the shell).
9. `--force` on a remove with no lifecycle verb is the remover's `--force`. Forward it. Beside a lifecycle verb, `--force` is reinstall force.

### 2.2 Specialized features

#### Refuse classes

Resolve the path first (physical directory, symlink target when the path exists; lexical absolute path when it does not). Then classify:

| Class | Match | Result |
|-------|--------|--------|
| `DENY-DOT` | The operand's final component, after trailing slashes are removed, is `.` or `..`, and every earlier class would allow the resolved directory | Refuse |
| `DENY-EMPTY` | Empty operand | Refuse |
| `DENY-STDIN` | Operand is exactly `-` | Refuse |
| `DENY-LOGIN-HOME` | Operand text is exactly `$HOME`, `${HOME}`, or `~`; or the resolved path is the login home directory itself | Refuse |
| `DENY-ACCOUNT-HOME` | Resolved path is an account home recorded in `/etc/passwd` (sixth field; also `getent passwd` when that list is present), the directory itself | Refuse |
| `DENY-HOME-USER` | Resolved path is exactly `/home` | Refuse |
| `DENY-HOME-ANCESTOR` | Resolved path is a strict ancestor of an account home | Refuse |
| `DENY-USR-BIN` | Resolved path is `/usr/bin` or anything inside `/usr/bin` (a symlink such as `/bin` that lands on `/usr/bin` uses this class). On Termux, also `$PREFIX/bin` or anything inside `$PREFIX/bin` | Refuse |
| `DENY-ROOT` | Resolved path is `/` | Refuse |
| `DENY-HOST` | Resolved path is exactly `/usr`, `/bin`, `/sbin`, `/etc`, `/var`, `/boot`, `/root`, `/lib`, `/lib64`, `/opt`, `/dev`, `/proc`, or `/sys`. On Termux, also exactly `$PREFIX`, `$PREFIX/etc`, `$PREFIX/var`, `$PREFIX/lib`, `$PREFIX/lib64`, `$PREFIX/opt`, `$PREFIX/sbin`, or `$PREFIX/boot` | Refuse |
| `DENY-UNRESOLVED` | The path cannot be resolved | Refuse |
| `ALLOW` | Anything else | May be removed when `--dry-run` is off |

An operand whose final component is `.` or `..` is refused when the resolved directory would otherwise be allowed. Trailing slashes do not change that component, so `./` and `../` are the same refusal. A `..` earlier in the path is not this class: `leaf/../leaf` is the resolved directory `leaf`. When `.` or `..` resolves to a stronger class, that class stays. `$HOME/.` stays the login home. `/etc/..` stays `/`. Naming the directory, as in `rm -rf /tmp/my-folder`, is how that directory is removed. Proof: `TP-SRM-37`.

`rm -rf` of any account home directory is refused, because that path is the whole home. A named folder strictly inside any account home is allowed, including a cache directory. That folder does not, by itself, mean the home is being wiped. The text `$HOME/...`, `${HOME}/...`, and `~/...` is expanded and then classified, so a suffix is a folder inside that home. `/etc/passwd` stores every account's home in the sixth field. Each of those directories, and only the directory itself, is refused. `/home` itself stays refused because it is the parent of the homes. A path strictly inside another account's home is allowed. The reviewed blacklist still refuses `/`, `/usr/bin` and anything inside it, and the named system directories below. On Termux that same blacklist is the §2.0.4 table. `$PREFIX/var` is refused. A folder inside `$PREFIX/var` is allowed. `$PREFIX/share` is allowed.

#### Dry-run report

For each path, human mode says:

- allowed and present: the path exists, the kind (`dir`, `file`, `link`, or `other`), removal is allowed, and nothing was removed
- allowed and absent: the path does not exist, removal would be allowed if it existed, and nothing was removed
- refused: `Refusing to remove <path>`, what that path is, `STOP`, `Do not retry with rm, /bin/rm, or /usr/bin/rm`, and a next step

#### Remove-check scratch directory

The remove check writes its switch list and path list in a directory named `safe-rm-work.` plus a unique suffix, under the cache root (`TMPDIR`, the resolved cache folder). `mktemp` is not installed on every OS. A minimal image may lack it until `apk`, `apt`, or a peer package install. The program **MUST** check that the temp maker exists and can create a directory before it uses `mktemp -d`. When the maker is absent, or `mktemp -d` fails, the scratch directory is a subdirectory of that cache folder. The suffix is an unpredictable token, not a `$$` name.

`mktemp -d` and `mkdir` apply the process umask. A umask that strips the owner execute bit, such as `0177`, leaves mode `0600` (`drw-------`). That directory exists and cannot be searched, so creating a file inside it fails, and removing the directory can fail, which leaves it behind. `chmod` does not apply umask. After the directory is created, the program **MUST** set mode `0700` and confirm the directory is searchable and writable before it writes any file in it. Cleanup **MUST** set mode `0700` again before it removes the directory. On Termux the cache root is often `${HOME}/.cache/cache-${APP_NAME}-$$`, because `/dev/shm` and `/tmp` are not usable. Proof: `TP-SRM-36` (mode `0700` when `mktemp -d` returns `0600`, and under umask `0177`) and `TP-SRM-40` (absent or failing temp maker; the scratch directory is that cache subdirectory and is not left behind).

#### Machine contract

With `--json`, stdout is one object from `out_json`. Stderr carries `out_json_error` when the command is fatal. `message` is the same sentence a person sees.

```json
{"type":"rm","message":"Dry-run finished. Every listed path may be removed. Nothing was removed.","dry_run":"true","removed":"false","ok":"true","results":[{"path":"/tmp/leaf","resolved":"/tmp/leaf","exists":"true","kind":"dir","verdict":"allow","class":"ALLOW","message":"Dry-run: /tmp/leaf exists (dir). Removal is allowed. Nothing was removed."}]}
```

A refused dry-run uses `"ok":"false"`, `"removed":"false"`, `"verdict":"refuse"`, and a `class` from the table above. The fatal `message` starts with `Stopped.`

#### Protected rm (2023 setup, kept)

`rm -rf` on the raw system binary is the danger this product exists to close. These numbered steps are measure 2, after measure 1 in §2.0.5, and they are idempotent. On Linux the disk after measure 2 **MUST** match §2.0.1 After swapped. On Termux it **MUST** match §2.0.3 After swapped, and the steps below apply to `$PREFIX/bin` instead of `/usr/bin` and `/bin`. On macOS measure 2 does not run, §2.0.1 does not apply, and `/bin/rm` stays Apple's binary.

1. Check **both** `/usr/bin/rm` and `/bin/rm`. A directory with no `rm` is skipped. Setup **MUST NOT** stop at `/usr/bin` when `/bin/rm` is the `rm` people type, and **MUST NOT** stop at `/bin` when `/usr/bin/rm` is that file. When the two paths are the same file, one move covers both. When neither path has an `rm` that can be swapped, stop and move nothing.
2. When `rm` in that directory is a regular file and `origin-rm` is absent, move `rm` to `origin-rm`.
3. When `rm` is a symlink to BusyBox, do not rename that symlink to `origin-rm`. BusyBox chooses its applet from the file name, so a file named `origin-rm` would not remove anything. Write `origin-rm` so it runs `busybox rm`, then point `rm` at this program. `restore` puts that BusyBox symlink back and removes that `origin-rm`. On Termux the same rule covers a symlink whose target name is `coreutils`, `toybox`, or `busybox`: `origin-rm` runs that program's `rm`.
4. Copy this program to `safe-rm` in the directory that was swapped, mode `0755`. When that file is absent, this is the first copy. When that file is already present and its bytes differ, replace it with this program. Do not move `origin-rm` to do that. Do not create `rm` in a directory that had no `rm`.
5. Point `rm` at `safe-rm`. If `rm` is missing after the move, or is a symlink that does not name this program, replace that link.

A finished `self-install` and a finished `self-update` run §2.0.5. That includes a pipe, quiet, or json place, an already-installed `self-install`, and a `self-update` that is already the remote version. Measure 1 writes `${HOME}/.local/bin` as this login. Measure 2 then follows the host table in §2.0.5. The system guard's bytes are that home file when it exists, not an older running `$0`. These steps perform the first move when `origin-rm` is absent, and they do not move `origin-rm` again when it is present. On Termux, measure 2 does not write `/usr/bin/safe-rm`. Proof that a finished place runs setup is `TP-SRM-32`. Proof of the two layers is `TP-SRM-33` and `TP-SRM-34`.

The lasting result on Linux is: `/usr/bin/rm` and `/bin/rm` are this guard, and the remover is `/usr/bin/origin-rm` or `/bin/origin-rm`. The home guard is also this program, and its remover is `${HOME}/.local/bin/origin-rm` only when the system `origin-rm` is absent. Setup **MUST NOT** point `/usr/bin/rm` or `/bin/rm` back at `origin-rm`. The 2023 script did that in the step after the move, and the later link to `safe-rm` then never ran. That order is a defect. Do not copy it.

`restore` and `-restore` follow §2.0.5. On the system layer, when `origin-rm` exists, remove the `rm` symlink, move `origin-rm` back to `rm`, and remove `safe-rm`. Say that the original binary is restored, through `out_*`.

`reset` and `--reset` follow §2.0.5. On the system layer, when `origin-rm` exists, replace `rm` with a symlink to `origin-rm`. Leave `origin-rm` and `safe-rm`. When `origin-rm` is absent, change nothing. Setup still must not point `rm` at `origin-rm`. A later setup points that symlink back at `safe-rm`.

On Termux, measure 2 runs as this login against `$PREFIX/bin/rm` and does not call `sudo`. On macOS, Git Bash, and Windows cmd, measure 2 does not run and does not call `sudo`. Measure 1 still runs. The guard still refuses a home directory when the program is invoked by name.

#### Real remove

When `--dry-run` is off and every path is allowed, exec the remover from §2.0.5 once. Pass every forwarded switch, in order, then `--`, then every allowed path. One command is one exec, so a switch whose meaning depends on the whole operand list (such as `-I`) matches the remover. **MUST NOT** exec the remover for a refused path. **MUST NOT** exec it once per path.

When that exec exits 0, the success line names the caller and each path that was forwarded. The sentence is `Caller <caller> removed <path>.` More than one path is comma-separated in that same sentence. On a terminal the caller and each path are italic (SGR 3). Off a terminal the same words are plain. `--json` puts that plain sentence in `message`. `--quiet` still hides the human line.

The caller is the nearest script path in the parent command. That is the file named by `sh script`, by `bash script`, or by `--rcfile`. Arguments after that script, including the path being removed, are not the caller. `sh -c` names no script file, so the walk continues to the next shell. A file that was sourced, with no path left in the shell's command, is not invented: the label is that shell, such as `-bash`. The walk stops at a program that is not a shell, so a session leader is not reported as the script. Proof: `TP-SRM-39`.

#### Non-goals

- Tests for this verb use `--dry-run`, except `TP-SRM-39`. That proof execs a fixture `origin-rm` under `/tmp/safe-rm-swap.*` that exits 0 and does not unlink. The listed path remains. The host remover is not exec'd. A system directory cannot be removed by the suite.
- The guard does not keep a database of paths.
- Product sentences do not use the 2023 `printf` lines. They use `out_*`.

### 2.3 Specialized project help items

`safe-rm help` keeps the Type 0 rows and adds:

| Row | Text that must appear |
|-----|------------------------|
| `rm` | Check each path. Remove only when every path is allowed |
| `rm -rf` | When this program is the `rm` people type, the same switches as `origin-rm`, including `-rf` |
| `rm -- -file` | A name that starts with `-` is a path after `--`. `./-file` is that same path |
| `rm -rf .` | `'.' and '..' are refused. Name the folder itself` |
| `rm --dry-run` | Remove nothing. Say whether each path exists and whether it may be removed |
| finished remove | A finished remove names the caller and each path. On a terminal those names are italic |
| `--dry-run` | The same switch may appear before or after `rm` |
| `restore` | Put `origin-rm` back as `rm` |
| `reset` | When `origin-rm` exists, point `rm` at it. Linux uses root or sudo |
| Stop line | The home directory was refused. Do not retry that path with the raw binary |

### 2.4 Specialized project about items

Human `about` includes:

- `Remove guard:` stating that the guard is on
- `Dry-run:` showing `safe-rm rm --dry-run <path>`

JSON `about` includes `"remove_guard":"on"` and `"dry_run_switch":"--dry-run"`.

### 2.5 Proof

| ID | Proves |
|----|--------|
| `TP-SRM-01` | `sh -n src/safe-rm` |
| `TP-SRM-02` | `version` names `safe-rm` `1.0.0` |
| `TP-SRM-03` | `help` lists `self-install`, `rm`, `--dry-run`, and the do-not-retry line |
| `TP-SRM-04` | `src/safe-rm.sha256` matches the ship unit |
| `TP-SRM-05` | Dry-run of an existing temporary directory is allowed and the file remains |
| `TP-SRM-06` | Dry-run of a missing temporary path is allowed and the path stays absent |
| `TP-SRM-07` | Dry-run of the login home is refused and the home remains |
| `TP-SRM-08` | Dry-run of the text `$HOME`, `${HOME}`, and `~` is refused |
| `TP-SRM-09` | Dry-run of `/home` is refused. A first-level name under `/home` that is not an account home stays refused. A folder strictly inside another account home is allowed |
| `TP-SRM-SWAP-01` | Layout only, under `/tmp/safe-rm-swap.*`. Setup moves that fixture's regular `rm` to `origin-rm` and points `rm` at `safe-rm`. A second setup does not move it again. `restore` puts the file back. The test does not execute `rm` and does not remove a directory. A non-admin `setup` without that fixture moves nothing |
| `TP-SRM-10` | Dry-run of `/usr/bin` and `/usr/bin/sh` is refused and both remain |
| `TP-SRM-11` | Dry-run of `/` is refused and `/` remains |
| `TP-SRM-12` | Dry-run of a folder inside the login home (this project directory and `${HOME}/.cache`) is allowed and the folder remains |
| `TP-SRM-20` | Dry-run of another account home from `/etc/passwd` is refused and that path is not created or removed |
| `TP-SRM-13` | One allowed path plus `/usr/bin` refuses the whole command and the allowed path remains |
| `TP-SRM-14` | `--json` dry-run allow: `dry_run` true, `removed` false, `verdict` allow, `exists` true |
| `TP-SRM-15` | `--json` dry-run refuse: `verdict` refuse, `removed` false, stderr says `STOP` |
| `TP-SRM-16` | `rm --dry-run` with no path exits `1` |
| `TP-SRM-17` | An unknown `safe-rm` command still exits `1` and points at help. A remover switch is not an unknown command |
| `TP-SRM-21` | The command named `rm` accepts `rm -rf --dry-run` of a folder that may be removed. The folder remains. The text is not `Unknown command` |
| `TP-SRM-22` | The command named `rm` accepts another remover switch (`--preserve-root`, `--one-file-system`, `--interactive=never`) with `--dry-run`. The path remains |
| `TP-SRM-23` | The command named `rm` with `rm -rf --dry-run` of the login home is still refused and the home remains |
| `TP-SRM-24` | `safe-rm rm -rf --preserve-root --dry-run` of an allowed folder is allowed and the folder remains |
| `TP-SRM-25` | The command named `rm` with `--debug --dry-run` and no path exits `1`, says no path was given, and does not open the menu |
| `TP-SRM-26` | A second setup, after the fixture guard was replaced with a stub, writes this program back, does not move `origin-rm`, and the command named `rm` accepts `rm -rf --dry-run` of an allowed folder. The folder remains |
| `TP-SRM-27` | `help`/`--help`, `version`/`--version`, and the other lifecycle pairs are one command on `safe-rm`. On the command named `rm`, `--version` prints this program's version and does not remove. A bare word, including a link named `version`, is a path under `--dry-run` and stays in place. A `--` switch and a path together remove nothing |
| `TP-SRM-29` | Two fixture directories under `/tmp/safe-rm-swap.*`. An empty first directory does not stop setup. A regular `rm` in the second directory is moved. A BusyBox symlink in the second directory stays the BusyBox file; `origin-rm` there runs `busybox rm`, and `restore` puts the symlink back. Nothing in the fixture is executed. Neither path present moves nothing |
| `TP-SRM-30` | Termux layout only. `SRM_TERMUX_PREFIX` is `/tmp/safe-rm-swap.*` and stands in for `/data/data/com.termux/files/usr`. Setup moves `$PREFIX/bin/rm` to `$PREFIX/bin/origin-rm` and points `rm` at `safe-rm`. A symlink to `toybox` or `coreutils` is not renamed; `origin-rm` runs that program's `rm`, and `restore` puts the symlink back. An empty `bin` moves nothing and does not say an admin login is required. A prefix outside `/tmp/safe-rm-swap.*` moves nothing. `/usr/bin/rm` stays. Nothing in the fixture is executed |
| `TP-SRM-31` | Termux blacklist only. `SRM_TERMUX_PREFIX` is `/tmp/safe-rm-swap.*`. Dry-run refuses `$PREFIX`, `$PREFIX/bin` and a name inside it, and the exact directories `$PREFIX/etc`, `$PREFIX/var`, `$PREFIX/lib`, `$PREFIX/lib64`, `$PREFIX/opt`, `$PREFIX/sbin`, and `$PREFIX/boot`. Each of those paths remains. Dry-run allows `$PREFIX/share`, `$PREFIX/include`, `$PREFIX/tmp`, `$PREFIX/libexec`, `$PREFIX/var/log`, and a name inside `$PREFIX/sbin`. Those paths remain. The command named `rm` with `rm -rf $PREFIX/var --dry-run` refuses and the directory remains. Without that test variable, the scratch `$PREFIX/var` is allowed and `/var` is still refused. Nothing in the fixture is executed |
| `TP-SRM-32` | Layout only, under `/tmp/safe-rm-swap.*`, with `HOME` set inside that test file and not by `tests/run_dry_run.sh`. `self-install` runs setup: a regular `rm` moves to `origin-rm` and `rm` points at the placed file. A second `self-install` replaces a stub guard and does not move `origin-rm`. An already-current `self-update` does the same with the placed file, not an older `$0`. A newer `self-update` copies that newer file onto the guard. On Termux, `self-install` runs the `$PREFIX/bin` setup and leaves `/usr/bin/rm` in place. Nothing in the fixture is executed |
| `TP-SRM-33` | §2.0.5 measure 1 as ship unit `1.0.11`. `HOME` is inside `/tmp/safe-rm-swap.*`. Profile-ensure creates a missing `.profile` that sources `.bashrc` and leaves an existing body. Path-ensure names `${HOME}/.local/bin` once in `.bashrc`. A second run does not append again. `sudo` is not called. Nothing is executed |
| `TP-SRM-35` | §2.7 PATH block (self-install `1.2.1`). When `PATH` has `/bin` before `/usr/local/bin`, `export PATH="${HOME}/.local/bin:/usr/local/bin:$PATH"` is written once on `.bashrc`, `.zshrc`, `.zshenv`, and `.profile`. Fish gets `set -gx PATH ${HOME}/.local/bin /usr/local/bin $PATH` once. `${HOME}/.local/bin` stays first. `/usr/local/bin` stays ahead of `/usr/bin`. An existing `.profile` body stays. A second run does not append again. Nothing is executed. **TODO** in ship unit `1.0.12` |
| `TP-SRM-36` | Remove-check scratch directory. A `mktemp -d` that returns mode `0600`, and a process umask `0177`, still let a dry-run allow an existing temporary directory. The directory remains. The scratch directory is not left behind. Nothing is executed |
| `TP-SRM-40` | Remove-check scratch directory when the temp maker is absent, and when a maker on `PATH` exits without creating a directory. Dry-run of an allowed path is still allowed. The path remains. Stderr does not say the scratch directory could not be created. The scratch directory is not left behind. Nothing is executed |
| `TP-SRM-37` | From an allowed temporary directory, dry-run of `.`, `..`, and `./` is refused and the directory remains. `./file` and `leaf/../leaf` stay allowed and remain. `leaf/..` is refused. One `.` beside an allowed path removes nothing. JSON `class` is `DENY-DOT`. `rm --dry-run -- -rf` treats `-rf` as a path. `rm --dry-run -rf` with no `--` gives no path. Nothing is executed |
| `TP-SRM-38` | Layout only, under `/tmp/safe-rm-swap.*`. After setup, `reset` points the fixture `rm` at `origin-rm`. `origin-rm` and `safe-rm` stay. A second `reset` leaves that link. A directory with no `origin-rm` is not changed. A non-admin `reset` without that fixture does not change `/usr/bin/rm`. A BusyBox fixture points `rm` at `origin-rm` and leaves the applet. Nothing is executed |
| `TP-SRM-39` | A finished remove names the caller and each path. On a terminal those names are italic. `--json` uses the same sentence with no italic. `--quiet` hides the human line. A refused path does not exec the remover. The fixture `origin-rm` under `/tmp/safe-rm-swap.*` exits 0 and does not unlink. The listed path remains. `/usr/bin/rm` stays |
| `TP-SRM-34` | §2.0.5 measure 2 under `/tmp/safe-rm-swap.*` with a sudo stand-in. The real `sudo` is not run and the host `/bin` and `/usr/bin` are not written. Linux: measure 1 finishes, then the stand-in runs measure 2 only. Darwin: the stand-in is not called and the fixture `/bin/rm` stays. A BusyBox symlink is not renamed. Nothing is executed |
| `TP-SRM-28` | `help` says a local `install` copies this file into `/usr/local/bin/` or `${HOME}/.local/bin/` and does not download |
| `TP-SRM-18` | `about` includes `Remove guard:` |
| `TP-SRM-19` | `--quiet` still prints the refusal |

Runner: `tests/run_dry_run.sh`. Its swap block points `HOME` at `/tmp/safe-rm-place.*` and restores the login `HOME` before later checks. `TP-SRM-32` runs in `tests/test_place_setup.sh`. `TP-SRM-33` and `TP-SRM-34` run in `tests/test_two_layer.sh`. `TP-SRM-35` is TODO and is not in the suite yet. Each of those files sets `HOME` only inside that file.

### 2.6 Implementation Notes (this project)

| Fact | Value |
|------|--------|
| Product | `safe-rm` |
| Ship unit | `src/safe-rm` |
| Companion | `src/safe-rm.sha256` |
| Version | `1.0.16` |
| Prefix | `srm_` |
| Type 0 lifecycle | Kept in full (self-install, self-update, self-uninstall, version, about, help, numbered menu, `out_*`). The 2023 setup is kept as well: `origin-rm`, `rm` → this program, `restore`, `reset` |
| Channel default | `REPO_USER=cloudgen`, `REPO_NAME=safe-rm`, `SCRIPT_RELPATH=src/safe-rm` |
| Dispatcher anchors | Basename `rm` routes to `srm_cmd_rm` before the menu. `safe-rm rm` is the same remove. `--dry-run` is not forwarded |
| Honesty | The two-layer setup is **implemented** in ship unit `1.0.11`. Measure 1 writes `${HOME}/.local/bin` as this login, then measure 2. Linux measure 2 re-execs this program through `sudo` when the invoker is not root (`SRM_SUDO` in tests; the default is `sudo`). macOS, Termux, Git Bash, and Windows cmd do not call `sudo`. macOS does not move `/bin/rm`. The saved original is named `origin-rm`. Profile-ensure creates a missing `.profile` that sources `.bashrc`. Ship unit `1.0.12` writes the one-directory user-bin line on `.bashrc`, `.zshenv`, and Fish. The §2.7 block that puts `/usr/local/bin` next, on `.zshrc` and `.profile` as well, is **not implemented** yet (`TP-SRM-35` TODO). Termux `$PREFIX/bin` still has no `sudo`. Tests pass `SRM_SWAP_ROOT=/tmp/safe-rm-swap.*` or `SRM_TERMUX_PREFIX=/tmp/safe-rm-swap.*` so they never touch the host `/usr/bin` or `/bin`. Dry-run never execs the remover. `TP-SRM-33` and `TP-SRM-34` are in `tests/test_two_layer.sh`. Ship unit `1.0.12` sets the remove-check scratch directory to mode `0700` after `mktemp -d` (`TP-SRM-36`). Ship unit `1.0.13` refuses an operand whose final component is `.` or `..` when that resolved directory would otherwise be allowed (`TP-SRM-37`). Account-home lookup uses `grep -Fxq` and falls back to a read loop when `grep` fails. Ship unit `1.0.14` adds `reset`: when `origin-rm` exists, root or the Linux `sudo` re-exec points the system `rm` at it and leaves `origin-rm` and `safe-rm` (`TP-SRM-38`). Ship unit `1.0.15` names the caller and each path on a finished remove. On a terminal those names are italic. A sourced file with no path in the shell command is reported as that shell. `TP-SRM-39` execs a fixture `origin-rm` under `/tmp/safe-rm-swap.*` that exits 0 and does not unlink. Ship unit `1.0.16` checks the temp maker before `mktemp -d`. When that program is absent or cannot create the directory, the scratch directory is a mode-`0700` subdirectory of the cache folder (`TP-SRM-40`) |

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Resolve the path, then refuse. One refused path cancels the whole command.
- **Intentional:** The 2023 setup stays. The self-management lifecycle and the reviewed blacklist stay with it. They do not replace that setup.
- **Anti-fragile:** `--dry-run` is the way to see the verdict without a remove. A missing system `rm` fails closed.
- **Over-protect:** The dry-run branch returns before `srm_exec_one`. `srm_exec_one` also refuses to run when dry-run is set.

---

## 4. Protection Rule (Sacred)

**Future agents MUST NOT:**

1. Call the system `rm` from the `--dry-run` path.
2. Remove any path after one path in the same command was refused.
3. During setup, leave the raw system `rm` as the command people type, or point `rm` back at `origin-rm` and stop there. `reset` is the only verb that points the system `rm` at `origin-rm`, and only when that file already exists.
4. Point `HOME` at a scratch directory in order to test this command.
5. Add a test that invokes `rm` without `--dry-run`.
6. Print the refusal with `echo` or `printf` instead of `out_*`.
7. Allow an account home directory itself, including the login home.
8. Refuse a named folder strictly inside an account home, such as a cache directory, unless that folder is itself an account home. An operand whose final component is `.` or `..` is not that named folder.
9. Exec `/usr/bin/rm`, `/bin/rm`, `$PREFIX/bin/rm`, or `${HOME}/.local/bin/rm` for the real delete. The real delete execs the remover in §2.0.5. On macOS the guard itself execs `/bin/rm`.
10. Reject a remover switch, including a clustered short switch such as `-rf`, with `safe-rm help` or `Unknown command`.
11. Require a second `rm` verb when the command name is already `rm`.
12. Exec the remover once per path. One allowed command is one exec of every allowed path.
13. Treat the command named `rm` with no arguments, or `rm --debug` alone, as the numbered menu or as install-ensure.
14. Leave a stale `safe-rm` in place after a root place or a later setup when `origin-rm` already exists, so the command people type is an older program that rejects `-rf`.
15. Forward `--help` or `--version` to the remover. On the command named `rm`, route a bare lifecycle word (`version`, `help`, and the other words with no dashes) as this program's command, or route a `--` lifecycle switch as a path.
16. On Termux, allow `$PREFIX`, `$PREFIX/bin` or anything inside it, or the exact directories `$PREFIX/etc`, `$PREFIX/var`, `$PREFIX/lib`, `$PREFIX/lib64`, `$PREFIX/opt`, `$PREFIX/sbin`, and `$PREFIX/boot`. Refuse a folder strictly inside `$PREFIX/var`, or refuse `$PREFIX/share`, `$PREFIX/include`, `$PREFIX/tmp`, or `$PREFIX/libexec`, unless that folder is itself an account home.
17. Finish a `self-install` or `self-update` without measure 1, so the command people type stays the original remover.
18. Skip measure 1 and swap only the system `rm`, or run measure 2 on macOS.
19. Call `sudo` for measure 1, or call `sudo` on macOS, Termux, Git Bash, or Windows cmd. Let the measure-2 child call `sudo` again.
20. Save the original under a second name `rm-original`, or make the Linux home `origin-rm` a script that execs `/bin/rm` or `/usr/bin/rm` after those paths are the guard.
21. Allow an operand whose final component is `.` or `..` when the resolved directory would otherwise be allowed. The operator names the directory.
22. On `reset`, create an `rm` link when `origin-rm` is absent, move or remove `origin-rm`, or remove `safe-rm`. A login that is not root does not rewrite `/usr/bin/rm` or `/bin/rm`.

**Violating this rule is a critical remove-guard regression.**

---

## Under command line for normal user only

This product may run on Termux, Git Bash, Windows cmd, or the same class (this login only).

**This requirement:** Measure 1 runs as this login on every host, including Termux, Git Bash, Windows cmd, and macOS, and does not call `sudo`. On Termux, measure 2 swaps `$PREFIX/bin/rm` (`/data/data/com.termux/files/usr/bin/rm` on the reported phone) as this login and does not call `sudo`. `/usr/bin/rm` and `/bin/rm` stay untouched there. The home-directory refusal still applies. The §2.0.4 blacklist still applies. On Git Bash and Windows cmd, measure 2 does not run and does not call `sudo`. On macOS, measure 2 does not run and does not call `sudo`. On Linux, measure 2 is the one internal `sudo` re-exec. It moves the system `rm` to `origin-rm` and points `rm` at this program. It is not a general admin shell, and it does not create a dedicated account.

| MUST | MUST NOT |
|------|----------|
| On Termux, move `$PREFIX/bin/rm` as this login and leave `/usr/bin/rm` and `/bin/rm` untouched | Call `sudo` on Termux, macOS, Git Bash, or Windows cmd |
| On Termux, refuse `$PREFIX/var` and the other §2.0.4 rows | Allow `$PREFIX/var`, or refuse a folder inside `$PREFIX/var` |
| Run measure 1 on Git Bash, Windows cmd, and macOS | Run measure 2, or call `sudo`, on those hosts |
| Keep `--dry-run` as a local check | Wrap `apt` or `pkg` from this verb |

---

## 5. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Type 0 verbs and the pointer at this file |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_*` printer |
| `docs/requirements/index.md` | Registry |
| `src/safe-rm` | Implementation |
| `tests/run_dry_run.sh` | `TP-SRM-*` |

---

## 6. Revision history

| Date | Change |
|------|--------|
| 2026-09-27 | 1.0.0: guarded `rm` and `--dry-run`. The ship text said this program does not replace `/bin/rm` or `/usr/bin/rm`. |
| 2026-09-27 | 1.1.0: restore the 2023 intention. Setup swaps the system `rm` to this guard and keeps the original binary as `origin-rm`. `restore` puts it back. Any account home directory is refused. A folder inside any account home is allowed. Selfmanaged lifecycle and `out_*` stay. Ship unit is still the gap named in Implementation Notes. |
| 2026-09-27 | 1.1.1: §2.0. The remover is `/usr/bin/origin-rm` or `/bin/origin-rm`. `/usr/bin/rm` and `/bin/rm` after setup are this guard and are not exec'd for the delete. |
| 2026-09-27 | 1.1.2: §2.0.1 table of each path before the swap and after the swap. `restore` reverses that table. |
| 2026-09-27 | 1.2.0: the command named `rm` is the remover's command line. `-rf` and every other remover switch are accepted and forwarded in one exec. `rm -rf` of a folder inside the login home may be removed. |
| 2026-09-27 | 1.2.1: when `origin-rm` is already present, a later setup and a root place replace the guard file with this program. They do not move `origin-rm` again. A non-root place does not write that guard. |
| 2026-09-27 | 1.2.2: each lifecycle verb is also its `--` switch. On the command named `rm`, `version` and `--version` are this program's version, not a file and not the remover's text. |
| 2026-09-27 | 1.2.3: on the command named `rm`, a bare lifecycle word is a path again. `rm version` removes a link named `version`. `rm --version` stays this program's version. The same split applies to every other command word. `safe-rm version` stays the command. |
| 2026-09-27 | 1.2.4: setup checks `/usr/bin/rm` and `/bin/rm`. A missing `rm` in one directory does not cancel the other. A BusyBox symlink is not renamed to `origin-rm`; that file runs `busybox rm`. |
| 2026-09-27 | 1.2.5: Alpine is the different-path host. `/bin/rm` is BusyBox and `/usr/bin/rm` may be absent. §2.0.2 is that before/after table. Setup must not stop at `/usr/bin` on that host. |
| 2026-09-27 | 1.2.6: Termux `which rm` is `$PREFIX/bin/rm` (`/data/data/com.termux/files/usr/bin/rm`). §2.0.3 is that before/after table. This login runs setup there. Setup does not call `sudo` and does not require an admin login. |
| 2026-09-27 | 1.2.7: Termux blacklist §2.0.4. `$PREFIX/var` and the other prefix matches of the Linux system directories are refused. A folder inside `$PREFIX/var` stays allowed. `$PREFIX/share` stays allowed. |
| 2026-09-28 | 1.2.8: a finished `self-install` or `self-update` runs setup when this login may. The guard bytes are the placed file. A non-root Linux place does not run setup. |
| 2026-09-29 | 1.2.9: §2.0.5. Two layers. Measure 1 is `${HOME}/.local/bin` as this login, with the original saved as `origin-rm`. Measure 2, except on macOS, moves `/usr/bin/rm` and `/bin/rm` to `origin-rm` and points `rm` at this program. On Linux that measure re-execs this program through `sudo` when the invoker is not root. macOS, Termux, Git Bash, and Windows cmd do not call `sudo`. macOS does not move `/bin/rm`. Ship unit `1.0.10` does not implement this section yet. |
| 2026-09-29 | 1.2.10: Measure 1 names **profile-ensure** and **path-ensure** (`requirement-shell-cli-self-install.md` §2.7). A missing `.profile` sources `.bashrc` and is not given the PATH line. That line stays on `.bashrc` and `.zshenv`. |
| 2026-09-29 | 1.2.11: Ship unit `1.0.11` implements §2.0.5 and §2.7 as of that date. `TP-SRM-33` and `TP-SRM-34` are in the suite. |
| 2026-09-29 | 1.2.12: When `/bin` is ahead of `/usr/local/bin`, path-ensure writes `${HOME}/.local/bin` then `/usr/local/bin` on `.bashrc`, `.zshrc`, `.zshenv`, `.profile`, and Fish. `/usr/local/bin` is then ahead of `/usr/bin`. Ship unit `1.0.11` does not implement this block yet. `TP-SRM-35` is TODO. |
| 2026-09-30 | 1.2.13: The remove-check scratch directory is mode `0700` after `mktemp -d`. A umask that strips the owner execute bit, or a `mktemp` that returns `0600`, must not leave `safe-rm-work.*` unsearchable. Cleanup sets `0700` before it removes that directory. `TP-SRM-36`. Ship unit `1.0.12`. |
| 2026-09-30 | 1.2.14: `DENY-DOT`. An operand whose final component is `.` or `..` is refused when the resolved directory would otherwise be allowed. A stronger class stays. A `..` in the middle is not this class. `TP-SRM-37`. Ship unit `1.0.13`. |
| 2026-09-30 | 1.2.15: `reset`. When `origin-rm` exists, root or the Linux `sudo` re-exec replaces the system `rm` with a symlink to `origin-rm`. `origin-rm` and `safe-rm` stay. A missing `origin-rm` changes nothing. Termux does this as this login on `$PREFIX/bin`. macOS does not call `sudo`. `TP-SRM-38`. Ship unit `1.0.14`. |
| 2026-09-30 | 1.2.16: A finished remove names the caller and each path. On a terminal those names are italic. A sourced file with no path in the shell command is the shell, such as `-bash`. `TP-SRM-39`. Ship unit `1.0.15`. |
| 2026-09-30 | 1.2.17: The temp maker is not on every OS. The remove check uses `mktemp -d` only when that program exists and can create a directory. Otherwise the scratch directory is a subdirectory of the cache folder. A directory at `0600` cannot be searched. Mode `0700` is set before any file, and again before cleanup. `TP-SRM-40`. Ship unit `1.0.16`. |

**Last Updated**: 2026-09-30
**Owner**: safe-rm project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
