**file**: docs/requirements/requirement-domain-safe-rm.md
**id**: RQ-DOMAIN-SAFE-RM
**Status**: Active (Version 1.0.0)
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **current domain SSOT** for **safe-rm**: a guarded remove on top of the inherited Type 0 self-install CLI. It exists because an agent once ran a recursive remove of the login home after a command-scoped `HOME=` prefix. The prefix did not apply to the later remove, and the login home was the target.

**Scope:** the `rm` verb, `--dry-run`, refuse classes, messages that tell the operator to stop, and the help/about rows for that guard.
**Out of scope:** Type 0 install, checksum, and storage (peer shell requirements). Replacing `/usr/bin/rm` or `/bin/rm`. Any remove that the tests perform without `--dry-run`.

### 1.1 Human-facing

**In one sentence:** `safe-rm rm` checks each path and refuses a login home, anything under `/home`, `/usr/bin`, and other system directories; `--dry-run` only tells you whether the folder exists and whether removal would be allowed.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person or agent who types the command | `safe-rm rm --dry-run /tmp/my-folder` |
| The other role | The system `rm` at `/bin/rm` or `/usr/bin/rm`, called only after every path is allowed and `--dry-run` is off | Not used by the dry-run suite |
| Not this file | Install, self-update, and the `out_*` printer | Peer shell requirements |

| Includes | Excludes |
|----------|----------|
| Refuse rules, dry-run report, stop text | Swapping the system `rm` for this program |
| One JSON object for `rm` when `--json` is set | A second printer beside `out_*` |

| Surface | What you open | What for |
|---------|---------------|----------|
| `safe-rm help` | Command | Remove-guard rows and Type 0 rows |
| `safe-rm rm --dry-run <path>` | Command | Exists, and whether removal is allowed, with nothing removed |
| `src/safe-rm` | Program file | `srm_*` guard |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Ask before deleting | The program reports existence and the verdict and deletes nothing | `safe-rm rm --dry-run <path>` |
| Hit a dangerous path | The program exits non-zero, names the path, and tells you not to retry with `rm` | `safe-rm rm --dry-run <dangerous-path>` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Specialized CLI subcommands

| Verb | Privilege | Meaning |
|------|-----------|---------|
| `rm` | Invoking user. No admin privilege and no dedicated account | Check every operand path. Remove only when every path is allowed and `--dry-run` is off |

Empty argv stays install-ensure. It is not `rm`.

| Flag | Where | Behavior |
|------|--------|----------|
| `--dry-run` | Before `rm` or after `rm` | Do not call the system `rm`. For each path, say whether it exists and whether removal is allowed |
| `--` | After `rm` | End of options. Later operands are paths |
| `-r`, `-R`, `-f`, `-v`, `-i`, `-d`, `-I` and the long forms `--recursive`, `--force`, `--dir`, `--verbose`, `--one-file-system`, `--interactive` | After `rm` | Accepted as system-rm flags. Ignored for the actual remove while `--dry-run` is set |
| `--quiet`, `--json`, `--debug` | Global or after `rm` | Same contracts as the output requirement |

Rules:

1. If any path is refused, remove **no** path, including paths that would have been allowed.
2. `--dry-run` never calls `/bin/rm` or `/usr/bin/rm`.
3. A prompt flag (`-i` or `--interactive` other than `never`) in real mode with no terminal is a fatal error. The command must not wait.
4. No operands is a fatal error. Nothing is removed.
5. Unknown tokens that are not `rm`, a known flag, or a path after `rm` still fail via `out_die` and point at `safe-rm help`.
6. Product sentences use `out_info`, `out_success`, `out_error`, and `out_die`. The guard does not use `echo` or `printf` for those sentences.
7. Exit `0` when every path is allowed (dry-run or a completed real remove). Exit `1` when any path is refused, a path is missing in a way the system `rm` rejects, or the invocation is invalid.

### 2.2 Specialized features

#### Refuse classes

Resolve the path first (physical directory, symlink target when the path exists; lexical absolute path when it does not). Then classify:

| Class | Match | Result |
|-------|--------|--------|
| `DENY-EMPTY` | Empty operand | Refuse |
| `DENY-STDIN` | Operand is exactly `-` | Refuse |
| `DENY-LOGIN-HOME` | Operand text is `$HOME`, `${HOME}`, `~`, or those forms with a suffix; or the resolved path is the login home or anything inside it | Refuse |
| `DENY-HOME-USER` | Resolved path is `/home` or anything inside `/home` | Refuse |
| `DENY-HOME-ANCESTOR` | Resolved path is a strict ancestor of the login home | Refuse |
| `DENY-USR-BIN` | Resolved path is `/usr/bin` or anything inside `/usr/bin` (a symlink such as `/bin` that lands on `/usr/bin` uses this class) | Refuse |
| `DENY-ROOT` | Resolved path is `/` | Refuse |
| `DENY-HOST` | Resolved path is exactly `/usr`, `/bin`, `/sbin`, `/etc`, `/var`, `/boot`, `/root`, `/lib`, `/lib64`, `/opt`, `/dev`, `/proc`, or `/sys` | Refuse |
| `DENY-UNRESOLVED` | The path cannot be resolved | Refuse |
| `ALLOW` | Anything else | May be removed when `--dry-run` is off |

A path inside the login home is refused even when it is not the home directory itself. That covers a recursive remove of the home's children.

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

#### Real remove

When `--dry-run` is off and every path is allowed, call `/bin/rm` or `/usr/bin/rm` if that file is executable and is not this program. Pass the accepted flags and one path at a time after `--`. Do not call `sudo`. Do not replace `/usr/bin/rm` or `/bin/rm`.

#### Non-goals

- This program does not install itself as `/usr/bin/rm` or `/bin/rm`.
- Tests for this verb do not run real mode. They use `--dry-run` so a system directory cannot be removed by the suite.
- The guard does not keep a database of paths.

### 2.3 Specialized project help items

`safe-rm help` keeps the Type 0 rows and adds:

| Row | Text that must appear |
|-----|------------------------|
| `rm` | Check each path. Remove only when every path is allowed |
| `rm --dry-run` | Remove nothing. Say whether each path exists and whether it may be removed |
| `--dry-run` | The same switch may appear before or after `rm` |
| Stop line | Do not retry with `rm`, `/bin/rm`, or `/usr/bin/rm` |

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
| `TP-SRM-09` | Dry-run of `/home` and `/home/safe-rm-no-such-user` is refused and does not create the fake path |
| `TP-SRM-10` | Dry-run of `/usr/bin` and `/usr/bin/sh` is refused and both remain |
| `TP-SRM-11` | Dry-run of `/` is refused and `/` remains |
| `TP-SRM-12` | Dry-run of this project directory (inside the login home) is refused and the directory remains |
| `TP-SRM-13` | One allowed path plus `/usr/bin` refuses the whole command and the allowed path remains |
| `TP-SRM-14` | `--json` dry-run allow: `dry_run` true, `removed` false, `verdict` allow, `exists` true |
| `TP-SRM-15` | `--json` dry-run refuse: `verdict` refuse, `removed` false, stderr says `STOP` |
| `TP-SRM-16` | `rm --dry-run` with no path exits `1` |
| `TP-SRM-17` | An unknown command still exits `1` and points at help |
| `TP-SRM-18` | `about` includes `Remove guard:` |
| `TP-SRM-19` | `--quiet` still prints the refusal |

Runner: `tests/run_dry_run.sh`. It does not point `HOME` at a scratch directory.

### 2.6 Implementation Notes (this project)

| Fact | Value |
|------|--------|
| Product | `safe-rm` |
| Ship unit | `src/safe-rm` |
| Companion | `src/safe-rm.sha256` |
| Version | `1.0.0` |
| Prefix | `srm_` |
| Bootstrap origin | `selfmanaged` Type 0 architecture. That ship unit stays `src/selfmanaged`. Direction is origin to this product |
| Channel default | `REPO_USER=cloudgen`, `REPO_NAME=safe-rm`, `SCRIPT_RELPATH=src/safe-rm` |
| Dispatcher anchors | `--dry-run` flag, `rm` command, `srm_cmd_rm` route |

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Resolve the path, then refuse. One refused path cancels the whole command.
- **Intentional:** The stop sentence tells the operator not to retry with the system `rm`.
- **Anti-fragile:** `--dry-run` is the way to see the verdict without a remove. A missing system `rm` fails closed.
- **Over-protect:** The dry-run branch returns before `srm_exec_one`. `srm_exec_one` also refuses to run when dry-run is set.

---

## 4. Protection Rule (Sacred)

**Future agents MUST NOT:**

1. Call the system `rm` from the `--dry-run` path.
2. Remove any path after one path in the same command was refused.
3. Replace `/bin/rm` or `/usr/bin/rm` with this program.
4. Point `HOME` at a scratch directory in order to test this command.
5. Add a test that invokes `rm` without `--dry-run`.
6. Print the refusal with `echo` or `printf` instead of `out_*`.
7. Treat a folder inside the login home as allowed.

**Violating this rule is a critical remove-guard regression.**

---

## Under command line for normal user only

This product may run on Termux, Git Bash, Windows cmd, or the same class (this login only).

**This requirement:** `rm` stays **normal user privilege**. It does not ask for admin privilege and it does not switch to a dedicated account. It does not wrap `sudo`.

| MUST | MUST NOT |
|------|----------|
| Refuse the login home and `/usr/bin` the same way on this login | Enable admin-privilege install of a replacement system `rm` |
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

**Last Updated**: 2026-09-27
**Owner**: safe-rm project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
