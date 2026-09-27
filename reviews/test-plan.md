# Test plan — selfmanaged

Maps **baseline coverage** and **finding lock-in (TP-*)** to `tests/`.  
**Suite entry:** `./tests/run.sh`  
**Last update:** 2026-09-17 (TP-SI-01..06 **have**)

Status: **have** = automated today · **TODO** = needed · **n/a** = not applicable / product choice

---

## Baseline coverage (Type 0)

| Area | Coverage | Evidence |
|------|----------|----------|
| Syntax | have | `sh -n selfmanaged` |
| Companion digest matches ship unit | have | `selfmanaged.sha256` check in suite |
| version / help / about human + JSON | have | `tests/test_cli.sh` |
| help must not list CHECKSUM | have | test_cli |
| about must not include CHECKSUM | have | test_cli |
| about storage fields | **have** | effective_storage / storage_dir |
| Storage isolation / dir exists | **have** | test_cli after SM-STOR wire |
| Unknown command fail-closed | have | test_cli |
| quiet / env -u HOME | have | test_cli |
| Zero-arg Type O paths | have | test_cli + lifecycle |
| self-uninstall --json without --force | have | confirm_required |
| Install / re-install idempotent | have | test_install_lifecycle |
| version-check / self-update / checksum / downgrade | have | lifecycle |
| GLOBAL_BIN isolate under multi-install hosts | **have** | `ci_isolated_env` (1.2.2) |

**Baseline result (2026-07-16 origin fix):** PASS=102 FAIL=0 SKIP=0  
**Baseline re-run (2026-07-19 product review):** PASS=102 FAIL=0 SKIP=0  
**Baseline re-run (2026-08-11 1.2.2):** PASS=102 FAIL=0 SKIP=0  
**Baseline re-run (2026-09-02 1.2.3):** PASS=108 FAIL=0 SKIP=0  
**Baseline re-run (2026-09-06 1.2.4):** PASS=117 FAIL=0 SKIP=0  
**Baseline re-run (2026-09-27 1.3.1):** PASS=142 FAIL=0 SKIP=0

---

## safe-rm domain (`TP-SRM-*`)

**Suite entry:** `./tests/run_dry_run.sh`  
**Ship unit:** `src/safe-rm`  
**Law:** `requirement-domain-safe-rm`  
**Mode:** `--dry-run` only. The suite does not call a real remove.

| ID | Coverage | Evidence |
|----|----------|----------|
| `TP-SRM-01` .. `TP-SRM-04` | Syntax, version, help, digest | `tests/run_dry_run.sh` |
| `TP-SRM-05` .. `TP-SRM-06` | Allowed temporary path is not removed | same |
| `TP-SRM-07` .. `TP-SRM-13` | Login home, `/home`, `/usr/bin`, `/`, mixed command | same |
| `TP-SRM-14` .. `TP-SRM-19` | JSON, usage, unknown command, about, quiet | same |

---

## Finding-linked TP rows

| TP-ID | Related finding / lesson | Intent | Status | Target / notes |
|-------|--------------------------|--------|--------|----------------|
| TP-STOR-01 | SM-STOR-01, L-STOR-01 | Storage resolver invoked; root exists | **have** | test_cli about + dir exists |
| TP-STOR-02 | SM-STOR-02 | Product law documents storage | **have** | requirement-shell-cli-storage.md |
| TP-STOR-03 | SM-TEST-01 | Isolation: path under APP_NAME + user | **have** | test_cli isolation |
| TP-HYG-01 | SM-HYG-01 | Companion `*.tmp` not present | **have** | removed; gitignore `*.tmp` |
| TP-ID-01 | SM-ID-01 | `APP_NAME="…"` hard-assign | **have** | static + extractors |
| TP-OUT-01 | SM-OUT-01 | about JSON storage fields | **have** | test_cli |
| TP-CSUM-01 | SM-SEC-01, L-CSUM-01 | help/about never advertise CHECKSUM | **have** | test_cli |
| TP-BOOT-01 | L-BOOT-01 | Always reach app_main under pipe | **have** | Indirect via zero-arg |
| TP-UNIN-01 | L-UNIN-01 | self-uninstall --json no force → confirm_required | **have** | test_cli + lifecycle |
| TP-SETU-01 | L-SETU-01 | env -u HOME still works | **have** | test_cli |
| TP-CITE-TERM-01 | L-CITE-TERM-01 | Bootstrap footer cites requirements | **have** | static fix |
| TP-JSON-RAW-01 / TP-CLI-12 | L-JSON-RAW-01, SM-PLAN-01 | `out_json` `@key` raw nested | **have** | `tests/test_cli.sh` — unquoted array/object; string keys stay quoted; JSON=0 no-op |
| TP-CS-01 | coding-style REQ | No `util_sudo` / command-position `sudo` | **have** | `tests/test_cli.sh` static |
| TP-ISO-GLOBAL-01 | SM-REV-01 / gitlab-nginx specialize | Isolated GLOBAL_BIN for lifecycle | **have** | helpers + lifecycle/cli env |
| TP-INST-MAYBE-01 / TP-LC-10 | SM-BUG-01, L-INST-MAYBE-01 | Not installed + QUIET/JSON **through `inst_maybe_install`** must place or fail closed (not `return 0` skip) | **have** | `tests/test_install_lifecycle.sh` |
| TP-SI-01 | shell-cli-self-install | `self-install` with script `$0` copies; dead `SCRIPT_URL` still places | **have** | `tests/test_cli.sh` |
| TP-SI-02 | shell-cli-self-install | Local dest mode **0700** | **have** | `tests/test_cli.sh` |
| TP-SI-03 | shell-cli-self-install | NI empty argv is self-install (copy), not help | **have** | `tests/test_cli.sh` |
| TP-SI-04 | shell-cli-self-install | Interpreter `$0` (`sh -s`) uses channel download | **have** | `tests/test_cli.sh` |
| TP-SI-05 | shell-cli-self-install | Second `self-install` already-installed no-op | **have** | `tests/test_cli.sh` |
| TP-SI-06 | shell-cli-self-install | Help lists `self-install` | **have** | `tests/test_cli.sh` |
| TP-SI-07 | L-DEST-0711-01 | No live `chmod +x`; `inst_cli_dest_mode` names 0755/0700 | **have** | `tests/test_cli.sh` |
| TP-SI-08 | L-DEST-0711-01 | Isolated GLOBAL_BIN dest **0755**; leftover **0711** healed | **have** | `tests/test_cli.sh` |

---

## Rules

1. Closing a **bug** finding updates the matching TP to **have**.  
2. Do not mark TP **have** without a suite assertion (or documented static fix for cite/ID).  
3. Bootstrap project: no domain TP suite required.  
