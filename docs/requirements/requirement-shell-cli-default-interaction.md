**file**: docs/requirements/requirement-shell-cli-default-interaction.md  
**Status**: Active (Version 1.1.1)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the project Single Source of Truth for the **numbered terminal menu** of safe-rm.

This file is the **main menu requirement**. On a real terminal, typing only `safe-rm` shows that menu. `safe-rm --debug` is the same menu: `--debug` is not a command, so it does not take the run off the menu. `safe-rm menu` and `safe-rm main` open the same list. **1** is the remove guard. **8** is self-management. Choosing **1** opens **11** `rm` and **0** Back. Choosing **8** opens the lifecycle list **82–87** and **0** Back. **9** leaves. A pipe, a quiet run, or a json run with no command still places the program and does not open this list.

**Scope:** When the list appears, which rows it has, how a row is drawn, what a bad pick does, and what happens after a command finishes.  
**Out of scope:** How place/copy/download works (`requirement-shell-cli-self-install.md`); the non-interactive empty-argv place matrix (`requirement-shell-cli-zero-arguments.md`); the full `out_*` catalog (`requirement-shell-output-requirements.md`); refuse classes for `rm` (`requirement-domain-safe-rm.md`).

### 1.1 Human-facing

**In one sentence:** At a terminal, `safe-rm` and `safe-rm --debug` show the main menu (item **1** is the remove guard, item **8** is self-management). Away from a terminal, no command still installs or says it is already installed.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | A person at a terminal | `safe-rm` then `8` then `82` |
| The other role | A pipe or a script with no one to answer | `curl -fsSL …/src/safe-rm \| sh` |
| Not this file | Checksum math, scratch paths, which paths `rm` refuses | Peer requirements |

| Includes | Excludes |
|----------|----------|
| Front **1**, **8**, and **9**; remove-guard **11** and **0** Back; self-management **82–87** and **0** Back | Server-side **2** (this product has no server board) |
| Bold short name and italic gray explain on a terminal | A second menu look |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Open the list | Front board, then leave. `--debug` alone still opens this list | `safe-rm` then `9`, or `safe-rm --debug` then `9` |
| Open the remove guard | **11** lists subfolders of the current path, plus a number to type a path | `safe-rm` then `1` then `11` |
| Check, update, or place | Open **8**, then **82–87** | `safe-rm` then `8` |
| Step back | Return to the front board | `0` |

---

## 2. Core Rules (Mandatory)

### 2.1 When the list appears

safe-rm has a zero-argument requirement. That file owns empty argv. This file owns the numbered list.

| Situation | What runs |
|-----------|-----------|
| Interactive 0-argv: no command token, `TTY=1`, `JSON=0`, `QUIET=0`. `--debug` is excluded from the command count, so `safe-rm --debug` is still 0-argv | This main menu (`app_default`). `DEBUG=1` when `--debug` was present |
| No command, and no TTY, or `JSON=1`, or `QUIET=1` | `inst_self_install` (not this menu, not help). `--debug` does not change that |
| A command token is present (`version`, `rm`, `self-install`, …) | That command. `--debug` only turns debug on |
| `menu` or `main` on a TTY | This menu. `--json` and `--quiet` are ignored while the list is drawn |
| `menu` or `main` off a TTY | `app_help` (JSON help when `--json`) |

`--quiet`, `--json`, and `--force` are not excluded the way `--debug` is. `safe-rm --quiet` and `safe-rm --json` with no command still place the program. `safe-rm --force` with no command is not this menu.

1. The choice **MUST** be read in the current shell. **MUST NOT** capture a `read` helper with `$()` or backticks. The path prompt under **11** follows the same rule.  
2. A failed `read` (EOF) **MUST** leave the current layer without spinning. On the front board that leaves the program. On a submenu that returns to the front board.  
3. **MUST NOT** hang when there is no terminal.

### 2.2 Front board

**2** stays reserved and **MUST NOT** be printed. The front board **MUST NOT** print Back. The front board **MUST NOT** print `rm`, `version`, `about`, `version-check`, `self-update`, `self-uninstall`, `self-install`, `install`, `help`, `menu`, or `main` as its own row.

| # | Token | Label |
|---|-------|-------|
| *(header)* | — | `**safe-rm**(*version*) — Guarded rm that refuses login homes and system directories` |
| **1** | `remove-guard` | `remove-guard: check a path and remove it only when it is allowed` |
| **8** | `self-management` | `self-management: this CLI install, version, update, uninstall` |
| **9** | Exit | leave the program |

1. **9**, `exit`, `quit`, or an empty line on the front board **MUST** return 0.  
2. **1** or `remove-guard` **MUST** open the remove-guard board.  
3. **8** or `self-management` **MUST** open the self-management board.  
4. A typed leaf that is listed under **1** (`11`, `rm`) or under **8** (`version`, `about`, `version-check`, `self-update`, `self-uninstall`, `self-install`) **MAY** run from the front prompt, then the front board **MUST** show again.  
5. `install` is not a listed row (**81** is reserved). Typing it here is a bad pick. `help`, `menu`, and `main` **MUST NOT** be rows.

### 2.3 Remove-guard board (parent 1)

| # | Token | Label |
|---|-------|-------|
| *(header)* | — | `**safe-rm**(*version*) — remove-guard` |
| **11** | `rm` | `rm: check each path and remove only when every path is allowed` |
| **0** | Back | return to the front board |

1. **0**, `back`, or an empty line **MUST** return to the front board and **MUST NOT** run `rm`.  
2. **11** or `rm` **MUST** open a path board in the current shell. The board **MUST** show `Current path:` as the working directory, then each immediate subfolder as **1…N** (`folder name: absolute path`), then the next number **custom-path** (`type a path`), then **0** Back. Files and dotfolders **MUST NOT** be rows. Names that contain a newline **MUST NOT** be rows. Folder order **MUST** be byte order (`LC_ALL=C`).  
3. A folder number, or that folder’s name, **MUST** call `srm_cmd_rm` with that folder’s absolute path. The **custom-path** number **MUST** ask `Path:` in the current shell, then call `srm_cmd_rm` with the typed text. The tokens `custom-path` and `custom` **MUST** do the same, unless a listed folder already has that name, in which case the folder is chosen.  
4. An empty typed path **MUST** `out_error` and reprint the path board. **MUST NOT** `out_die` for an empty path. **MUST NOT** call `srm_cmd_rm` for an empty path.  
5. **0**, `back`, or an empty line on the path board **MUST** return to the remove-guard board and **MUST NOT** call `srm_cmd_rm`.  
6. A bad pick on the path board **MUST** `out_error`, name the pick, and reprint the path board. **MUST NOT** `out_die`.  
7. The path board is a data picker. Its rows **MUST** be **1…N**, not **111…**. The `rm` row on the remove-guard board stays **11**.  
8. After `rm` finishes, the **front** board **MUST** show again. **MUST NOT** stay on the path board or on this board. **MUST NOT** leave the program only because the command finished. A refused path still follows `requirement-domain-safe-rm.md` (that path calls `out_die`).  
9. **9** is not a row on this board or on the path board. It is a bad pick here.  
10. The choice and the typed path **MUST** be read in the current shell. **MUST NOT** capture either `read` with `$()` or backticks.

### 2.4 Self-management board (parent 8)

Online script-alone, no payload. **81** `install` stays reserved and **MUST NOT** be printed. Do not renumber the rows that remain.

| # | Token | Label |
|---|-------|-------|
| *(header)* | — | `**safe-rm**(*version*) — self-management` |
| **82** | `version` | `version: show current version` |
| **83** | `about` | `about: show detailed diagnostics` |
| **84** | `version-check` | `version-check: compare local vs remote version` |
| **85** | `self-update` | `self-update: update safe-rm to a newer remote version` |
| **86** | `self-uninstall` | `self-uninstall: remove safe-rm` |
| **87** | `self-install` | `self-install: place this CLI only (copy when $0 is a script; download when piped)` |
| **0** | Back | return to the front board |

1. **0**, `back`, or an empty line **MUST** return to the front board and **MUST NOT** run a verb.  
2. A listed number or its token **MUST** run that handler, then the **front** board **MUST** show again. **MUST NOT** stay on this board after a finished command. **MUST NOT** leave the program because the command finished.  
3. **9** is not a row on this board. It is a bad pick here.

### 2.5 Look

1. Header **MUST** be live `APP_NAME(VERSION)`: bold name, italic version, then the board title, printed with `out_info`.  
2. Each command row **MUST** be `N. short: explain` via `out_menu_choice`. The number is plain. On a TTY the short name **MUST** be bold (SGR **1**) and the explain **MUST** be italic and light gray (SGR **3** + **37**). Off a TTY the same words are plain.  
3. Exit and Back have no explain.  
4. **MUST NOT** draw the explain unstyled on a TTY. **MUST NOT** use a second color scheme.

### 2.6 Bad pick

An unused number, an unknown name, or a hidden reserved number (**2**, **81**, submenu **9**) **MUST** `out_error`, name the pick, reprint **this** layer, and read again. **MUST NOT** `out_die`. **MUST NOT** treat the pick as an unknown argv command. **MUST NOT** jump from a submenu back to the front board on a bad pick.

### 2.7 Implementation Notes

| Item | Value |
|------|--------|
| **Product** | safe-rm |
| **Ship unit** | `src/safe-rm` |
| **Claimed** | yes |
| **Case** | Zero-argument requirement exists. It defers **interactive** empty argv here. Non-interactive empty argv stays Type O place |
| **Handler** | `app_default`; remove-guard layer `app_default_rm_loop`; path board `app_default_ask_rm`; self-management layer `app_default_self_loop` |
| **Honesty** | **Implemented.** |

### 2.8 Why this requirement exists (CIAO)

- **Caution:** A pipe never waits on the list.  
- **Intentional:** **1** is the remove guard. **8** is self-management. **87** is place-this-CLI. **11** is `rm`.  
- **Anti-fragile:** A wrong number reprints that board. A finished command returns to the front board.  
- **Over-protect:** Lifecycle verbs stay off the front board. **81** is not reused for another verb. `rm` is not a front-board row beside **8**.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Non-interactive empty argv stays place.  
- **Intentional:** One numbering card.  
- **Anti-fragile:** Back and Exit are different.  
- **Over-protect:** Do not compact hidden numbers.

---

## 4. Protection Rule (Sacred)

**Future assistants MUST NOT**:

1. Open this menu for empty argv when there is no TTY, or when `JSON=1`, or when `QUIET=1`.  
2. Put `install`, `version`, `about`, `version-check`, `self-update`, `self-uninstall`, `self-install`, `help`, `menu`, or `rm` on the front board as its own row.  
3. Print **81**, or renumber **82–87** because **81** is hidden.  
4. Number children of **8** as **91–94** or restart a command submenu at **1**. Number the `rm` row as **1** on the remove-guard board. Number the path board’s folders as **111…** (that board is a data picker and starts at **1**).  
5. `out_die` on a bad menu pick, or on an empty path at the **custom-path** prompt.  
6. Stay on the self-management board or the remove-guard board after a command finishes.  
7. Put a Back row on the front board.  
8. Draw a TTY explain without italic light gray, or a TTY short name without bold.  
9. Read the choice or the path with `$()` around a helper that calls `read`.  
10. Open **11** onto a bare `Path:` line that does not first list the subfolders of the current path and a **custom-path** number.

---

## 5. Definition of done

| ID | Where | Status |
|----|-------|--------|
| **TP-CLI-17** | `tests/run_dry_run.sh` | have (TTY row is bold short + italic gray explain; header nametag) |
| **TP-CLI-19** | `tests/run_dry_run.sh` | have (bad pick reprints this layer; process stays up) |
| **TP-CLI-21** | `tests/run_dry_run.sh` | have (finished **82** redisplays the front board) |
| **TP-CLI-22** | `tests/run_dry_run.sh` | have (off-TTY `menu` is help; **8** lists **87** and omits **81**) |
| **TP-CLI-EMPTY-01** | `tests/run_dry_run.sh` | have (interactive empty argv is the menu and does not place; `safe-rm --debug` on a TTY is the same menu) |
| **TP-CLI-SRM-01** | `tests/run_dry_run.sh` | have (front has remove-guard, **8**, and **9**; `rm` is **11** under **1**) |
| **TP-CLI-SRM-02** | `tests/run_dry_run.sh` | have (**11** lists subfolders of the current path, then **custom-path**, then **0** Back; empty custom path and a bad pick reprint that board; nothing is removed) |

The Type 0 suite `tests/test_cli.sh` still targets the bootstrap snapshot `src/selfmanaged`. These menu rows live on the safe-rm suite because that is the program the operator runs.

---

## 6. Related artifacts

| Artifact | Relationship |
|----------|----------------|
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv: interactive menu, otherwise place |
| `docs/requirements/requirement-shell-cli-interface.md` | `menu` / `main` on the command table |
| `docs/requirements/requirement-shell-cli-self-install.md` | What **87** / `self-install` does |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_menu_choice` / `out_text` |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | No hang off a TTY |
| `docs/requirements/requirement-domain-safe-rm.md` | What **11** / `rm` refuses |
| `src/safe-rm` | `app_default` |

---

**Last Updated**: 2026-09-27  
**Owner**: safe-rm project maintainers  
**Alignment:** requirement-shell-cli-zero-arguments · requirement-shell-cli-interface · requirement-shell-cli-self-install · requirement-shell-output-requirements · requirement-domain-safe-rm · CIAO / CIAO-Lite
