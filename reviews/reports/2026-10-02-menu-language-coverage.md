# Menu language coverage — safe-rm — 2026-10-02

## Verdict

Authorized implementation. The class gate passes. Menu language was not product law, and the front board had no row **5**. Ship unit **1.0.20** closes that gap. This is not an approve-as-is review.

## Class gate

Software-development. One Active `requirement-class-software-dev.md`. Pass.

## Registry

Before this change the registry and the disk matched: 15 Active rows (1 class, 13 shell, 1 domain). No orphan requirement file. No language file.

After this change: 16 Active rows. New row `requirement-shell-cli-language` **1.0.0**. Peers bumped in the same change: default-interaction **1.1.3**, interface **1.2.9**, storage **1.1.3**, modular function design **1.0.6**, domain **1.2.21**.

## Gap

The sibling contract puts menu language on front row **5**, block **50–69**, thirteen codes, one persistence leaf, and an environment override that does not write the file. safe-rm **1.0.19** had front **1**, **8**, and **9** only. English menu tests depend on `Choice: `, `9. Exit`, `0. Back`, and `Not a menu choice '3'`.

## What was specialized

The safe-rm boards, the help headings, the `menu` help sentence, the about title, and the cache labels follow `APP_LANG`. Operational `rm` text, JSON about, and `version` stay English. Domain law only points at the language requirement. It does not own the copy.

Default remains English. `SRM_LANG` wins for one process. The leaf is `${HOME}/.local/safe-rm/language`, mode `0600`.

## Proof

`TP-CLI-24` in `tests/run_dry_run.sh`. `HOME` is under the suite scratch directory. The check does not execute a real `rm` and does not remove a directory. `./tests/run_dry_run.sh` on 2026-10-02: PASS=760 FAIL=0. JSON about keys stay English.

## Not done

The installed host guard is not replaced by this checkout. Editing `src/safe-rm` does not change the `rm` people type until that version is installed.
