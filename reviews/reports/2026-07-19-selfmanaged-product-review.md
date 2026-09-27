# Product review — selfmanaged

| Field | Value |
|-------|--------|
| **Date** | 2026-07-19 |
| **Scope** | Full Type 0 product surface (ship unit, tests, requirements registry, user docs, reviews plan) |
| **Ship unit** | `./selfmanaged` (`VERSION="1.2.0"`, `APP_NAME="selfmanaged"`) |
| **Class** | software-development · **bootstrap project** (no domain SSOT) |
| **Baseline suite** | `./tests/run.sh` → **PASS=102 FAIL=0 SKIP=0** |
| **Prior lessons** | Loaded `reviews/lessons.md` (all L-* re-checked) |
| **Reviewer** | Grok product review (`skill-product-review`) |
| **Verdict** | **Pass with nits** |

---

## 1. Pre-flight

| # | Check | Result |
|---|--------|--------|
| P1 | `docs/requirements/index.md` | **10** Active rows: **1 class** + **9 shell** (storage included); no domain SSOT — honest bootstrap |
| P2 | Ship unit + companion digest | `selfmanaged.sha256` **matches** `./selfmanaged` |
| P3 | `reviews/lessons.md` | Loaded; closed lessons re-verified via suite / static |
| P4 | `./tests/run.sh` | **OK** PASS=102 |
| P5 | Bootstrap class | No domain REQs; Type 0 only |

---

## 2. Lessons re-check

| L-ID | Open? | 2026-07-19 evidence |
|------|-------|---------------------|
| L-STOR-01 / L-STOR-02 | Closed | `util_resolve_storage` wired in `app_main`; about JSON storage fields; suite storage tests PASS |
| L-BOOT-01 | Closed | Footer always `app_main "$@"`; no basename gate |
| L-TYPEO-01 | Closed | Zero-arg suite paths PASS |
| L-UNIN-01 | Closed | confirm_required / no fake success PASS |
| L-SETU-01 | Closed | `env -u HOME version` PASS |
| L-CSUM-01 | **Partial** | help/about omit CHECKSUM (suite); companion transparency tests PASS — keep SECURITY wording vigilance |
| L-CITE-01 / L-CITE-TERM-01 | Closed | Ship unit cites live `requirement-shell-*` only (no template/skill paths) |
| L-HYG-01 | Closed | No `*.tmp` companions at root |
| L-ID-01 | Closed | `APP_NAME="selfmanaged"` hard-assign present |
| L-JSON-RAW-01 | Closed impl / **TP TODO** | Code has `@key` path; **TP-JSON-RAW-01** still suite **TODO** (SM-PLAN-01) |

---

## 3. Strengths

1. **Green suite** — 102 automated assertions covering Type O, install lifecycle, checksum pin paths, storage, quiet/HOME, uninstall force policy.  
2. **Version SSOTs aligned** — project-target-version README badge, runtime `VERSION`, CHANGELOG `[1.2.0]`, SECURITY current all **1.2.0**.  
3. **Product law inventory** — nine shell REQs + new class law file (registry updated; class gate remediated this session).  
4. **Integrity story** — companion digest match; automatic checksum transparency covered in lifecycle tests; CHECKSUM excluded from help/about.  
5. **Bootstrap honesty** — no invented domain surface; modular Type 0 prefixes; storage as scratch isolation not domain ops.  
6. **Reviews surface** — living plan + lessons + prior reports; `reviews/` not gitignored.

---

## 4. Findings

### SM-PLAN-01 — P3 (open, carried)

| Field | Detail |
|-------|--------|
| **Title** | `out_json` `@key` raw nested lacks suite lock-in |
| **Evidence** | `reviews/test-plan.md` TP-JSON-RAW-01 **TODO**; impl present (L-JSON-RAW-01 closed for code) |
| **Risk** | Regression of nested JSON without CI detection |
| **TP** | TP-JSON-RAW-01 |
| **Action** | Add assertion in `tests/test_cli.sh` (or mark n/a with rationale) |

### SM-OPS-SSH-01 — P2 (environment / release ops; not ship-unit defect)

| Field | Detail |
|-------|--------|
| **Title** | Active SSH user profile cannot GitHub; mismatch with repository-user |
| **Evidence** | Pre-git report: active **drsense** → DENIED; git-capable **cloudgen** → `cloudgen`, **wilgat** → `Wilgat`; product `REPO_USER=cloudgen` |
| **Risk** | `git fetch`/`push` fail on default identity; teams may not see which profile to activate |
| **Harness** | `skill-ssh-user-profile` §3a pre-git report (added 2026-07-19) |
| **Action** | Activate the SSH profile that probes as the repository user, with user confirm, before remote git |

### SM-DOC-PLAN-01 — P3 (nit)

| Field | Detail |
|-------|--------|
| **Title** | Living plan still says “9 shell REQs” / “nine REQs” in places |
| **Evidence** | `what-to-review.md` P1; index now has class + 9 shell |
| **Action** | Refresh what-to-review / AGENTS maps when committing class REQ |

### SM-REQ-WIP-01 — P3 (process)

| Field | Detail |
|-------|--------|
| **Title** | Uncommitted requirements hygiene (class file, CIAO renumber, DoD) |
| **Evidence** | `git status`: modified shell REQs + untracked `requirement-class-software-dev.md` |
| **Risk** | Class gate / CIAO fixes not on origin until commit |
| **Action** | Commit with explicit **docs-only / no-bump** or product **1.2.1** if desired |

---

## 5. Explicit non-findings (OK)

| Area | Note |
|------|------|
| Ship unit template/skill citation | None found |
| Domain REQ invent | None — bootstrap correct |
| Digest stale | No |
| Version drift target vs runtime | No |
| Storage dead code | Resolved (prior SM-STOR) |

---

## 6. Test-plan deltas

| TP-ID | Status after this review |
|-------|---------------------------|
| Baseline Type 0 | **have** — re-run PASS=102 |
| TP-JSON-RAW-01 | Still **TODO** (SM-PLAN-01) |
| New TP for SSH profile | **n/a** product suite — ops harness / pre-git report (not ship unit) |

---

## 7. Pre-git SSH profile report (ops context)

```text
Product repository-user: cloudgen
Active profile:          drsense  (default ~/.ssh)
Active current-git-user: DENIED
Git-capable:             cloudgen → cloudgen (matches REPO_USER); wilgat → Wilgat
Recommended activate:    cloudgen
```

---

## 8. Verdict

**Pass with nits**

- Product ship unit and automated Type 0 surface are **healthy** at **1.2.0**.  
- Remaining product-plan debt: **SM-PLAN-01** (JSON `@key` test).  
- Release/git remote ops blocked until **SSH profile activate** (SM-OPS-SSH-01), not a code bug.  
- Commit pending requirements/class work when ready.

### Recommended next steps

1. User-confirm **activate cloudgen** SSH profile for git remote.  
2. Implement **TP-JSON-RAW-01** or close as n/a.  
3. Commit requirements + class REQ (+ optional reviews report).  
4. Refresh what-to-review P1 counts (10 REQs = 1 class + 9 shell).

---

**No product code changed in this review run.**
