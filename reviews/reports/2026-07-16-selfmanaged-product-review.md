# Product review: selfmanaged (Type 0 bootstrap CLI) — re-check

**Date:** 2026-07-16  
**Reviewer:** Grok  
**Product:** selfmanaged `VERSION=1.1.0`  
**Ship unit:** `./selfmanaged` (`#!/bin/sh`)  
**Product class:** **Bootstrap project** (no Active domain requirements SSOT; Type 0 shell law only)  
**Scope:** Full Type 0 re-check after creating public `reviews/` plan tree; re-validate 2026-07-15 findings + incident lessons.  
**Method:** Load `reviews/lessons.md` + `what-to-review.md`; static ship unit + requirements registry; run `./tests/run.sh`.  
**Baseline:** PASS=93 FAIL=0 SKIP=0 (2026-07-16).  
**Prior report:** `reports/2026-07-15-selfmanaged-product-review.md`

---

## Pre-flight

| Step | Result |
|------|--------|
| Lessons loaded | Yes — `reviews/lessons.md` (created this pass from prior report + incidents) |
| What-to-review loaded | Yes — `reviews/what-to-review.md` |
| Requirements registry | 8 Active `requirement-shell-*` (Area shell); **no** domain SSOT |
| Class detection | Specialized product + no domain SSOT → **bootstrap project** |
| Tests | RESULT: OK |

---

## Summary

selfmanaged remains a mature **CIAO Type 0** bootstrap CLI: output SSOT, pipe-safe entry (`app_main "$@"`), Type O empty-argv, companion checksum + optional pin, fail-closed uninstall, and a fully green suite (**93/93**).

**No code remediation** in this pass (review-only). Public **review plan** is now established under root `reviews/` (was missing; only a harness-local report under `docs/reviews/`).

**Open debt unchanged at structural level:** storage resolver is still **dead code** (SM-STOR-01 / L-STOR-01). Hygiene leftover `selfmanaged.sha256.tmp` remains on disk but is **gitignored**. Identity hard-assign for `APP_NAME` still absent.

**Verdict:** **Revise** — plan published; prior open findings **confirmed** with current evidence; implement storage wire + law when authorized.

---

## Strengths (re-confirmed)

| Area | Evidence |
|------|----------|
| Entry / bootstrap | File ends with unconditional `app_main "$@"` (L-BOOT-01 closed) |
| Type O empty argv | Suite: not-installed / local / global paths |
| Output SSOT | JSON about on stdout; errors use error type paths |
| CHECKSUM not user-facing in help/about | Suite asserts + ship unit comment ~2426 |
| Uninstall fail-closed | confirm_required without --force |
| set -u / HOME | `env -u HOME version` pass |
| Companion integrity | sha256 match + human transparency messages in suite |
| Bootstrap class honesty | No invented domain REQ |

---

## Lessons re-check

| L-ID | Result 2026-07-16 | Evidence |
|------|-------------------|----------|
| L-STOR-01 | **Still open** | Only definition of `util_resolve_storage` (~2024); no callers; tiers 1–2 `echo` without `mkdir -p` |
| L-STOR-02 | **Still open** | `docs/requirements/index.md` has no storage row |
| L-BOOT-01 | Closed (hold) | `app_main "$@"` at EOF |
| L-TYPEO-01 | Closed (hold) | Suite zero-arg cases green |
| L-UNIN-01 | Closed (hold) | Suite confirm_required |
| L-SETU-01 | Closed (hold) | Suite + code notes in storage function |
| L-CSUM-01 | Partial | Suite green; keep SECURITY/README trust wording honest |
| L-HYG-01 | **Still open** | `selfmanaged.sha256.tmp` exists; `git check-ignore` → `*.tmp` |
| L-ID-01 | **Still open** | `: "${APP_NAME:=selfmanaged}"` only; `VERSION="1.1.0"` hard-assign |

---

## Findings status

### SM-STOR-01 — P1 — **open** (confirmed)

- **Location:** `util_resolve_storage()` ~2024–2047; no call sites  
- **Evidence:** `grep util_resolve_storage` only definition/comments; about JSON lacks storage keys  
- **TP:** TP-STOR-01 TODO  

### SM-STOR-02 — P2 — **open** (confirmed)

- **Location:** requirements registry  
- **Evidence:** No storage requirement file/row  
- **TP:** TP-STOR-02 n/a (docs) until behavior claimed  

### SM-TEST-01 — P2 — **open** (confirmed)

- **Blocked on** SM-STOR-01 wire  
- **TP:** TP-STOR-01 / TP-STOR-03 TODO  

### SM-HYG-01 — P3 — **open** (confirmed, mitigated for git)

- **Evidence:** File present; ignored by `.gitignore` `*.tmp`  
- **Suggestion:** `rm -f selfmanaged.sha256.tmp` locally; optional TP-HYG-01  

### SM-ID-01 — P3 — **open** (confirmed)

- **Evidence:** APP_NAME default-assign only  
- **TP:** TP-ID-01 TODO  

### SM-OUT-01 — P3 — **open** (confirmed, product choice)

- about JSON sample: `app`, `version`, `installed`, paths, shell, user — **no** storage  
- Couples to SM-STOR-01  

### SM-DOC-01 — P3 — **open** (confirmed)

- Modular inventory still lists `util_resolve_storage` among live helpers without wire/Gap note honesty  

### SM-SEC-01 — P3 — **open** (informational)

- Suite enforces CHECKSUM not in help/about; continue honest trust language  

### New findings this pass

None material beyond plan-surface gap (now closed by creating `reviews/`).

---

## Non-findings

| Check | Result |
|-------|--------|
| Test suite regression | **None** — 93/93 |
| Basename install gate | **Absent** |
| Domain law pollution | **None** — bootstrap class intact |
| Product law cites | Registry honest shell-only |
| help lists CHECKSUM | **No** (required) |

---

## Priority remediation order (unchanged)

1. **SM-STOR-01** + **SM-STOR-02** — wire storage or document Gap + optional requirement  
2. **SM-TEST-01** / TP-STOR-* — tests after wire  
3. **SM-HYG-01** / **SM-ID-01** — local cleanup + identity hard-assign  
4. **SM-DOC-01** / **SM-OUT-01** / **SM-SEC-01** — docs and trust polish  

---

## Plan surface created this pass

| Path | Role |
|------|------|
| `reviews/README.md` | Surface rules |
| `reviews/index.md` | Registry |
| `reviews/what-to-review.md` | Living checklist |
| `reviews/test-plan.md` | TP-* |
| `reviews/lessons.md` | L-* |
| `reviews/reports/2026-07-15-…` | Promoted prior report |
| `reviews/reports/2026-07-16-…` | This report |

---

## Related

| Artifact | Role |
|----------|------|
| `./selfmanaged` | Ship unit |
| `docs/requirements/index.md` | Product law registry |
| `tests/run.sh` | Regression baseline |
| `reviews/lessons.md` | Mandatory re-check |
| Prior `docs/reviews/` | Historical harness copy only |

---

**Written by:** Grok  
**Review status:** Plan published; findings open — **no ship-unit code changes** (review-only).  
**Verdict:** **Revise**
