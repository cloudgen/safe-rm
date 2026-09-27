# Product review: selfmanaged (Type 0 bootstrap CLI)

**Date:** 2026-07-15  
**Reviewer:** Grok  
**Product:** selfmanaged `VERSION=1.1.0`  
**Ship unit:** `./selfmanaged` (`#!/bin/sh`)  
**Scope:** Full Type 0 surface with emphasis on **storage**, integrity, bootstrap entry, output SSOT, tests, and repo hygiene.  
**Method:** Static read of ship unit + requirements registry + tests run (`./tests/run.sh`).  
**Baseline:** PASS=93 FAIL=0 SKIP=0 (2026-07-15).

---

## Summary

selfmanaged is a mature **CIAO Type 0** self-install CLI: strong `out_*` SSOT, JSON errors on **stderr**, unconditional `app_main` (INC-20260712-001 closed), Type O empty-argv install-ensure, Shape A companion checksum + Shape B `CHECKSUM` pin, fail-closed uninstall without `--force`, and a green local test suite.

The main structural gap is **storage**: `util_resolve_storage` exists and matches the multi-user isolation design, but it is **never called**, tiers 1–2 only echo paths without create, and there is **no** product-law requirement for storage (unlike specialized sibling springboot2). Hygiene: tracked-looking `selfmanaged.sha256.tmp` at repo root (covered by `*.tmp` in `.gitignore` if untracked — verify git status).

Overall: **production-ready Type 0** with **storage debt** and a few polish items.

---

## Strengths

| Area | Notes |
|------|--------|
| **Output SSOT** | Full `out_*` family; `out_json_error` on stderr (stdout purity for success JSON) |
| **Bootstrap** | Always `app_main "$@"` — pipe-safe; no basename gate |
| **Empty argv** | Pure Type O: install-ensure for not-installed / installed local / global; exit status propagated |
| **Install integrity** | Companion `.sha256` + optional env pin; mismatch fail-closed; transparent link/value/result messages |
| **Self-update** | Semver compare; `downgrade_blocked` without `--force` |
| **Uninstall** | `confirm_required` non-interactive without force |
| **set -u** | HOME resolve, `IS_ROOT`/`SH` defaults (INC-20260713-001 lessons present) |
| **Prefixes** | Clean `out_`/`inst_`/`app_`/`ver_`/`path_`/`util_`/`prompt_` |
| **Tests** | 93 cases covering CLI + install lifecycle + checksum + downgrade |

---

## Findings

### SM-STOR-01 — Severity: P1 (high)

- **Area:** Storage  
- **Status:** open  
- **Location:** `selfmanaged` `util_resolve_storage()` (~2004–2026); no call sites in `app_main` / `app_about`  
- **Description:** Resolver is **dead code**. Tiers 1–2 `echo` `/dev/shm|…` or `/tmp/…` **without** `mkdir -p`. Tier 3 creates `STORAGE_DIR` only if reached. Nothing sets `EFFECTIVE_STORAGE_DIR` or exports `TMPDIR`. Install still uses `mktemp -t` under system temp (OK for install staging, but product storage root is unused).  
- **Impact:** Multi-user isolation design is not exercised; about/JSON has no storage diagnostics; future callers may copy the “echo only” pattern and hit missing directories.  
- **Suggestion:** Port springboot2 storage remediation pattern:  
  1. Create chosen tier root fail-closed in `util_resolve_storage`.  
  2. In `app_main`: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage); export EFFECTIVE_STORAGE_DIR STORAGE_DIR TMPDIR=…`.  
  3. Surface `effective_storage` / `storage_dir` in `app_about` (human + JSON).  
  4. Add `requirement-shell-cli-storage.md` + registry row (or document deliberate “helper reserved / unused” Gap in modular inventory).  
- **Cross-ref:** springboot2 storage review 2026-07-15 (P1–P2 fixed there).

---

### SM-STOR-02 — Severity: P2 (medium)

- **Area:** Storage / product law  
- **Status:** open  
- **Location:** `docs/requirements/index.md` (no storage row)  
- **Description:** No live **storage** requirement. Modular inventory may list `util_resolve_storage` without ownership law.  
- **Suggestion:** Add `requirement-shell-cli-storage` specialized for selfmanaged (portable core + Implementation Notes: wire or explicit Gap). Register in `index.md`.

---

### SM-HYG-01 — Severity: P3 (low)

- **Area:** Repo hygiene  
- **Status:** open  
- **Location:** repo root `selfmanaged.sha256.tmp`  
- **Description:** Companion temp file present next to `selfmanaged.sha256`. `.gitignore` has `*.tmp` — ensure file is not committed; delete local copy if leftover from digest generation.  
- **Suggestion:** `rm -f selfmanaged.sha256.tmp`; confirm `git status` clean of `*.tmp`. Document companion regen in CHANGELOG/skill-commit-check if not already.

---

### SM-ID-01 — Severity: P3 (low)

- **Area:** Identity extractors  
- **Status:** open  
- **Location:** Config block — `: "${APP_NAME:=selfmanaged}"` without `APP_NAME="selfmanaged"` hardcode line  
- **Description:** `VERSION` is hard-assignable via `VERSION="1.1.0"`; `APP_NAME` is only default-assign. Some test harnesses / about greps use `grep '^APP_NAME="'`. Works for VERSION-based extractors; inconsistent shape vs specialized products that hardcode both.  
- **Suggestion:** Add `APP_NAME="selfmanaged"` + keep `:=` default for override safety (mirror springboot2 extractors).

---

### SM-OUT-01 — Severity: P3 (nit / product choice)

- **Area:** about JSON surface  
- **Status:** open (product choice)  
- **Location:** `app_about` JSON keys  
- **Description:** about JSON is rich (install paths, shell, user) but has no storage fields — consistent with unused resolver (SM-STOR-01).  
- **Suggestion:** When wiring storage, add `effective_storage` / `storage_dir` keys; keep CHECKSUM out of about (checksum law).

---

### SM-TEST-01 — Severity: P2 (medium)

- **Area:** Tests  
- **Status:** open  
- **Location:** `tests/`  
- **Description:** Suite is solid for Type 0 lifecycle (93 green). Gaps relative to storage/hardening: no assert that `util_resolve_storage` is invoked; no isolation test for storage root; no regression that companion temp files are not shipped.  
- **Suggestion:** After SM-STOR-01, add about JSON storage fields + directory-exists assert (springboot2 `test_cli.sh` pattern).

---

### SM-DOC-01 — Severity: P3 (low)

- **Area:** Requirements / modular inventory  
- **Status:** open  
- **Location:** `docs/requirements/requirement-shell-modular-function-design.md` (live inventory)  
- **Description:** If inventory lists `util_resolve_storage` as Implemented without call sites, that is dual-truth vs disk.  
- **Suggestion:** Re-read modular Implementation Notes; mark storage helper **Gap / reserved** or **Implemented** only after wire.

---

### SM-SEC-01 — Severity: P3 (informational)

- **Area:** Integrity trust  
- **Status:** open (known class INC-20260713-003 style)  
- **Location:** help Environment `CHECKSUM`; companion same-origin  
- **Description:** Same-channel SHA-256 is byte consistency, not authenticity/signing — product already separates automatic companion vs optional pin; ensure README/SECURITY wording does not overclaim (spot-check on release).  
- **Suggestion:** Keep trust bounds in SECURITY.md; do not list CHECKSUM in help as if required for users (already install-path only — confirm help/about).

---

## Non-findings (explicitly OK)

| Check | Result |
|-------|--------|
| Basename bootstrap gate | **Absent** — always `app_main "$@"` |
| Empty argv → help | **No** — Type O install-ensure |
| Download fail exit | Propagated via `return`/`exit $?` paths |
| Downgrade without force | Non-zero + `downgrade_blocked` |
| Uninstall JSON without force | Fail-closed `confirm_required` |
| `out_json_error` channel | stderr |
| Reverse-copy of domain into A | N/A (Type 0 only product) |
| Test suite | Green at review time |

---

## Priority remediation order

1. **SM-STOR-01** + **SM-STOR-02** — wire storage or document Gap; add requirement if claiming multi-user scratch  
2. **SM-TEST-01** — follow storage wire with tests  
3. **SM-HYG-01** / **SM-ID-01** — hygiene + identity hardcode  
4. **SM-DOC-01** / **SM-OUT-01** / **SM-SEC-01** — notes and trust wording  

---

## Related

| Artifact | Role |
|----------|------|
| `./selfmanaged` | Ship unit under review |
| `docs/requirements/` | Product law |
| `docs/incidents/` | Process failures (bootstrap basename, set -u, checksum UX, …) |
| `tests/run.sh` | Regression baseline |
| Sibling springboot2 storage fixes (2026-07-15) | Reference implementation for SM-STOR-01 |

---

**Written by:** Grok  
**Review status:** Findings open — no code changes in this pass (review-only).
