# Report: coverage, README readability, previous-incident lock-in

**Date:** 2026-09-06  
**Product:** selfmanaged **1.2.4** (`./selfmanaged`)  
**Status:** closed  
**Suite:** PASS=117 FAIL=0 SKIP=0  
**Finding IDs:** SM-PLAN-01 (closed) · coding-style Gap (closed) · README Type-0 lead (closed)

## Summary

Previous-incident remainder **SM-PLAN-01** (`out_json` `@key` with no suite assertion) is now **have** as **TP-JSON-RAW-01**. Software-development class residual listed coding-style as Gap; `requirement-shell-script-coding.md` is Active and the class file **points**. Product README Description now leads with people/install, not Type 0. Related shell requirements print **Under command line for normal user only**.

## In one sentence

The leftover JSON `@key` lock-in is tested, coding lessons have a specialize-in home, and a newcomer can read the README without privilege-type codes as the only words.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Operator installing or reviewing this CLI | `selfmanaged about` · `./tests/run.sh` |
| The other role | Specializee that copies `out_json` / helpers | `@key` must stay unquoted; no `util_sudo` on this bootstrap |
| Not this | Domain verbs / dest approve / in-tool sudo | Bootstrap has none |

## What was wrong

| ID | Surface | Before |
|----|---------|--------|
| SM-PLAN-01 / L-JSON-RAW-01 | `reviews/test-plan.md` TP-JSON-RAW-01 | Impl present; suite **TODO** |
| Class residual | `requirement-class-software-dev.md` | Coding-style **Gap** (lessons arrive raw) |
| README Description | `README.md` | Lead sentence was Type 0 / Type O jargon |
| Related shell REQs | `docs/requirements/requirement-shell-*.md` | Missing exact heading **Under command line for normal user only** |
| 2026-09-02 report body | `reviews/reports/2026-09-02-…` | Closed status vs “not patched” body |

## What changed (this pass)

1. `tests/test_cli.sh` — TP-JSON-RAW-01 (raw array/object; string keys quoted; JSON=0 no-op) + TP-CS-01 (no `util_sudo` / command-position `sudo`).  
2. `requirement-shell-script-coding.md` registered; class residual points.  
3. README voice pack (one sentence, three boxes, includes/excludes, practice). Help `DESCRIPTION` aligned.  
4. Exact **Under command line for normal user only** section on related shell REQs (output-only file skipped).  
5. 2026-09-02 report recast banner so “not patched” is historical.

## Verdict

**Pass** for C-lifecycle + README readability + previous-incident lock-in. Remaining vigilance only: L-REQ-CIAO-URL-01 (process), L-CSUM-01 (wording).

**Written by:** Implement + Review  
**Date:** 2026-09-06
