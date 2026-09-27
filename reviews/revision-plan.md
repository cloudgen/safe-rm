# Revision plan — selfmanaged

Living backlog of **bootstrap origin** improvements.  
**Product:** selfmanaged Type 0 CLI · **Class:** bootstrap (no domain SSOT)  
**Source reflection:** specialize gitlab-nginx from selfmanaged (2026-08-11)  
**Last update:** 2026-09-06 (SM-REV-06 / TP-JSON-RAW-01 **done**)

Status: **done** · **open** · **deferred**

---

## Closed in 1.2.2 (priority 1–3)

| # | Item | Status | Evidence |
|---|------|--------|----------|
| **1** | **GLOBAL_BIN test isolation** — host `/usr/local/bin/${APP_NAME}` must not shadow lifecycle CI | **done** | `tests/helpers.sh` `ci_isolated_env`; all lifecycle/cli env blocks export `GLOBAL_BIN=${CI_GLOBAL_BIN}`; Case C still uses dedicated `_global_bin` |
| **2** | **Specializee contract in product law** — empty argv, channel, `out_*`, root host-mutation, help order, REQ retarget hygiene | **done** | `requirement-shell-cli-zero-arguments` §2.2.1 · `requirement-shell-cli-interface` §2.5 / §2.5.1 · modular-design domain/shim note · output `@key` specializee note |
| **3** | **Ship-unit injection anchors** for A→B specialize | **done** | `src/selfmanaged`: `DOMAIN_HELP_ROWS`, `DOMAIN_ABOUT_FIELDS`, `DOMAIN_DISPATCH_FLAGS`, `DOMAIN_DISPATCH_COMMANDS`, `DOMAIN_DISPATCH_ROUTES` |

**Baseline after 1.2.2:** `PASS=102 FAIL=0 SKIP=0` (`./tests/run.sh`, 2026-08-11).

---

## Residual backlog (from same reflection)

| ID | Priority | Item | Status | Notes |
|----|----------|------|--------|-------|
| SM-REV-04 | medium | Specializee **tests/README porting checklist** (rename app, GLOBAL_BIN, domain suite) | **done** (1.2.2) | See `tests/README.md` § Specializee porting |
| SM-REV-05 | medium | Origin-review lesson: never bulk-sed org names in CIAO URLs when retargeting REQs | **done** (2026-08-11) | Captured as `L-REQ-CIAO-URL-01` in `reviews/lessons.md` |
| SM-REV-06 | low | TP-JSON-RAW-01 suite assertion for `out_json` `@key` | **done** (1.2.4) | `tests/test_cli.sh`; closes SM-PLAN-01 |
| SM-REV-07 | low | Optional GitHub Action template comment for specializees | **deferred** | Selfmanaged already has `.github/workflows/ci.yml` |
| SM-REV-08 | n/a | Domain verbs inside selfmanaged | **rejected** | Would pollute bootstrap; reverse-copy risk |

---

## Non-goals

- Rewriting Type O empty argv to domain setup  
- Reverse-copy of specialized sibling domain into A  
- Auto-detect “test mode” inside product install logic (tests isolate env; product keeps multi-install semantics)

---

## Publish checklist (when cutting a release)

1. Align `VERSION` / README badge / CHANGELOG / SECURITY / `selfmanaged.sha256`  
2. `./tests/run.sh` green  
3. Update this plan + `what-to-review.md` last date  
4. Commit + vault-bound push as **cloudgen** (repository-user)
