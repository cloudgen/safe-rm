**file**: docs/requirements/requirement-actor-role-subject.md
**id**: RQ-ACTOR-ROLE-SUBJECT
**Status**: Active (Version 1.0.3)
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement says **who** may run each family of safe-rm commands. There is no dest review and no approver. The row that matters for the 2023 swap is **setup**: the check that `/usr/bin/origin-rm` or `/bin/origin-rm` already holds the original binary, and the move that does that swap when it has not happened.

**Scope:** Actor, role, and subject for the main menu, the guard, setup, restore, and the selfmanaged lifecycle.
**Out of scope:** How the swap moves the file (`requirement-domain-safe-rm.md`). Which rows the main menu draws (`requirement-shell-cli-default-interaction.md`).

### 1.1 Human-facing

**In one sentence:** Any login may open the main menu and run the guard; only an admin login may run setup, and setup is the check of whether `/usr/bin/origin-rm` or `/bin/origin-rm` already exists.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person at the keyboard | `safe-rm` then `9` |
| The other role | An admin login that may move `/usr/bin/rm` and `/bin/rm` | Setup that checks `origin-rm` |
| Not this file | The refuse table and the menu numbers | Peer requirements |

| Includes | Excludes |
|----------|----------|
| Who may run setup, restore, the menu, and `rm` | An approver account |
| Subject **None** when the command is not for another person's request | A dest review queue |

| Surface | What you open | What for |
|---------|---------------|----------|
| `safe-rm` | Command on a terminal | Main menu, this login |
| Setup | Admin command | Check and, if needed, swap `origin-rm` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Open the menu | This login. No admin step | `safe-rm` or `safe-rm --debug` |
| Check the swap | Admin login only. Looks for `/usr/bin/origin-rm` or `/bin/origin-rm`, then moves the original binary there if it is still named `rm` | Setup, as that admin login |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Table

Three columns. No approver.

| Actor | Role | Subject |
|-------|------|---------|
| This login, on a terminal | Opens the main menu (`safe-rm` or `safe-rm --debug`) | None |
| This login | Runs the guard (`rm`, `--dry-run`) | The path named on that command |
| This login | Runs self-install, version, about, help, menu, self-update, self-uninstall. Each of those words is also `--` plus the same word, including when this program is the `rm` people type (`rm version`, `rm --help`) | None |
| Admin login: root, or a login that can move `/usr/bin/rm` and `/bin/rm` | Runs **setup**. Setup checks whether `/usr/bin/origin-rm` or `/bin/origin-rm` is already the original binary. If it is, setup does not move `rm` again and replaces the existing `safe-rm` with this program. If `rm` is still the original binary, setup moves it to that `origin-rm` path and points `rm` at this program | The host `rm` command (`/usr/bin/rm`, `/bin/rm`, `/usr/bin/origin-rm`, `/bin/origin-rm`) |
| The same admin login | Runs `restore` | The host `rm` command |
| A pipe, or quiet, or json, with no command | Places this CLI. Does not open the menu and does not move `rm`. When that place is root and `origin-rm` is already there, it replaces the guard file with this program | None |

Rules:

1. A login that cannot move `/usr/bin/rm` and `/bin/rm` **MUST NOT** run setup and **MUST NOT** run `restore`. That login may still open the main menu and run the guard.
2. Setup's first act is the check. The check looks at `/usr/bin/origin-rm` and `/bin/origin-rm`. An existing original binary there means the swap already happened. Setup **MUST NOT** move `rm` again in that case. Setup **MUST** replace the existing `safe-rm` when its bytes are not this program. A root place does the same replace and does not move `rm`. A non-root place does not write `/usr/bin/safe-rm` or `/bin/safe-rm`.
3. On Termux, Git Bash, and Windows cmd, nobody runs setup. The swap stays unused. The menu and the guard still run as this login.
4. The main menu does not ask for admin privilege. Choosing a leaf that is setup or `restore` still has to pass the admin row above.
5. Setup's check compares the host to the before/after table. That table lives in `requirement-domain-safe-rm.md` §2.0.1. Before swapped, `/usr/bin/rm` and `/bin/rm` are the original binary and `origin-rm` is absent. After swapped, those `rm` paths are this guard and the original binary is `/usr/bin/origin-rm` or `/bin/origin-rm`.

### 2.2 Implementation Notes

| Item | Value |
|------|--------|
| Product | safe-rm |
| Dest review | None. This table has no approver |
| Setup actor | Admin login on a Linux host. `safe-rm setup` refuses otherwise, unless `SRM_SWAP_ROOT` is a `/tmp/safe-rm-swap.*` directory used by tests |
| Menu actor | This login. Live: interactive 0-argv, including `--debug` alone, calls `app_default` |

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** The check of `origin-rm` is the same privileged setup as the move.
- **Intentional:** The menu is for this login. The swap is for the admin login.
- **Anti-fragile:** A second setup finds `origin-rm` already present and does not move `rm` again.
- **Over-protect:** No approver column. There is no dest review.

---

## 4. Protection Rule (Sacred)

**Future agents MUST NOT:**

1. Let a non-admin login run setup or `restore`.
2. Treat "check whether origin-rm exists" as a different person from the person who may move `/usr/bin/rm`.
3. Add an approver column.
4. Open the main menu only for the admin login.

---

## Under command line for normal user only

**This requirement:** On Termux, Git Bash, and Windows cmd the setup row does not run. This login still opens the main menu and runs the guard. Do not call `sudo` there to become the admin actor.

| MUST | MUST NOT |
|------|----------|
| Main menu and the guard as this login | Setup or `restore` on Termux, Git Bash, or Windows cmd |

---

## 5. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-domain-safe-rm.md` | What setup and the remover do |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Main menu |
| `docs/requirements/index.md` | Registry |

---

**Last Updated**: 2026-09-27 (1.0.3 — lifecycle verbs are switches, including on the command named `rm`)
**Owner**: safe-rm project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
