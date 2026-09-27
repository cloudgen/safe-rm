# Filled run: CL-TEMP-FILE-SYSTEM — safe-rm 1.0.2 cache folder

**Date:** 2026-09-27  
**Blank form:** `docs/templates/checklists/checklist-temp-file-system.md` (local harness; this filled run is the versioned record)  
**Product:** safe-rm (`src/safe-rm`)  
**Reference:** sibling grok-cli `requirement-shell-cli-storage` 1.4.0 and the cache-folder rules (placeholders only; no hardcoded app name, login, or process id)  
**Change type:** fix  
**Related law:** `requirement-shell-cli-storage` **1.1.0** · `requirement-shell-cli-interface` **1.2.1**  
**Proof:** **TP-CACHE-01** · **TP-CACHE-02** · **TP-CACHE-03** (`tests/run_dry_run.sh`)

## Verdict

- [x] **Pass** — per-login per-process cache directory; mktemp files; silent tier miss; persistence separate
- [ ] **Revise**
- [ ] **Block**

Reviewer / role: Implement + Review (this change)  
Date: 2026-09-27

## 1. Leaves (blocking)

- [x] Scratch created with `mktemp` / `util_mktemp` under `${TMPDIR}` (after storage resolve) (**TP-CACHE-03**)
- [x] `mkdir` of one cache tier is fail-soft and silent (**TP-CACHE-02** skip of preferred: no `fallback` text, no `Cannot create cache`, no `[WARN]` / `[ERROR]`, live path is the 1st fallback, preferred path still printed)
- [x] Linux: `/dev/shm/cache/cache-${APP_NAME}-${login}-$$`, then `/tmp/cache/...`, then `${HOME}/.cache/cache-${APP_NAME}-$$` (**TP-CACHE-02**)
- [x] Git Bash: `/tmp/cache/cache-${APP_NAME}-${login}-$$`, then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$`. No 2nd fallback line (**TP-CACHE-02**)
- [x] Mac: `/tmp/cache/...`, then `${HOME}/Library/Caches/cache-${APP_NAME}-$$`, then `${HOME}/cache/cache-${APP_NAME}-$$` (**TP-CACHE-02**)
- [x] Cache directory may end in `-$$`. Scratch files stay `mktemp` (`util_mktemp` uses `XXXXXX`, not `${APP_NAME}.$$`) (**TP-CACHE-03**)
- [x] `ps -p $$` is not used as a cache path
- [x] `mktemp` failure stays fail-closed (`util_mktemp` falls through to `mktemp`, then the resolver dies only when every tier failed)
- [x] Chosen leaf mode **0700** (**TP-CACHE-02**). Live path is not `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${login}`
- [x] Home leaves omit `${login}`. Persistence is `${HOME}/.local/${APP_NAME}` with no login suffix and no `$$`

## 2. Cleanup

- [x] Fatal helpers still `exit 1` only when every cache tier failed
- [x] Re-run does not reuse another process’s leaf (`$$` is this process) (**TP-CACHE-02**)

## 3. Root vs leaf

- [x] Root still from `util_resolve_storage`. No second chain
- [x] `TMPDIR` exported to the chosen cache directory (`app_main`)

## 4. Proof

- [x] **TP-CACHE-01** human labels: Cache folder used, preferred, 1st fallback, 2nd fallback, Persistence storage. No Storage (effective) / Storage (fallback)
- [x] **TP-CACHE-02** Linux, Git Bash, and Mac chains; silent skip; mode 0700; persistence `${HOME}/.local/${APP_NAME}`
- [x] **TP-CACHE-03** `util_mktemp` name under the cache leaf; `$$` file-name template refused
- [x] Suite does not assign `HOME` to a scratch directory. `about` is not a remove path
- [x] Dry-run suite PASS=200 FAIL=0. Bootstrap suite PASS=142 FAIL=0 SKIP=0

## Scope

| Field | Value |
|-------|--------|
| Script / ship unit | `src/safe-rm` 1.0.2 |
| Related requirement | `requirement-shell-cli-storage` 1.1.0 |
| Change type | fix |
