# What to review — selfmanaged

**Living checklist** (review plan). Product: **selfmanaged** Type 0 bootstrap CLI.  
**Class:** Bootstrap project — no Active domain requirements expected.  
**Always load first:** `reviews/lessons.md`

**Last plan update:** 2026-09-27 (main menu vs selfmanaged; L-MENU-01)

---

## Pre-flight

| # | Check | Notes |
|---|--------|--------|
| P1 | Read `docs/requirements/index.md` (live law only) | **1 class** + **9 shell** REQs incl. **storage**; no domain SSOT |
| P0 | Pre-git SSH profile report if remote git | Active profile + git-capable candidates vs `REPO_USER` |
| P2 | Confirm ship unit `src/selfmanaged` + companion `src/selfmanaged.sha256` | Digest match via tests |
| P3 | Load `reviews/lessons.md` and re-check every open L-* | Mandatory |
| P4 | Run `./tests/run.sh` for baseline | Record PASS/FAIL in report |
| P5 | Confirm product class still bootstrap (no invented domain REQ) | Owner may override |

---

## Product law surfaces

| Surface | Path | Review focus |
|---------|------|--------------|
| CLI interface | `requirement-shell-cli-interface.md` | Commands, flags, dispatch; specializee §2.5.1 |
| Zero-arg Type O | `requirement-shell-cli-zero-arguments.md` | Empty argv = install-ensure, not help; specializee §2.2.1 |
| Self-management | `requirement-shell-self-management.md` | version-check, self-update, self-uninstall, about |
| Output SSOT | `requirement-shell-output-requirements.md` | `out_*`; JSON errors on stderr |
| Modular design | `requirement-shell-modular-function-design.md` | Prefixes; inventory honesty vs disk |
| Idempotency | `requirement-shell-idempotency.md` | Re-run ensure safety |
| Interactive modes | `requirement-shell-interactive-vs-noninteractive.md` | TTY vs pipe / quiet / json |
| Automatic checksum | `requirement-shell-automatic-checksum.md` | Companion primary; CHECKSUM not help/about |
| CLI storage | `requirement-shell-cli-storage.md` 1.1.0 | Per-login per-process cache folder; persistence `${HOME}/.local/${APP_NAME}`; silent tier miss; about labels |

**Out of scope unless added:** Domain requirements / domain verbs (not bootstrap product law).

---

## High-risk paths (ship unit)

| Path / symbol | Risk | Prior IDs |
|--------------|------|-----------|
| `app_main "$@"` entry (end of file) | Basename gate under pipe | L-BOOT-01 |
| Empty argv branch | Help instead of install-ensure | L-TYPEO-01 |
| `inst_maybe_install` quiet/json | Success without placing when not installed | L-INST-MAYBE-01, SM-BUG-01 |
| `util_resolve_storage` | Dead code; tiers 1–2 no create; unused in main | L-STOR-01, SM-STOR-01 |
| Install / self-update integrity | Companion vs pin trust bounds | L-CSUM-01, SM-SEC-01 |
| `self-uninstall` non-force | Fake JSON success cancel | L-UNIN-01 |
| `set -u` defaults (`HOME`, `IS_ROOT`, `SH`, storage tier 3) | nounset crashes | L-SETU-01 |
| Identity extractors (`APP_NAME` / `VERSION`) | Grep/SSOT shape | SM-ID-01 |
| Repo root `*.tmp` companions | Hygiene / accidental ship | SM-HYG-01 |

---

## Tests surface

| Check | Path |
|-------|------|
| Suite entry | `tests/run.sh` |
| CLI surface | `tests/test_cli.sh` |
| Install lifecycle | `tests/test_install_lifecycle.sh` |
| Helpers | `tests/helpers.sh` (**GLOBAL_BIN** isolate) |
| TP registry | `reviews/test-plan.md` |
| Revision plan | `reviews/revision-plan.md` |

---

## Main menu vs selfmanaged (L-MENU-01)

Reference is selfmanaged **1.4.0** (`selfmanaged/src/selfmanaged`), not `src/selfmanaged` **1.3.1**.

| Check | Pass when |
|-------|-----------|
| Interactive empty argv | Numbered menu. No install prompt and no place |
| Pipe / quiet / json empty argv | Still `inst_self_install` (TP-SI-03) |
| Front board | Header nametag, **1** remove-guard, **8** self-management, **9** Exit. No lifecycle verb and no `rm` row on this board |
| Under **8** | **82–87** and **0** Back. **81** not printed |
| Domain | `rm` on its own front category, not beside **8** |
| Under **11** | Subfolders of the current path as **1…N**, then **custom-path**, then **0** Back. Files and dotfolders stay off the list |
| `menu` / `main` | Same board on a terminal. Help off a terminal |
| Bad pick | `out_error` and reprint. Not `out_die` |
| After a leaf | Front board shows again |

---

## Product user / integrity docs

| Check | Path |
|-------|------|
| README install channel truth | `README.md` |
| SECURITY trust bounds (no overclaim signing) | `SECURITY.md` |
| CHANGELOG when releasing fixes | `CHANGELOG.md` |
| Companion digest present | `selfmanaged.sha256` |

---

## Explicit non-goals for default full Type 0 review

- Inventing domain REQs to “look complete”  
- Reverse-copy of specialized sibling domain into selfmanaged  
- Treating `docs/skills` / templates as product behavioral authority  
- Claiming ISO/OWASP certification from templates alone  

---

## Publish steps (after a run)

1. Write `reviews/reports/YYYY-MM-DD-<scope>.md`  
2. Update `reviews/index.md`  
3. Merge new failure modes into `reviews/lessons.md`  
4. Add/update TP rows in `reviews/test-plan.md`  
5. Adjust this file if a permanent surface appeared  
