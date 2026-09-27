# Lessons — selfmanaged

**Prior-report failure modes** to re-check on every product review.  
**Mandatory load** before findings.  
**Last update:** 2026-09-17 (L-DEST-0711-01)

| L-ID | Failure mode | Re-check | Source | Open? |
|------|--------------|----------|--------|-------|
| L-DEST-0711-01 | Global dest `chmod +x` on `mktemp` 0600 mints **0711**; other logins cannot open shebang (`/bin/sh: Permission denied`) | No live `chmod +x` (**TP-SI-07**); isolated `GLOBAL_BIN` **0755** (**TP-SI-08**); specializees keep `inst_cli_dest_mode` | ollama-cli 1.5.1 `sudo curl \| sh` → `-rwx--x--x` | **Closed** (origin 1.3.0 dest mode + TP-SI-07/08) |
| L-INST-MAYBE-01 | First-install helper returns success under quiet/json without placing; peer REQ used to document that skip | Helper calls `inst_self_install` under QUIET/JSON; both REQs say the same; specializee copies of the helper must not skip | SM-BUG-01 | **Closed** (2026-09-02 helper + TP-LC-10) |
| L-REQ-CIAO-URL-01 | Bulk-sed of org names when retargeting REQs rewrites CIAO philosophy URLs (`cloudgen/ciao`) into product-channel identity | Grep REQs for `github.com/cloudgen/ciao` after retarget; never `s/cloudgen/<product>/g` over whole docs | SM-REV-05 | **Open** (process vigilance; teach on next origin review) |
| L-OPS-SSH-01 | Active ssh-user-profile GitHub DENIED while another profile is git-capable; default ≠ repository-user | Pre-git report: active profile + git-capable list; activate matching REPO_USER | SM-OPS-SSH-01 | **Closed** (2026-07-19 activate cloudgen) |
| L-STOR-01 | Storage resolver dead code; tiers 1–2 no mkdir; not called from main/about | Call sites of `util_resolve_storage`; mkdir all tiers; about JSON storage fields | SM-STOR-01 | **Closed** (2026-07-16 wire) |
| L-STOR-02 | No storage product law | `requirement-shell-cli-storage.md` + index row | SM-STOR-02 | **Closed** (2026-07-16) |
| L-BOOT-01 | Basename / `$0` APP_NAME gate blocks `curl\|sh` | End of ship unit always `app_main "$@"` | INC-20260712-001 | **Closed** (re-check still) |
| L-TYPEO-01 | Empty argv dumps help instead of install-ensure | Zero-arg tests | requirement-shell-cli-zero-arguments | **Closed** (suite) |
| L-UNIN-01 | self-uninstall --json without --force fakes success cancel | confirm_required | INC-20260713-002 | **Closed** (suite) |
| L-SETU-01 | `set -u` with bare HOME / privilege defaults | env -u HOME | INC-20260713-001 | **Closed** (suite) |
| L-CSUM-01 | CHECKSUM trust UX / overclaim authenticity | Companion primary; CHECKSUM not in help/about; SECURITY bounds | INC-20260713-003 | **Partial** — suite OK; wording vigilance |
| L-CITE-01 | Product source cites templates/skills as law | ALIGNMENT cites live `requirement-shell-*` only | INC-20260712-002 | **Closed** (process) |
| L-HYG-01 | Companion `*.tmp` left at repo root | No `selfmanaged.sha256.tmp` | SM-HYG-01 | **Closed** (2026-07-16) |
| L-ID-01 | APP_NAME only `:=` without hard-assign | `APP_NAME="selfmanaged"` present | SM-ID-01 | **Closed** (2026-07-16) |
| L-CITE-TERM-01 | Bootstrap footer cites terminologies | Footer cites requirement-shell-cli-* | origin 2026-07-16 | **Closed** (2026-07-16) |
| L-JSON-RAW-01 | `out_json` lacks `@key` raw nested path | `@key` supported in out_json; suite asserts unquoted insert | timer origin map | **Closed** (impl 2026-07-16; suite 2026-09-06 TP-JSON-RAW-01) |

## How to use

1. For each open L-*, re-verify with evidence in the new report.  
2. When fixed, set Open? to **Closed** and point to TP / commit / date.  
3. Promote new modes from reports into this table (do not rely on chat memory).  
