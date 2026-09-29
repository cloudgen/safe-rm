**file**: docs/requirements/requirement-actor-role-subject.md
**id**: RQ-ACTOR-ROLE-SUBJECT
**Status**: Active (Version 1.0.6)
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement says **who** may run each family of safe-rm commands. There is no dest review and no approver. The row that matters for the 2023 swap is **setup**: the check that `/usr/bin/origin-rm` or `/bin/origin-rm` already holds the original binary, and the move that does that swap when it has not happened.

**Scope:** Actor, role, and subject for the main menu, the guard, setup, restore, and the self-management lifecycle.
**Out of scope:** How the swap moves the file (`requirement-domain-safe-rm.md`). Which rows the main menu draws (`requirement-shell-cli-default-interaction.md`).

### 1.1 Human-facing

**In one sentence:** Any login may open the main menu and run the guard; this login always installs the home guard; on Linux this login then escalates with `sudo` for `/usr/bin/rm` and `/bin/rm`; on Termux this login swaps `$PREFIX/bin/rm` with no `sudo`; on macOS nobody moves `/bin/rm`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person at the keyboard | `safe-rm` then `9` |
| The other role | Root, reached by this login through `sudo` for Linux measure 2 only | The system `rm` move |
| Not this file | The refuse table and the menu numbers | Peer requirements |

| Includes | Excludes |
|----------|----------|
| Who may run setup, restore, the menu, and `rm` | An approver account |
| Subject **None** when the command is not for another person's request | A dest review queue |

| Surface | What you open | What for |
|---------|---------------|----------|
| `safe-rm` | Command on a terminal | Main menu, this login |
| Setup | This login, then root for Linux measure 2 | Home guard, then the system swap |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Open the menu | This login. No admin step | `safe-rm` or `safe-rm --debug` |
| Check the swap | This login writes `${HOME}/.local/bin`. Linux measure 2 is root, via `sudo` when this login is not root. Termux measure 2 is this login on `$PREFIX/bin/rm`. macOS has no measure 2 | `safe-rm setup` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Table

Three columns. No approver.

| Actor | Role | Subject |
|-------|------|---------|
| This login, on a terminal | Opens the main menu (`safe-rm` or `safe-rm --debug`) | None |
| This login | Runs the guard (`rm`, `--dry-run`) | The path named on that command |
| This login | Runs self-install, version, about, help, menu, self-update, self-uninstall. Each of those words is also `--` plus the same word. On the command named `rm`, only the `--` form is that command (`rm --help`, `rm --version`). The bare word is a path (`rm version` removes a link named version) | None |
| This login | Runs **measure 1** on every host. Writes `${HOME}/.local/bin/safe-rm`, `${HOME}/.local/bin/rm`, and `${HOME}/.local/bin/origin-rm`. Does not call `sudo` | The home `rm` |
| This login on Linux, not root | After measure 1, re-execs this program through `sudo` for **measure 2 only**. The password prompt, if any, is `sudo`'s own prompt | `/usr/bin/rm` and `/bin/rm` |
| Root (this process is already root, or the `sudo` child) | Runs **measure 2** on Linux. On Alpine, `/bin/rm` is the BusyBox symlink and `/usr/bin/rm` may be absent; that is still this row. If `origin-rm` is already the remover, does not move `rm` again and replaces `safe-rm` when the bytes differ. Otherwise moves `rm` to `origin-rm`, or writes the BusyBox `origin-rm`, and points `rm` at this program. The child **MUST NOT** call `sudo` | `/usr/bin/rm`, `/bin/rm`, and the matching `origin-rm` |
| This login on Termux | Runs **measure 2** and `restore` for `$PREFIX/bin` only, after measure 1. `which rm` is `$PREFIX/bin/rm` (`/data/data/com.termux/files/usr/bin/rm`). No `sudo`. Does not move `/usr/bin/rm` or `/bin/rm` | `$PREFIX/bin/rm` and `$PREFIX/bin/origin-rm` |
| This login on macOS | Stops after measure 1. Does not move `/bin/rm` or `/usr/bin/rm`. Does not call `sudo` | None for the system paths |
| This login on Git Bash or Windows cmd | Stops after measure 1. Does not call `sudo` | None for a system path |
| Root, same rule as measure 2 | Runs system `restore` on Linux | The host `rm` command |
| A pipe, or quiet, or json, with no command | Places this CLI. Does not open the menu. After the place, runs measure 1, then measure 2 under the host row above | None |

Rules:

1. Measure 1 belongs to this login on every host. A login that cannot write `/usr/bin/rm` still runs measure 1. On Linux, that login reaches measure 2 by the `sudo` re-exec. It **MUST NOT** move `/usr/bin/rm` or `/bin/rm` in the unprivileged process. Alpine's `rm` is `/bin/rm`. Measure 2 still belongs to the root row when `/usr/bin/rm` is absent. Termux is the next row: this login owns `$PREFIX/bin`.
2. Measure 2's first act on that layer is the check. On Linux the check looks at `/usr/bin/origin-rm` and `/bin/origin-rm`. On Termux the check looks at `$PREFIX/bin/origin-rm`. An existing remover there means the swap already happened. Setup **MUST NOT** move `rm` again in that case. Setup **MUST** replace the existing `safe-rm` when its bytes are not this program. The bytes are the measure-1 file when that file exists.
3. On Termux, this login runs measure 2 and `restore` for `$PREFIX/bin/rm` only. Setup **MUST NOT** call `sudo` and **MUST NOT** say an admin login is required. On macOS, Git Bash, and Windows cmd, measure 2 does not run and **MUST NOT** call `sudo`. Measure 1 still runs. The menu and the guard still run as this login on every one of those hosts.
4. The main menu does not ask for admin privilege. Choosing a leaf that is setup or `restore` still has to pass the row for that host. The Linux `sudo` prompt is the system prompt inside measure 2, not a menu row.
5. Setup's check compares the host to the before/after table. The same-directory table is `requirement-domain-safe-rm.md` §2.0.1. Alpine, where `/bin/rm` and `/usr/bin/rm` are different paths, is §2.0.2. Termux, where `which rm` is `$PREFIX/bin/rm`, is §2.0.3. The home layer and the macOS stop are §2.0.5. Before swapped on Alpine, `/bin/rm` is the BusyBox symlink and `/usr/bin/rm` may be absent. After swapped, `/bin/rm` is this guard and `/bin/origin-rm` runs `busybox rm`. Before swapped on Termux, `$PREFIX/bin/rm` is the file `which rm` printed. After swapped, that path is this guard and `$PREFIX/bin/origin-rm` is the remover. On macOS, before and after, `/bin/rm` is Apple's binary.

### 2.2 Implementation Notes

| Item | Value |
|------|--------|
| Product | safe-rm |
| Dest review | None. This table has no approver |
| Setup actor | Measure 1: this login, every host. Measure 2: root on Linux, through `sudo` when this login is not root; this login on Termux for `$PREFIX/bin` only; nobody on macOS, Git Bash, or Windows cmd. Tests use `SRM_SWAP_ROOT` or `SRM_TERMUX_PREFIX` under `/tmp/safe-rm-swap.*` and a sudo stand-in. They do not run the real `sudo` |
| Menu actor | This login. Live: interactive 0-argv, including `--debug` alone, calls `app_default` |

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** The check of `origin-rm` is the same privileged setup as the move.
- **Intentional:** The menu and measure 1 are for this login. Linux measure 2 is root, reached through `sudo` when this login is not root.
- **Anti-fragile:** A second setup finds `origin-rm` already present and does not move `rm` again.
- **Over-protect:** No approver column. There is no dest review.

---

## 4. Protection Rule (Sacred)

**Future agents MUST NOT:**

1. Let the unprivileged process move `/usr/bin/rm` or `/bin/rm`. On Linux that move is the root child. On Termux, this login is the actor for `$PREFIX/bin` only. On macOS, nobody is the actor for `/bin/rm`.
2. Treat "check whether origin-rm exists" as a different person from the person who may move `/usr/bin/rm`.
3. Call `sudo` on macOS, Termux, Git Bash, or Windows cmd, or call `sudo` from the measure-2 child.
4. Add an approver column.
5. Open the main menu only for the admin login.

---

## Under command line for normal user only

**This requirement:** Measure 1 is this login on every host and does not call `sudo`. On Termux this login runs measure 2 and `restore` for `$PREFIX/bin/rm` and does not call `sudo`. On macOS, Git Bash, and Windows cmd, measure 2 does not run. This login still opens the main menu and runs the guard. The Linux `sudo` re-exec is measure 2 only. Do not call `sudo` to become a general admin actor.

| MUST | MUST NOT |
|------|----------|
| Main menu, the guard, and measure 1 as this login | Call `sudo` on Termux, macOS, Git Bash, or Windows cmd |
| Termux measure 2 of `$PREFIX/bin/rm` as this login | Measure 2 or `restore` against `/usr/bin` or `/bin` on Termux, macOS, Git Bash, or Windows cmd |

---

## 5. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-domain-safe-rm.md` | What setup and the remover do |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Main menu |
| `docs/requirements/index.md` | Registry |

---

**Last Updated**: 2026-09-29 (1.0.6 — measure 1 is this login; Linux measure 2 is a `sudo` re-exec; macOS does not move `/bin/rm`)
**Owner**: safe-rm project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
