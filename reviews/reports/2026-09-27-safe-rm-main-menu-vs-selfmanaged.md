# Report: main menu vs selfmanaged — safe-rm 1.0.0

**Date:** 2026-09-27
**Mode:** domain review (numbered main menu only). Not a design. Ship unit was not changed in that review.
**Status:** closed 2026-09-27 — `src/safe-rm` now opens the numbered menu on a terminal (front **1** / **8** / **9**). Pipe, quiet, and json empty argv still place. Suite `tests/run_dry_run.sh` PASS=105 FAIL=0.
**Verdict:** Revise (review record). Follow-up implemented the same day.

## Summary

safe-rm does not have a main menu similar to selfmanaged 1.4.0. On a terminal, `selfmanaged` with no arguments opens a numbered board: **8** self-management and **9** Exit. Choosing **8** opens **82–87** (version through self-install) and **0** Back. The same terminal invocation of `safe-rm` prints “not installed yet” and asks whether to install. `safe-rm menu` is an unknown command.

The self-management subtree is the part that must match. safe-rm also has a domain verb, `rm`, which selfmanaged does not. Copying the origin front board as two rows would hide that verb. The origin leaves front **1** and **2** unprinted because it has no domain, and leaves **81** unprinted because it has no payload. safe-rm has no payload either, so **81** stays hidden. `rm` belongs on a domain category, not on the front board next to install and version.

A pipe, `--quiet`, or `--json` with no arguments still places the program on selfmanaged. That path on safe-rm is already correct and must stay.

Lessons loaded: `reviews/lessons.md`. Open **L-REQ-CIAO-URL-01** re-checked on the interface and self-install requirements: CIAO links still point at `github.com/cloudgen/ciao`. No new bulk-sed. The lesson stays open as process vigilance.

Not in scope, and not claimed by this product: Type 1 elevation, a least-privilege account, JSON sudoer grants, and a host daemon started by `self-update`. The unknown-command line for `menu` is already an operator sentence (`Unknown command or flag: menu. See 'safe-rm help'.`).

Suite `./tests/run.sh` was not re-run. Evidence is the live probes below plus the ship unit and the requirement text.

## Reference (selfmanaged 1.4.0)

Probed `selfmanaged/src/selfmanaged` (same boards as the sibling project `prjs/selfmanaged`). Forced `TTY=1`, then `9`, and `8` / `0` / `9`. Exit 0. No place.

Front:

```text
[INFO] selfmanaged(1.4.0) — Shell script bootstrap for self Installation & Maintenance
8. self-management: this CLI install, version, update, uninstall
9. Exit
```

Under **8**:

```text
[INFO] selfmanaged(1.4.0) — self-management
82. version: show current version
83. about: show detailed diagnostics
84. version-check: compare local vs remote version
85. self-update: update selfmanaged to a newer remote version
86. self-uninstall: remove selfmanaged
87. self-install: place this CLI only (copy when $0 is a script; download when piped)
0. Back
```

On a real terminal the header is bold name and italic version, and each explain is italic light gray (`out_text` kind `menu_choice`, SGR 1 and SGR 3;37). **1**, **2**, and **81** are reserved and not printed. `install` is not a row. Law: `selfmanaged/docs/requirements/requirement-shell-cli-default-interaction.md`.

The bootstrap binary at `src/selfmanaged` is still **1.3.1** and has no `app_default_print_menu`. It is not the menu reference.

## safe-rm probes (1.0.0)

Isolated `USER_BIN` and `GLOBAL_BIN`. Nothing was placed.

| Invocation | Exit | What happened |
|------------|------|----------------|
| `TTY=1`, no arguments, answer `n` | 0 | “Note: 'safe-rm' is not installed yet.” then `Install safe-rm 1.0.0 now? (y/N)?` then “Installation skipped by user.” |
| `menu` | 1 | `[ERROR] Unknown command or flag: menu. See 'safe-rm help'.` |
| `help` | 0 | Flat verb list. Self-management rows, then “Remove guard” (`rm`, `rm --dry-run`). No numbered board. No `menu` or `main` row. |

## Issues

### Issue 1 -- Severity: bug
- File: src/safe-rm:3377
- Description: Interactive empty argv is an install prompt (`inst_maybe_install` when not installed, `inst_self_install` when already installed). selfmanaged routes that case to `app_default` and places only for non-interactive, quiet, or json empty argv (`selfmanaged/src/selfmanaged` around the zero-arg split). Product law forbids the menu: `docs/requirements/requirement-shell-cli-self-install.md` line 62 (“This product has **no** numbered TTY menu”) and `docs/requirements/requirement-domain-safe-rm.md` line 49 (“Empty argv stays install-ensure”).
- Suggestion: Split empty argv the way origin 1.4.0 does. Terminal, not quiet, not json: numbered menu, no place side effect. Pipe, quiet, or json: keep `inst_self_install`. Update the zero-arguments, self-install, and interface requirements in the same change. Do not open the menu under `curl | sh`.
- Lesson: L-MENU-01
- Test: TP-CLI-EMPTY-01
- Status: open

### Issue 2 -- Severity: bug
- File: src/safe-rm:3414
- Description: The dispatcher accepts `version|about|help|version-check|self-update|self-uninstall|self-install|install` and domain `rm`. It does not accept `menu` or `main`. Origin help lists both, and off a terminal they print help.
- Suggestion: Route `menu` and `main` to the same handler as interactive empty argv. Off a terminal, print help (JSON help when `--json`).
- Lesson: L-MENU-01
- Test: TP-CLI-22
- Status: open

### Issue 3 -- Severity: bug
- File: src/safe-rm:2685
- Description: There is no menu printer. `src/safe-rm` has no `out_menu_choice`, no `util_app_ident`, and no `app_default`. Help is the only “menu,” and it is a flat list. The origin draws `N. short: explain` and, on a terminal, bold short name plus italic gray explain.
- Suggestion: Bring the origin printer and the two boards across. Front header is `safe-rm(version)` plus the product short description, then **8** self-management and **9** Exit. Self-management board is **82–87** and **0** Back. Omit **81** (no payload; do not renumber). Omit lifecycle verbs from the front board.
- Lesson: L-MENU-01
- Test: TP-CLI-17
- Status: open

### Issue 4 -- Severity: bug
- File: docs/requirements/index.md:14
- Description: The registry has no `requirement-shell-cli-default-interaction`. The zero-arguments row still says empty argv is install-ensure for every case. Origin registered that requirement on 2026-09-27 and split interactive empty argv into the menu. `SK-CLI-DEFAULT-INTERACTION` says the numbered tree is its own requirement, not a paragraph inside the domain file.
- Suggestion: Add the default-interaction requirement for safe-rm, retarget identity to safe-rm, and point the zero-arguments row at the split (interactive menu, otherwise place).
- Lesson: L-MENU-01
- Test: TP-CLI-17
- Status: open

### Issue 5 -- Severity: bug
- File: src/safe-rm:2732
- Description: The domain verb `rm` exists only on help. A similar menu is not the origin’s two-row front board copied verbatim: that board hides **1** and **2** because selfmanaged has no domain. Putting `rm` on the front board beside **8** would also violate the skill rule that the front board is categories (and Exit), while install, version, about, and the other self-managed verbs stay under **8**. `rm` is not one of those self-managed verbs.
- Suggestion: Keep the origin self-management board unchanged in numbering. Add one front category for the remove guard (the reserved client-side slot **1**), with the live `rm` row under it, **0** Back, and Exit only on the front board as **9**. After `rm` finishes, show the front board again. A bad pick reprints that layer and does not `out_die`. This review does not pick the short and long labels; those belong in the hierarchy table when the menu is implemented.
- Lesson: L-MENU-01
- Test: TP-CLI-SRM-01
- Status: open

### Issue 6 -- Severity: suggestion
- File: tests/test_cli.sh:205
- Description: `TP-SI-03` locks non-interactive empty argv as self-install, which should remain. Nothing locks the interactive menu, bold/italic rows, bad-pick retry, return to the front board after a leaf, or “under 8, **87** is present and **81** is absent.”
- Suggestion: Add the TODO rows in `reviews/test-plan.md`. Do not weaken `TP-SI-03`.
- Lesson: L-MENU-01
- Test: TP-CLI-17, TP-CLI-19, TP-CLI-21, TP-CLI-22, TP-CLI-EMPTY-01, TP-CLI-SRM-01
- Status: open

### Issue 7 -- Severity: nit
- File: docs/requirements/requirement-shell-cli-interface.md:36
- Description: Several Type 0 requirements still speak as selfmanaged (`selfmanaged help`, owner “selfmanaged project maintainers”, channel examples `cloudgen/selfmanaged`). The word “menu” in that file means the help verb list, which is the opposite of the numbered board.
- Suggestion: Retarget those identity lines when the menu requirement is added. Keep `github.com/cloudgen/ciao` (L-REQ-CIAO-URL-01).
- Lesson: L-REQ-CIAO-URL-01
- Test: none
- Status: open

## What already matches

- Non-interactive empty argv places the CLI and does not open a menu (`requirement-shell-cli-self-install.md` rule 1). Keep that.
- `help` still lists Type 0 verbs and the remove guard. The numbered menu does not replace help.
- No payload, so **81** `install` stays off the board on origin and should stay off on safe-rm. The `install` argv alias can remain a hidden alias of `self-install`.
- `rm` refuse rules and `--dry-run` are unchanged by this review.

## Lessons re-checked

| L-ID | This run |
|------|----------|
| L-REQ-CIAO-URL-01 | Still open. CIAO URLs in the files read for this review were not rewritten. |
| L-MENU-01 | New. See `reviews/lessons.md`. |
| Other closed L-* | Not re-executed. They are outside this menu scope. |
