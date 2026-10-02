# Reviews index — safe-rm

**Registry** of review plan artifacts and run reports. Keep rows in sync with disk.  
**Updated:** 2026-10-02 (menu language coverage; ship unit 1.0.20)

## Plan artifacts

| Artifact | Path | Role |
|----------|------|------|
| What to review | `what-to-review.md` | Living checklist |
| Revision plan | `revision-plan.md` | Closed Type 0 origin backlog |
| Test plan | `test-plan.md` | TP-* lock-in |
| Lessons | `lessons.md` | L-* re-check |
| README | `README.md` | Surface rules |

## Reports

| Date | File | Scope | Baseline | Verdict |
|------|------|-------|----------|---------|
| 2026-10-02 | `reports/2026-10-02-menu-language-coverage.md` | front **5** menu language | dry-run PASS=760 FAIL=0 | **Closed** (ship unit 1.0.20) |
| 2026-09-27 | `reports/2026-09-27-safe-rm-main-menu-vs-selfmanaged.md` | safe-rm numbered main menu | probes; later `tests/run_dry_run.sh` | **Closed** (menu shipped the same day) |
| 2026-09-27 | `reports/2026-09-27-checklist-temp-file-system-cache-folder.md` | safe-rm cache folder vs storage law | dry-run PASS=200 | **Pass** |

## Open items summary

| ID | Severity | Status | One-line |
|----|----------|--------|----------|
| L-REQ-CIAO-URL-01 | P3 | open | Do not bulk-rename CIAO org URLs when retargeting product identity |
| L-CSUM-01 | partial | vigilance | Companion digest is the check; help and about do not advertise `CHECKSUM` |
| L-MENU-01 | bug | **closed** (2026-09-27) | `src/safe-rm` opens the numbered menu on a terminal; pipe / quiet / json still place |

## Notes

- Product: **safe-rm**. Ship unit `src/safe-rm`. Version SSOT `VERSION="1.0.20"`.  
- Domain proof: `tests/run_dry_run.sh`.  
- One Active domain SSOT: `requirement-domain-safe-rm`.  
