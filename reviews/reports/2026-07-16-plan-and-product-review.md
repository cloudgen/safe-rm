# Report: plan review + product review — selfmanaged 1.1.0

**Date:** 2026-07-16  
**Mode:** Plan review (living review plan + requirements/plan quality) + full Type 0 product re-check  
**Reviewer:** product-review skill / council  
**Product:** selfmanaged `VERSION="1.1.0"`  
**Ship unit:** `./selfmanaged` + companion `./selfmanaged.sha256`  
**Method:** disk read; `./tests/run.sh`; lesson walk; plan-and-requirements checklist; high-risk path spot-checks  
**Baseline:** **PASS=102 FAIL=0 SKIP=0** (2026-07-16)  
**Prior context:** origin-A fix report (same day); uncommitted working tree holds storage wire + `reviews/` tree  

---

## Summary

Post–origin-A selfmanaged is in good shape for a Type 0 bootstrap CLI: storage is wired, nine Active shell requirements match disk, suite is green, and high-risk lesson paths re-check clean. The living review plan (`what-to-review.md`, `test-plan.md`, `lessons.md`) is largely accurate and usable. Two honesty/inventory gaps remain: **TP-JSON-RAW-01** is marked **have** without a suite assertion (violates this project’s own test-plan rule), and tracked **AGENTS.md** still inventories **eight** shell REQs while disk has **nine** (missing `requirement-shell-cli-storage.md`). No P0/P1 product bugs found on this pass.

**Verdict:** **Pass with nits** — ship unit + product law OK; plan/inventory nits open (not ship blockers).

---

## Plan review

### Plan quality (`reviews/` living plan)

| Check | Result |
|-------|--------|
| Pre-flight surfaces listed | OK — 9 REQs incl. storage; bootstrap class explicit |
| High-risk paths map to L-* / SM-* | OK — storage, Type O, uninstall JSON, set -u, checksum UX, hygiene, APP_NAME |
| Lessons mandatory load | OK — table complete; Open? honest for L-CSUM-01 **Partial** |
| Test-plan baseline vs suite | OK — PASS=102 matches run |
| TP rows for closed bugs | Mostly OK — STOR/ID/HYG/UNIN/SETU/CSUM present |
| TP honesty rule (suite or documented static) | **Gap** — TP-JSON-RAW-01 (see finding SM-PLAN-01) |
| Explicit non-goals | OK — no invented domain; no reverse-copy |
| Publish steps documented | OK |
| `reviews/` not gitignored | OK — `git check-ignore` clean |
| Plan placeholders / TBD | None found in plan files |

### Requirements / plan-and-requirements (uncommitted law surface)

| Check | Result |
|-------|--------|
| Registry ↔ files | OK — 9 `requirement-shell-*.md`; index lists storage |
| New storage REQ complete | OK — purpose, normative tiers, wire, about fields, Protection Rule; no TODO/TBD |
| Harness path leak in versioned REQs | OK — related artifacts stay peer REQs / product paths |
| Modular inventory honesty | OK — `util_resolve_storage` marked wired + storage REQ cite |
| Output REQ `@key` note | OK — documented; implementation present in `out_json` |
| README requirements folder count | OK — nine Active |
| AGENTS.md inventory | **Stale** — still “eight” (see SM-DOC-01) |

### Plan review verdict

| Gate | Decision |
|------|----------|
| Living review plan ready for next full run? | **Approve** after TP-JSON-RAW honesty fix (nit) |
| Requirements surface ready? | **Approve** (disk + index); fix AGENTS inventory when convenient |
| Product implement blocked by plan gaps? | **No** |

---

## Product review

### Lessons re-check (mandatory)

| L-ID | Open? (prior) | This run evidence | Result |
|------|---------------|-------------------|--------|
| L-STOR-01 | Closed | `util_resolve_storage` mkdir all tiers; `app_main` sets `EFFECTIVE_STORAGE_DIR` + `TMPDIR`; `app_about` JSON fields | **Closed** reconfirmed |
| L-STOR-02 | Closed | `requirement-shell-cli-storage.md` + index row | **Closed** reconfirmed |
| L-BOOT-01 | Closed | Footer always `app_main "$@"`; no basename gate | **Closed** reconfirmed |
| L-TYPEO-01 | Closed | Empty argv → install-ensure (suite + manual zero-arg) | **Closed** reconfirmed |
| L-UNIN-01 | Closed | suite: confirm_required, no fake success | **Closed** reconfirmed |
| L-SETU-01 | Closed | `env -u HOME` version exit 0 (suite + manual) | **Closed** reconfirmed |
| L-CSUM-01 | Partial | help/about omit CHECKSUM; SECURITY integrity wording no signing overclaim | **Partial** — vigilance only |
| L-CITE-01 | Closed | ALIGNMENT cites live requirement-shell-* | **Closed** reconfirmed |
| L-HYG-01 | Closed | no root `*.tmp` | **Closed** reconfirmed |
| L-ID-01 | Closed | `APP_NAME="selfmanaged"` hard-assign | **Closed** reconfirmed |
| L-CITE-TERM-01 | Closed | footer cites requirement-shell-cli-* only | **Closed** reconfirmed |
| L-JSON-RAW-01 | Closed | `out_json` `@*` branch present | **Closed** (capability); TP lock-in still soft — SM-PLAN-01 |

### High-risk paths (ship unit)

| Path | Result |
|------|--------|
| `app_main "$@"` entry | Always runs |
| Empty argv branch | Type O ensure; not help |
| `util_resolve_storage` | Wired; create fail-closed |
| Install integrity / CHECKSUM UX | Suite green; not in help/about |
| self-uninstall non-force JSON | confirm_required |
| set -u defaults | HOME / storage tiers OK |
| APP_NAME / VERSION extractors | Hard-assign present |
| Companion digest | Suite match |

### Strengths

| Area | Notes |
|------|--------|
| Suite lock-in | 102 automated assertions including storage isolation |
| Storage law + wire | Resolver, main export, about diagnostics aligned |
| Bootstrap discipline | No domain REQ invention; origin-A closed without reverse-copy |
| Output SSOT | `out_*` / JSON stderr errors preserved |
| Review surface | Root `reviews/` peer-of-tests pattern in place |

### Findings

### SM-PLAN-01 — Severity: P3 (nit)
- **Area:** review plan / test-plan honesty  
- **Status:** open  
- **Location:** `reviews/test-plan.md` → TP-JSON-RAW-01  
- **Description:** Row is **have** with notes “implementation present; Type 0 has no nested consumer”. Project rule: do not mark TP **have** without a suite assertion (or documented static exception of the cite/ID class). Capability is real in `out_json`, but there is no `tests/` assertion for `@key` raw insert.  
- **Impact:** Plan overclaims lock-in; regression of `@key` could ship silently.  
- **Suggestion:** Either (a) add a small CLI/unit assertion that builds JSON with `@items` and greps unquoted array, or (b) reclassify status to **n/a** / **documented static** with explicit wording that suite coverage is not claimed.  
- **Cross-ref:** L-JSON-RAW-01; `requirement-shell-output-requirements.md`  

### SM-DOC-01 — Severity: P3 (nit)
- **Area:** agent inventory drift  
- **Status:** open  
- **Location:** `AGENTS.md` “Known requirements (live — selfmanaged)”  
- **Description:** Text still says **All eight** Active shell requirements and omits `requirement-shell-cli-storage.md`. Disk + `docs/requirements/index.md` correctly list **nine**.  
- **Impact:** Agents loading AGENTS.md first may invent wrong completeness or miss storage law.  
- **Suggestion:** Update count, table row, and “all eight” phrases to nine + storage REQ.  
- **Cross-ref:** L-STOR-02 closed on product law; inventory only  

### Non-findings (explicitly OK)

| Check | Result |
|-------|--------|
| Storage dead code | Fixed — wired from main + about |
| Type O empty argv | Install-ensure; suite locked |
| Basename / pipe gate | Absent; always `app_main` |
| Fake uninstall JSON cancel | Fail closed confirm_required |
| CHECKSUM in help/about | Absent |
| Domain REQ invention | None |
| Companion digest match | Suite PASS |
| `reviews/` gitignored | Not ignored |
| Storage REQ placeholders | None |
| Requirements harness navigation leak | Not observed in updated index/README |

### Priority remediation order

1. **SM-PLAN-01** — honest TP-JSON-RAW-01 (test or reword)  
2. **SM-DOC-01** — AGENTS.md nine-REQ inventory  
3. Optional vigilance: L-CSUM-01 wording if SECURITY/README ever claim authenticity/signing  

---

## Test-plan delta (this run)

| TP-ID | Prior | This review |
|-------|-------|-------------|
| TP-STOR-01/02/03 | have | reconfirmed have |
| TP-HYG-01, TP-ID-01, TP-OUT-01, … | have | reconfirmed |
| TP-JSON-RAW-01 | have (implementation present) | **Honesty gap** → SM-PLAN-01; leave open until fixed |

No new TP rows required for product bugs (none open at P0–P2).

---

## Scope / non-goals honored

- No domain requirements invented  
- No reverse-copy of specialized sibling products  
- Review did **not** modify ship unit (findings only)  
- Working tree remains dirty with prior origin-A implement + untracked `reviews/` — commit is a separate user decision  

---

## Related

| Artifact | Role |
|----------|------|
| `reviews/what-to-review.md` | Living checklist (plan) |
| `reviews/test-plan.md` | TP-* map |
| `reviews/lessons.md` | L-* re-check input |
| `reviews/reports/2026-07-16-selfmanaged-origin-a-fix.md` | Prior close-out |
| `docs/requirements/requirement-shell-cli-storage.md` | Storage law |
| `./tests/run.sh` | Baseline evidence |

**Written by:** product-review + plan-and-requirements review  
**Review status:** Ship unit **Pass**; plan/docs nits **open** (SM-PLAN-01, SM-DOC-01)  
