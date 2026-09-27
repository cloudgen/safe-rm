# Report: first-install helper can look successful without placing the program

**Date:** 2026-09-02  
**Updated:** 2026-09-06 — recast honesty: body below mixed report-time “not patched” notes with a later close. Canonical status remains **closed 2026-09-02** (helper patched; **TP-LC-10** / **TP-INST-MAYBE-01** **have**). Do not treat the “Suggested fix (not done)” block as current.  
**Mode:** Coverage + human-readable recast (closed after helper patch)  
**Product:** selfmanaged **1.2.3** (`./selfmanaged`) at close; current line is **1.2.4**  
**Status:** closed (helper patched 2026-09-02)  
**Finding ID:** SM-BUG-01  
**Lesson:** L-INST-MAYBE-01  
**Test:** TP-INST-MAYBE-01 / TP-LC-10 (**have**)

## Summary

If nobody has installed `selfmanaged` yet, the friendly helper `inst_maybe_install` is supposed to **place the program** (after a yes on a real terminal, or automatically under a pipe / quiet / JSON). Live code still **returns success without placing** when `JSON=1` or `QUIET=1`.

The advertised one-liner with **no flags** still works: empty argv in `app_main` calls `inst_perform_install` first when quiet/json is already set. The hole is the **helper itself**, and any specialized product that copies only that helper as “first install.”

This is **not** a missing incident file. There is no `docs/incidents/incident-*.md` on disk.

## In one sentence

A first-time quiet/JSON trip through the helper can look like “all good” while nothing was installed.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | First install, or a product copied from this bootstrap | `inst_maybe_install` under `QUIET=1` / `JSON=1` |
| The other role | Empty argv with **no tokens** (`curl \| sh`) | `app_main` already places via `inst_perform_install` |
| Not this finding | `selfmanaged --json` / `--quiet` with no command (those have argv; default command is help) | Separate dispatcher question |

## What a person is supposed to see (law)

| Situation | Must happen |
|-----------|-------------|
| Real terminal, not quiet/json | Note + yes/no. Yes places; no skips; no help dump. |
| Pipe (`curl \| sh`) | Auto-install message + place. |
| Quiet or JSON, not installed | Place with **no** question. Failure = non-zero. **Must not** return 0 without placing. |
| Already installed, force off | Success no-op (“already installed”), not help. |

Both live requirements now say the **same** thing:

- `requirement-shell-cli-zero-arguments.md` §2.4 — empty argv **and** the helper
- `requirement-shell-interactive-vs-noninteractive.md` — `inst_maybe_install` contract (was: helper may return without installing; **corrected 2026-09-02**)

## What the program does today

```sh
# ./selfmanaged — inst_maybe_install
if inst_is_installed && [ "${FORCE_REINSTALL}" -eq 0 ]; then
    return 0
fi
if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
    return 0   # not installed, no place, exit success
fi
```

Related live Gaps (law > code; same helper):

1. Re-tests `[ -t 0 ] && [ -t 1 ]` instead of reading process `TTY` (set once at startup).  
2. Empty argv with `--json` / `--quiet` **on the command line** is **not** empty argv (`$# -ne 0`); that path is help-default, not this skip.

`app_main` empty-argv (`$# -eq 0`) still calls `inst_perform_install` when JSON/quiet is already set in the environment, so `curl | sh` with no flags still auto-installs.

## Impact

- **This product’s one-liner:** not a silent no-op.  
- **This product’s helper:** dead-code skip if quiet/json ever reaches it; specializees that copy the helper inherit a fake success.  
- **Tests:** suite does not call the helper under QUIET/JSON when not installed (`TP-INST-MAYBE-01` still TODO).

## Suggested fix (not done in this report)

1. When not installed and `JSON=1` or `QUIET=1`: call `inst_perform_install` and return its status. **Do not** `return 0`.  
2. Gate the prompt on process `TTY`, not a second `[ -t`.  
3. Suite: not installed + QUIET/JSON **through the helper** must place or fail closed.

## Issues

### Issue 1 -- Severity: bug
- File: `selfmanaged:958`
- Description: `inst_maybe_install` returns 0 under JSON/QUIET without placing when Case A applies.
- Suggestion: Call `inst_perform_install`; return its status.
- Lesson: L-INST-MAYBE-01
- Test: TP-INST-MAYBE-01
- Status: closed

### Issue 2 -- Severity: suggestion
- File: `selfmanaged:977`
- Description: Helper re-tests `[ -t 0 ] && [ -t 1 ]` instead of consuming `TTY`.
- Suggestion: Read `TTY` (same as the prompt samples now in the interactive requirement).
- Lesson: L-INST-MAYBE-01
- Test: TP-INST-MAYBE-01
- Status: closed

## Related

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty-argv Case A + helper must place under quiet/json |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | Mode matrix + helper contract (aligned 2026-09-02) |
| `./selfmanaged` | `inst_maybe_install` · `app_main` empty-argv |
| `reviews/test-plan.md` | TP-INST-MAYBE-01 |
| `reviews/lessons.md` | L-INST-MAYBE-01 |

**Written by:** Review (coverage + human-readable recast)  
**Review status:** Closed — helper places under quiet/JSON; prompts consume `TTY`; TP-LC-10 in suite
