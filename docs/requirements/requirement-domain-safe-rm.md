**file**: docs/requirements/requirement-domain-safe-rm.md
**id**: RQ-DOMAIN-SAFE-RM
**Status**: Active (Version 1.2.5)
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **current domain SSOT** for **safe-rm**. The 2023 program already moved the system `rm` aside to `origin-rm` and made `rm` run the guard, because `rm -rf` is too dangerous to leave as the raw binary. Bootstrap from selfmanaged keeps that setup and adds the selfmanaged lifecycle (self-install, self-update, self-uninstall, version, about, help, the numbered menu). The improvement over 2023 is a reviewed blacklist and product sentences through `out_*`.

It also exists because an agent once ran a recursive remove of the login home after a command-scoped `HOME=` prefix. The prefix did not apply to the later remove, and the login home was the target.

**Scope:** the protected-`rm` setup (`origin-rm`, the `rm` link, `restore`), the command named `rm` (the same switches as `origin-rm`, including `-rf`), the `safe-rm rm` verb, `--dry-run`, refuse classes, messages that tell the operator to stop, and the help/about rows for that guard.
**Out of scope:** Checksum and storage (peer shell requirements). Any remove that the tests perform without `--dry-run`. Dropping the 2023 swap because the selfmanaged shell usually avoids `sudo`.

### 1.1 Human-facing

**In one sentence:** After setup, the remover is `/usr/bin/origin-rm` or `/bin/origin-rm` (the original binary that was moved); `/usr/bin/rm` and `/bin/rm` are this guard and accept the same switches as that remover, including `-rf`; `rm -rf` of any account home is refused, a folder inside any account home may be removed, and `--dry-run` does not call the remover.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person or agent who types `rm` | `cd ~/` then `mkdir test` then `rm -rf test` |
| The other role | The remover: `/usr/bin/origin-rm` or `/bin/origin-rm`. Called only after every path is allowed and `--dry-run` is off | Not used by the dry-run suite |
| Not this file | Self-update checksum and the `out_*` printer | Peer shell requirements |

| Includes | Excludes |
|----------|----------|
| Swap of system `rm` to this guard, `restore`, refuse rules, dry-run report | Leaving the raw `rm` binary as the command people type |
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

---

## 2. Core Rules / Requirements (Mandatory)

### 2.0 What "rm" means in this file

Two different files. Do not mix them.

| Word in this file | Path | What it is |
|-------------------|------|------------|
| **the remover** | `/usr/bin/origin-rm`, or `/bin/origin-rm` when the original binary was moved there | The original `rm` binary after the swap. **This is what deletes.** When this requirement says the real remove, it means one of these two paths. |
| **the command people type** | `/usr/bin/rm` and `/bin/rm` after setup | A symlink to this program. It checks the path. It does not delete. |

1. The real delete **MUST** exec `/usr/bin/origin-rm` when that file is executable. Otherwise it **MUST** exec `/bin/origin-rm` when that file is executable.  
2. The real delete **MUST NOT** exec `/usr/bin/rm` or `/bin/rm`. After setup those paths are this program, and calling them would run the guard again.  
3. When `/bin/rm` and `/usr/bin/rm` were the same file, one `origin-rm` exists. Calling either origin path that names that file is the same remover.  
4. `--dry-run` **MUST NOT** exec `/usr/bin/origin-rm` or `/bin/origin-rm`.

### 2.0.1 Before swapped and after swapped

Setup **MUST** turn the Before column into the After column. `restore` **MUST** turn After back into Before. When `/bin` and `/usr/bin` are the same directory, `/bin/rm` and `/usr/bin/rm` are one file, and one `origin-rm` covers both.

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

### 2.1 Specialized CLI subcommands

| Verb | Privilege | Meaning |
|------|-----------|---------|
| `rm` | The person who typed `rm`. The check itself does not switch account | Check every operand path. Remove only when every path is allowed and `--dry-run` is off, by exec of `/usr/bin/origin-rm` or `/bin/origin-rm` (§2.0) |
| `restore` | Admin privilege on a Linux host that owns the system `rm`. Unused on Termux, Git Bash, and Windows cmd | Put `origin-rm` back as `rm` and remove the `safe-rm` link. The 2023 token `-restore` is the same verb when this program is the `rm` people type |
| protected-rm setup | Admin login only. Who: `requirement-actor-role-subject.md`. Runs when `rm` is still the raw binary, and again when the guard file is already there | Check `/usr/bin/origin-rm` and `/bin/origin-rm`. If the original binary is already there, do not move `rm` again, and replace the existing `safe-rm` with this program. Otherwise move `rm` to that path and point `rm` at this program |

Interactive empty argv opens the numbered menu. It is not `rm`. A pipe, quiet, or json run with no arguments stays install-ensure of this CLI. It does not perform the first move of `rm`. When that place runs as root and `origin-rm` is already present, it replaces the existing guard with this program, so the `rm` people type runs these bytes. It is not a raw `rm`.

Sample: `safe-rm restore`  
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
| `DENY-EMPTY` | Empty operand | Refuse |
| `DENY-STDIN` | Operand is exactly `-` | Refuse |
| `DENY-LOGIN-HOME` | Operand text is exactly `$HOME`, `${HOME}`, or `~`; or the resolved path is the login home directory itself | Refuse |
| `DENY-ACCOUNT-HOME` | Resolved path is an account home recorded in `/etc/passwd` (sixth field; also `getent passwd` when that list is present), the directory itself | Refuse |
| `DENY-HOME-USER` | Resolved path is exactly `/home` | Refuse |
| `DENY-HOME-ANCESTOR` | Resolved path is a strict ancestor of an account home | Refuse |
| `DENY-USR-BIN` | Resolved path is `/usr/bin` or anything inside `/usr/bin` (a symlink such as `/bin` that lands on `/usr/bin` uses this class) | Refuse |
| `DENY-ROOT` | Resolved path is `/` | Refuse |
| `DENY-HOST` | Resolved path is exactly `/usr`, `/bin`, `/sbin`, `/etc`, `/var`, `/boot`, `/root`, `/lib`, `/lib64`, `/opt`, `/dev`, `/proc`, or `/sys` | Refuse |
| `DENY-UNRESOLVED` | The path cannot be resolved | Refuse |
| `ALLOW` | Anything else | May be removed when `--dry-run` is off |

`rm -rf` of any account home directory is refused, because that path is the whole home. A named folder strictly inside any account home is allowed, including a cache directory. That folder does not, by itself, mean the home is being wiped. The text `$HOME/...`, `${HOME}/...`, and `~/...` is expanded and then classified, so a suffix is a folder inside that home. `/etc/passwd` stores every account's home in the sixth field. Each of those directories, and only the directory itself, is refused. `/home` itself stays refused because it is the parent of the homes. A path strictly inside another account's home is allowed. The reviewed blacklist still refuses `/`, `/usr/bin` and anything inside it, and the named system directories below.

#### Dry-run report

For each path, human mode says:

- allowed and present: the path exists, the kind (`dir`, `file`, `link`, or `other`), removal is allowed, and nothing was removed
- allowed and absent: the path does not exist, removal would be allowed if it existed, and nothing was removed
- refused: `Refusing to remove <path>`, what that path is, `STOP`, `Do not retry with rm, /bin/rm, or /usr/bin/rm`, and a next step

#### Machine contract

With `--json`, stdout is one object from `out_json`. Stderr carries `out_json_error` when the command is fatal. `message` is the same sentence a person sees.

```json
{"type":"rm","message":"Dry-run finished. Every listed path may be removed. Nothing was removed.","dry_run":"true","removed":"false","ok":"true","results":[{"path":"/tmp/leaf","resolved":"/tmp/leaf","exists":"true","kind":"dir","verdict":"allow","class":"ALLOW","message":"Dry-run: /tmp/leaf exists (dir). Removal is allowed. Nothing was removed."}]}
```

A refused dry-run uses `"ok":"false"`, `"removed":"false"`, `"verdict":"refuse"`, and a `class` from the table above. The fatal `message` starts with `Stopped.`

#### Protected rm (2023 setup, kept)

`rm -rf` on the raw system binary is the danger this product exists to close. Setup does all of the following, and it is idempotent. The disk after a finished setup **MUST** match §2.0.1 After swapped.

1. Check **both** `/usr/bin/rm` and `/bin/rm`. A directory with no `rm` is skipped. Setup **MUST NOT** stop at `/usr/bin` when `/bin/rm` is the `rm` people type, and **MUST NOT** stop at `/bin` when `/usr/bin/rm` is that file. When the two paths are the same file, one move covers both. When neither path has an `rm` that can be swapped, stop and move nothing.
2. When `rm` in that directory is a regular file and `origin-rm` is absent, move `rm` to `origin-rm`.
3. When `rm` is a symlink to BusyBox, do not rename that symlink to `origin-rm`. BusyBox chooses its applet from the file name, so a file named `origin-rm` would not remove anything. Write `origin-rm` so it runs `busybox rm`, then point `rm` at this program. `restore` puts that BusyBox symlink back and removes that `origin-rm`.
4. Copy this program to `safe-rm` in the directory that was swapped, mode `0755`. When that file is absent, this is the first copy. When that file is already present and its bytes differ, replace it with this program. Do not move `origin-rm` to do that. Do not create `rm` in a directory that had no `rm`.
5. Point `rm` at `safe-rm`. If `rm` is missing after the move, or is a symlink that does not name this program, replace that link.

A root `self-install` (and the same place from a pipe, quiet, or json run) does not perform that first move. When `origin-rm` is already present, that place replaces `/usr/bin/safe-rm`, and `/bin/safe-rm` when `/bin` is a different directory, with this program. A non-root place does not write those paths. Termux, Git Bash, and Windows cmd do not replace them and do not call `sudo`.

The lasting result is: `/usr/bin/rm` and `/bin/rm` are this guard, and the remover is `/usr/bin/origin-rm` or `/bin/origin-rm`. Setup **MUST NOT** point `/usr/bin/rm` or `/bin/rm` back at `origin-rm`. The 2023 script did that in the step after the move, and the later link to `safe-rm` then never ran. That order is a defect. Do not copy it.

`restore` and `-restore`: when `origin-rm` exists, remove the `rm` symlink, move `origin-rm` back to `rm`, and remove `safe-rm`. Say that the original binary is restored, through `out_*`.

On Termux, Git Bash, and Windows cmd this setup does not run and does not call `sudo`. The guard still refuses a home directory when the program is invoked by name.

#### Real remove

When `--dry-run` is off and every path is allowed, exec the remover from §2.0 once: `/usr/bin/origin-rm` if that file is executable, otherwise `/bin/origin-rm`. Pass every forwarded switch, in order, then `--`, then every allowed path. One command is one exec, so a switch whose meaning depends on the whole operand list (such as `-I`) matches the remover. **MUST NOT** exec `/usr/bin/rm` or `/bin/rm`. Those paths are this guard after setup. **MUST NOT** exec the remover for a refused path. **MUST NOT** exec it once per path.

#### Non-goals

- Tests for this verb do not run real mode. They use `--dry-run` so a system directory cannot be removed by the suite.
- The guard does not keep a database of paths.
- Product sentences do not use the 2023 `printf` lines. They use `out_*`.

### 2.3 Specialized project help items

`safe-rm help` keeps the Type 0 rows and adds:

| Row | Text that must appear |
|-----|------------------------|
| `rm` | Check each path. Remove only when every path is allowed |
| `rm -rf` | When this program is the `rm` people type, the same switches as `origin-rm`, including `-rf` |
| `rm --dry-run` | Remove nothing. Say whether each path exists and whether it may be removed |
| `--dry-run` | The same switch may appear before or after `rm` |
| `restore` | Put `origin-rm` back as `rm` |
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
| `TP-SRM-28` | `help` says a local `install` copies this file into `/usr/local/bin/` or `${HOME}/.local/bin/` and does not download |
| `TP-SRM-18` | `about` includes `Remove guard:` |
| `TP-SRM-19` | `--quiet` still prints the refusal |

Runner: `tests/run_dry_run.sh`. It does not point `HOME` at a scratch directory.

### 2.6 Implementation Notes (this project)

| Fact | Value |
|------|--------|
| Product | `safe-rm` |
| Ship unit | `src/safe-rm` |
| Companion | `src/safe-rm.sha256` |
| Version | `1.0.7` |
| Prefix | `srm_` |
| Bootstrap origin | `selfmanaged` Type 0 architecture kept in full (self-install, self-update, self-uninstall, version, about, help, numbered menu, `out_*`). The 2023 safe-rm setup is kept as well: `origin-rm`, `rm` → this program, `restore` |
| Channel default | `REPO_USER=cloudgen`, `REPO_NAME=safe-rm`, `SCRIPT_RELPATH=src/safe-rm` |
| Dispatcher anchors | Basename `rm` routes to `srm_cmd_rm` before the menu. `safe-rm rm` is the same remove. `--dry-run` is not forwarded |
| Honesty | **Implemented** for `setup` / `restore`, for replacing an already-swapped guard on a later setup and on a root place, and for remover switches on the command named `rm` (`-rf` and any other switch, one exec of the remover). Tests pass `SRM_SWAP_ROOT=/tmp/safe-rm-swap.*` so they never touch `/usr/bin` or `/bin`. A non-admin setup without that variable refuses and moves nothing. The real delete still execs `/usr/bin/origin-rm` or `/bin/origin-rm` when that file exists (§2.0). Dry-run never execs it. The suite proves switch acceptance with `--dry-run` and does not exec the remover |

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Resolve the path, then refuse. One refused path cancels the whole command.
- **Intentional:** The 2023 setup stays. Specialize adds the selfmanaged lifecycle and the reviewed blacklist. It does not replace that setup.
- **Anti-fragile:** `--dry-run` is the way to see the verdict without a remove. A missing system `rm` fails closed.
- **Over-protect:** The dry-run branch returns before `srm_exec_one`. `srm_exec_one` also refuses to run when dry-run is set.

---

## 4. Protection Rule (Sacred)

**Future agents MUST NOT:**

1. Call the system `rm` from the `--dry-run` path.
2. Remove any path after one path in the same command was refused.
3. Leave the raw system `rm` as the command people type after setup, or point `rm` back at `origin-rm` and stop there.
4. Point `HOME` at a scratch directory in order to test this command.
5. Add a test that invokes `rm` without `--dry-run`.
6. Print the refusal with `echo` or `printf` instead of `out_*`.
7. Allow an account home directory itself, including the login home.
8. Refuse a named folder strictly inside an account home, such as a cache directory, unless that folder is itself an account home.
9. Exec `/usr/bin/rm` or `/bin/rm` for the real delete. The real delete execs `/usr/bin/origin-rm` or `/bin/origin-rm` (§2.0).
10. Reject a remover switch, including a clustered short switch such as `-rf`, with `safe-rm help` or `Unknown command`.
11. Require a second `rm` verb when the command name is already `rm`.
12. Exec the remover once per path. One allowed command is one exec of every allowed path.
13. Treat the command named `rm` with no arguments, or `rm --debug` alone, as the numbered menu or as install-ensure.
14. Leave a stale `safe-rm` in place after a root place or a later setup when `origin-rm` already exists, so the command people type is an older program that rejects `-rf`.
15. Forward `--help` or `--version` to the remover. On the command named `rm`, route a bare lifecycle word (`version`, `help`, and the other words with no dashes) as this program's command, or route a `--` lifecycle switch as a path.

**Violating this rule is a critical remove-guard regression.**

---

## Under command line for normal user only

This product may run on Termux, Git Bash, Windows cmd, or the same class (this login only).

**This requirement:** On Termux, Git Bash, and Windows cmd the protected-rm swap does not run and does not call `sudo`. The home-directory refusal still applies when this program is invoked by name. On a Linux host the swap is the setup: it moves the system `rm` to `origin-rm` and points `rm` at this program. That is the one admin step. It is not a general admin shell, and it does not create a dedicated account.

| MUST | MUST NOT |
|------|----------|
| Refuse any account home directory the same way on this login | Run the swap, or call `sudo`, when Termux, Git Bash, or Windows cmd is detected |
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

**Last Updated**: 2026-09-27
**Owner**: safe-rm project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
