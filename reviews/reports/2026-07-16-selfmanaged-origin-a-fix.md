# Report: origin A findings fix — selfmanaged 1.1.0

**Date:** 2026-07-16  
**Mode:** Implement (authorized: “fix all of origin a”)  
**Prior:** product reviews 2026-07-15/16 + bootstrap-origin-from-timer  
**Baseline after fix:** PASS=102 FAIL=0 SKIP=0  

---

## Summary

Closed **all open origin-A findings** on selfmanaged without reverse-copying timer domain.

| ID | Severity | Resolution |
|----|----------|------------|
| SM-STOR-01 | P1 bug | `util_resolve_storage` mkdir all tiers; wired from `app_main` (`EFFECTIVE_STORAGE_DIR` + `TMPDIR`) |
| SM-STOR-02 | P2 | Added `requirement-shell-cli-storage.md` + registry row |
| SM-TEST-01 | P2 | about JSON storage fields + isolation/dir-exists tests |
| SM-OUT-01 | P3 | about human + JSON `effective_storage` / `storage_dir` |
| SM-DOC-01 | P3 | Modular inventory marks storage **wired** + storage REQ cite |
| SM-ID-01 | P3 | `APP_NAME="selfmanaged"` hard-assign |
| SM-HYG-01 | P3 | Removed `selfmanaged.sha256.tmp` |
| T-CITE / L-CITE-TERM-01 | suggestion | Bootstrap footer cites live requirements only |
| L-JSON-RAW-01 | latent | `out_json` `@key` raw nested JSON ported |
| SM-SEC-01 | info | Spot-checked SECURITY — integrity wording (no signing overclaim); suite still blocks CHECKSUM in help/about |

**Verdict:** **Pass** — origin A open items closed; suite green.

---

## Evidence (disk)

- `util_resolve_storage` called from `app_main` and defensively from `app_about`  
- `grep '^APP_NAME="'` → `APP_NAME="selfmanaged"`  
- Footer cites `requirement-shell-cli-zero-arguments` + `requirement-shell-cli-interface`  
- Registry: 9 Active REQs including storage  
- Companion digest refreshed (hash-only format for suite)  

---

## Lessons / TP

| Item | Status |
|------|--------|
| L-STOR-01 | **Closed** |
| L-STOR-02 | **Closed** |
| L-ID-01 | **Closed** |
| L-HYG-01 | **Closed** |
| L-CITE-TERM-01 | **Closed** |
| L-JSON-RAW-01 | **Closed** (capability present) |
| TP-STOR-01/02/03 | **have** (about + isolation tests) |
| TP-ID-01 | **have** |
| TP-CITE-TERM-01 | **have** |
| TP-JSON-RAW-01 | **have** (implementation present; Type 0 has no nested consumer) |

---

## Not done (correctly)

- No domain law / domain verbs on selfmanaged  
- No reverse-copy of `./timer`  
- Optional re-specialize of timer from fixed A (user may request separately)  
