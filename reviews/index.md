# Reviews index — selfmanaged

**Registry** of review plan artifacts and run reports. Keep rows in sync with disk.  
**Updated:** 2026-09-27 (safe-rm 1.0.2 cache folder)

## Plan artifacts

| Artifact | Path | Role |
|----------|------|------|
| What to review | `what-to-review.md` | Living checklist |
| Revision plan | `revision-plan.md` | Bootstrap improvement backlog (1–3 closed) |
| Test plan | `test-plan.md` | TP-* lock-in |
| Lessons | `lessons.md` | L-* re-check |
| README | `README.md` | Surface rules |

## Reports

| Date | File | Scope | Baseline | Verdict |
|------|------|-------|----------|---------|
| 2026-07-15 | `reports/2026-07-15-selfmanaged-product-review.md` | Full Type 0 + storage emphasis | PASS=93 FAIL=0 | Open findings (storage debt) |
| 2026-07-16 | `reports/2026-07-16-selfmanaged-product-review.md` | Full re-check + plan bootstrap | PASS=93 FAIL=0 | **Revise** — prior opens confirmed |
| 2026-07-16 | `reports/2026-07-16-bootstrap-origin-from-timer.md` | Origin A from timer B report | A prior PASS=93 | **Block** — then fixed same day |
| 2026-07-16 | `reports/2026-07-16-selfmanaged-origin-a-fix.md` | Close all origin-A findings | PASS=102 FAIL=0 | **Pass** |
| 2026-07-16 | `reports/2026-07-16-plan-and-product-review.md` | Plan review + full Type 0 re-check | PASS=102 FAIL=0 | **Pass with nits** |
| 2026-07-19 | `reports/2026-07-19-selfmanaged-product-review.md` | Full Type 0 + class gate + ops SSH | PASS=102 FAIL=0 | **Pass with nits** |
| 2026-08-11 | `reports/2026-08-11-selfmanaged-specializee-revision.md` | GLOBAL_BIN tests + specializee contract + anchors | PASS=102 FAIL=0 | **Pass** (1.2.2) |
| 2026-09-02 | `reports/2026-09-02-bug-inst-maybe-install-quiet-json-skip.md` | Helper quiet/json skip; REQ coverage + human-facing | PASS=108 FAIL=0 | **Closed** (helper patched) |
| 2026-09-06 | `reports/2026-09-06-coverage-readme-req-tp-json-raw.md` | README voice; coding-style REQ; TP-JSON-RAW-01; command-line-for-normal-user-only | PASS=117 FAIL=0 | **Closed** (1.2.4) |
| 2026-09-27 | `reports/2026-09-27-safe-rm-main-menu-vs-selfmanaged.md` | safe-rm numbered main menu vs selfmanaged 1.4.0 | probes only; suite not re-run | **Revise** |
| 2026-09-27 | `reports/2026-09-27-checklist-temp-file-system-cache-folder.md` | safe-rm 1.0.2 cache folder vs grok-cli storage 1.4.0 | dry-run PASS=200; bootstrap PASS=142 | **Pass** |

## Open items summary

| ID | Severity | Status | One-line |
|----|----------|--------|----------|
| SM-BUG-01 | P1 (specializee / helper SSOT) | **closed** (2026-09-02) | Helper quiet/json now places or fail closed; TP-LC-10 |
| SM-PLAN-01 | P3 | **closed** (2026-09-06) | TP-JSON-RAW-01 suite lock-in in `tests/test_cli.sh` |
| SM-REV-05 | P3 | open | Lesson: no bulk-sed of CIAO org URLs when retargeting REQs |
| SM-OPS-SSH-01 | P2 | **closed** (1.2.1) | cloudgen profile activated to default `~/.ssh`; GitHub `Hi cloudgen!` |
| SM-DOC-PLAN-01 | P3 | **closed** (1.2.1) | Counts refreshed to 1 class + 9 shell |
| SM-REQ-WIP-01 | P3 | **closed** (1.2.1 release) | Class REQ + shell REQ hygiene in 1.2.1 commit |
| SM-DOC-01 | P3 | **closed** (2026-07-16) | AGENTS.md + docs maps list nine REQs incl. storage |
| SM-REV-01/02/03 | — | **closed** (1.2.2) | GLOBAL_BIN isolation; specializee contract; dispatch/help anchors |
| L-CSUM-01 | partial | vigilance | Suite OK; keep CHECKSUM trust wording honest |
| L-MENU-01 | bug | **closed** (2026-09-27) | `src/safe-rm` opens the numbered menu on a terminal; pipe / quiet / json still place |

## Notes

- Product class: **bootstrap project** (no domain SSOT); **software-development** class law Active.  
- Storage is wired Type 0 scratch isolation — not domain product ops.  
- Version **1.3.1** target/runtime/CHANGELOG/SECURITY aligned (2026-09-27). Ship unit `src/selfmanaged`; channel `SCRIPT_RELPATH` default `src/${APP_NAME}`. Self-install dest **0755** global / **0700** local; specializee **TP-SI-07** / **TP-SI-08**.  
- See **`revision-plan.md`** for specializee reflection backlog.  
