# Report: selfmanaged 1.2.2 specializee revision

**Date:** 2026-08-11  
**Scope:** Reflection items 1–3 from gitlab-nginx specialize; update revision plan  
**Version:** 1.2.2

## Delivered

| # | Item | Result |
|---|------|--------|
| 1 | GLOBAL_BIN test isolation | `ci_isolated_env` + lifecycle/cli env blocks |
| 2 | Specializee contract in REQs | zero-arg §2.2.1; CLI interface §2.5 / §2.5.1; modular + output notes |
| 3 | Ship-unit injection anchors | DOMAIN_HELP_ROWS / ABOUT_FIELDS / DISPATCH_* |

## Baseline

```
PASS=102 FAIL=0 SKIP=0
RESULT: OK
```

## Residual

- SM-PLAN-01 / TP-JSON-RAW-01 still TODO  
- SM-REV-05 (lesson: no bulk CIAO org sed) open for next origin review  

## Verdict

**Pass** — 1.2.2 ready for commit when owner requests push.
