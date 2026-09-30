**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Active (Version 1.1.2)  
**Area**: shell  
**Key**: `requirement-shell-cli-storage`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **shell CLI storage** of safe-rm. **Storage** means **two** classes:

| Class | Role | Survives reboot |
|-------|------|-----------------|
| **Cache folder** | Volatile scratch / temps | No (shm/tmp) or maybe (home fallback) |
| **Persistence storage** | Durable per-user app data | Yes (under this login’s `$HOME`) |

It owns path **shapes**, central resolvers, the `app_main` wire, and about diagnostics for both classes.

The preferred cache is **not** a ram-drive **project** tree (`/dev/shm/safe-rm` or `/dev/shm/safe-rm-<login>`). It lives under `/dev/shm/cache/` (Linux) or `/tmp/cache/` (Git Bash and Mac). The leaf is **per login and per process** so two logins never share one cache directory.

Placeholders only. **MUST NOT** hardcode an app name, a login name, or a process id.

- `${APP_NAME}` is the product app name.
- `${login}` is this login (`id -un`), one path segment.
- `$$` is this process id. It is not a fixed number.
- `${HOME}` is this login’s home.

A skipped tier is silent. No warning and no error because a higher cache folder was not used. An error is only when every tier for this host failed.

The directory name carries `$$`. Scratch files inside that directory stay unpredictable names. They do not use a `$$` file name. `mktemp` is not installed on every OS. When it is missing, the file is still created under this cache folder.

Volatile tiers (`/dev/shm` and `/tmp`) include `${login}` so two logins do not share one leaf. Home tiers omit `${login}` because `${HOME}` is already that login.

---

### 1.1 Human-facing

Scratch goes in a cache folder. Durable app data for this login goes under persistence storage.

| You | Another role | Not this |
|-----|--------------|----------|
| Let the CLI pick cache + persistence | Another login’s leaf is a different directory | Putting scratch in `/tmp` with a guessed name; treating `~/.local/bin` as data |

**Includes:** cache resolver, persistence resolver, about fields. **Excludes:** install binary placement; the remove guard (`requirement-domain-safe-rm`).

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Inspect storage | about shows Cache folder used, preferred, 1st fallback, 2nd fallback when that host has one, and Persistence storage. A skipped tier prints nothing | `safe-rm about` / `safe-rm --json about` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Two storage classes (mandatory split)

Volatile leaf (shared parents `/dev/shm` and `/tmp`): `cache-${APP_NAME}-${login}-$$`.  
Home leaf (already per login): `cache-${APP_NAME}-$$`.  
`$$` is **this process id**. `${login}` is `id -un` as one path segment. **MUST NOT** hardcode either.

| Host | Preferred | 1st fallback | 2nd fallback |
|------|-----------|--------------|--------------|
| Linux (and Termux, and any host that is not Git Bash or Mac) | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/.cache/cache-${APP_NAME}-$$` |
| Git Bash (`MSYSTEM`, or `uname -s` `MINGW*` / `MSYS*`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` | none |
| Mac (`uname -s` `Darwin`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/Library/Caches/cache-${APP_NAME}-$$` | `${HOME}/cache/cache-${APP_NAME}-$$` |

| Class | Helper |
|-------|--------|
| Cache folder (preferred) | `util_preferred_cache_dir` |
| Cache folder (1st fallback) | `util_fallback_cache_dir` |
| Cache folder (2nd fallback) | `util_fallback2_cache_dir` (empty on Git Bash) |
| Persistence storage | `util_persistent_storage_dir` → `${HOME}/.local/${APP_NAME}` |

Live chosen **cache** root: `util_resolve_storage` (stdout).  
Live **persistence** root: `util_resolve_persistent_storage` (stdout; create-before-return).

On Termux/Android, the chosen cache root (including `/tmp` and `/dev/shm`) **MAY** be **`noexec`**. Termux uses the **Linux** chain. Cache remains scratch **only**. **MUST NOT** exec a binary from the cache folder.

**Silent fallback.** Choosing a later tier **MUST NOT** print a warning or an error. **MUST NOT** say that a fallback happened. An error is allowed only when **every** tier for this host failed to be created.

**MUST NOT** mix these with:

| Forbidden as this product’s storage | Why |
|-------------------------------------|-----|
| `${HOME}/.local/bin` / `USER_BIN` | Install binary dir |
| `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` | Looks like a ram-drive project folder |
| `${HOME}/.local/share/${APP_NAME}` | Not this product’s persistence shape |
| `XDG_CACHE_HOME` as the chain | Replaces the host table |

Persistence is not a cache tier. It stays `${HOME}/.local/${APP_NAME}` with no login suffix and no `$$`.

### 2.2 Single cache resolver SSOT

1. **MUST** keep **one** authoritative cache-resolve helper: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` under a path it returned).  
3. Resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture.  
4. User-visible failure about cache **MUST** use Output SSOT.

Preferred and fallback **path shapes** **MUST** be `util_preferred_cache_dir`, `util_fallback_cache_dir`, and `util_fallback2_cache_dir` (or the same literals those helpers print).

### 2.3 Live cache resolve priority

Walk this host’s chain in order. First directory that can be created **and** is writable wins. The chain is the table in §2.1. **MUST NOT** replace that chain with one shared `cache-${APP_NAME}` leaf or with `XDG_CACHE_HOME`.

**Parent:** for `/dev/shm/cache` and `/tmp/cache` the resolver **MUST** create that parent (prefer mode **1777** when creating) so each login can add its own `cache-${APP_NAME}-${login}-$$` leaf. The **leaf** **MUST** be mode **0700**.

**Create before return:** for the **chosen** leaf, the resolver **MUST** create it, confirm it is **writable**, then print the path. If create/write fails → try the next tier **with no message**. If none work → **MUST** fail closed. **MUST NOT** return a path without creating it.

**MUST NOT** use these as cache:

| Forbidden cache path | Why |
|----------------------|-----|
| `/dev/shm/${APP_NAME}` | Looks like a ram-drive project folder |
| `/dev/shm/${APP_NAME}-${USERNAME}` | Same confusion. Login belongs in the leaf **under** `cache/`, as `cache-${APP_NAME}-${login}-$$` |
| `/dev/shm` or `/tmp` as a dump | No app-named cache leaf |
| Persistence storage | Durable data is not scratch |

### 2.4 Cache isolation

1. Cache leaves **MUST** include **`cache-${APP_NAME}`** (app identity).  
2. Volatile leaves (`/dev/shm/cache` and `/tmp/cache`) **MUST** be `cache-${APP_NAME}-${login}-$$`. Home leaves **MUST** be `cache-${APP_NAME}-$$` (no login segment). Isolation is the login segment plus this process id, not one shared directory that the second login falls out of.  
3. **MUST NOT** use a single shared world-writable directory for all logins or all apps.  
4. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so a temp maker that is installed inherits the isolated **cache** root.  
5. New scratch files **MUST** go through **`util_mktemp`**. That helper **MUST** check that `mktemp` exists and is executable before it calls it. `mktemp` is not installed on every OS until `apk`, `apt`, or a peer package install.  
6. When the temp maker is absent, or every `mktemp` attempt fails, the scratch **file** **MUST** be created under the resolved cache folder as `${APP_NAME}.${suffix}.${token}`, then mode `0600`. The token **MUST NOT** be a `$$` name. A scratch **directory** uses the same check: `mktemp -d` only when it can create a directory; otherwise `mkdir` a unique subdirectory of that cache folder. `mkdir` applies umask. Mode **MUST** be `0700`, and the directory **MUST** be searchable and writable, before any file is written in it. A directory at `0600` (`drw-------`) exists and cannot be searched.  
7. The **cache directory** name includes `$$` (this process). Scratch **files** inside it **MUST NOT** use a predictable `$$` file name (forbidden: `/tmp/${APP_NAME}.$$`, `${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$`). A missing temp maker **MUST NOT** fall back to a bare `/tmp` dump.
8. When the process exits, it **MUST** remove the cache leaf this process created. A stop signal during a remove does that removal and then exits `1`. The removal **MUST** be only that leaf: the basename is `cache-${APP_NAME}-${login}-$$` or `cache-${APP_NAME}-$$`, and the parent is one of this host's cache parents. **MUST NOT** remove `$HOME`, `/dev/shm/cache`, `/tmp/cache`, persistence storage, or a path that contains `..`. The leaf is mode `0700` while the process is alive. Proof: `TP-SRM-42`. After `about`, `TP-CACHE-02` shows the leaf is gone.

**`util_mktemp` shape** (the ship unit is the body; this is the contract):

```sh
util_mktemp() {
    : "${APP_NAME:=safe-rm}"
    : "${EFFECTIVE_STORAGE_DIR:=}"
    _suffix="${1:-tmp}"
    # Refuse a suffix that contains $$.
    if [ -z "${EFFECTIVE_STORAGE_DIR}" ]; then
        EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)
        export EFFECTIVE_STORAGE_DIR
    fi
    _bin=$(command -v mktemp 2>/dev/null || true)
    if [ -n "$_bin" ] && [ -x "$_bin" ]; then
        _made=$("$_bin" "${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.${_suffix}.XXXXXX" 2>/dev/null) || _made=
        if [ -n "$_made" ]; then
            printf '%s\n' "$_made"
            return 0
        fi
    fi
    # Temp maker absent or unable to create. Unique file under the cache folder.
    # Token is not a $$ name. chmod 0600 after create.
}
```

**Forbidden:**

```sh
# MUST NOT
tmp="/tmp/${APP_NAME}.$$"
tmp="${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$"
```

### 2.5 Persistence storage

1. Persistence **MUST** be **`${HOME}/.local/${APP_NAME}`** (this login’s home + app name).  
2. Helper **`util_persistent_storage_dir`** **MUST** print that path. **`util_resolve_persistent_storage`** **MUST** `mkdir -p` it, confirm it is writable, then print it (fail closed).  
3. **MUST NOT** use `${HOME}/.local/bin` as persistence (that is `USER_BIN`).  
4. **MUST NOT** store scratch/temps in persistence when a cache root is available.  
5. Persistence **MUST** be under the invoking login’s `$HOME` (per-user). **MUST** include `${APP_NAME}`. **MUST NOT** add a login suffix or `$$`.

### 2.6 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; `PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)`; export `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR`, `PERSISTENT_STORAGE_DIR`, `TMPDIR` (`TMPDIR` = cache root; `STORAGE_DIR` = 1st fallback path) |
| `app_about` human | **MUST** print **`Cache folder used:`** then the live directory; **`Cache folder (preferred):`** then this host’s preferred path; **`Cache folder (1st fallback):`** then the 1st fallback; **`Cache folder (2nd fallback):`** only when this host has a 2nd fallback; **`Persistence storage:`** then `${HOME}/.local/${APP_NAME}`. Linux sample below. **MUST NOT** label cache lines **Storage (effective)** or **Storage (fallback)**. **MUST NOT** warn or error when the used directory is a fallback |
| `app_about` JSON | **MUST** include `cache_used`, `cache_preferred`, `cache_fallback` (1st), `cache_fallback_2` (2nd, empty string when the host has none), `persistence_storage`, and the live chosen cache root as `effective_storage` (same value as `cache_used`; `storage_dir` = 1st fallback). **MUST NOT** include `CHECKSUM` |

`Cache folder used` is the tier that was created. When the preferred tier is the one used, the used line and the preferred line are the same path. When a fallback is used, the used line is that fallback path and the preferred line still shows the preferred path. Neither case prints a warning.

Linux `about` lines (placeholders, not a fixed process id):

```
[INFO] Cache folder used: /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (preferred): /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (1st fallback): /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (2nd fallback): ${HOME}/.cache/cache-${APP_NAME}-$$
[INFO] Persistence storage: ${HOME}/.local/${APP_NAME}
```

Git Bash omits the 2nd fallback line:

```
[INFO] Cache folder used: /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (preferred): /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (1st fallback): ${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$
[INFO] Persistence storage: ${HOME}/.local/${APP_NAME}
```

Mac prints preferred under `/tmp/cache/`, 1st fallback under `${HOME}/Library/Caches/`, and 2nd fallback under `${HOME}/cache/`:

```
[INFO] Cache folder used: /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (preferred): /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (1st fallback): ${HOME}/Library/Caches/cache-${APP_NAME}-$$
[INFO] Cache folder (2nd fallback): ${HOME}/cache/cache-${APP_NAME}-$$
[INFO] Persistence storage: ${HOME}/.local/${APP_NAME}
```

### 2.7 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `safe-rm` |
| **Ship unit** | `src/safe-rm` |
| **Cache resolver** | `util_resolve_storage` |
| **Linux preferred** | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` |
| **Linux 1st / 2nd** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/.cache/cache-${APP_NAME}-$$` |
| **Git Bash** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` |
| **Mac** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/Library/Caches/cache-${APP_NAME}-$$` then `${HOME}/cache/cache-${APP_NAME}-$$` |
| **Persistence** | `${HOME}/.local/safe-rm` |
| **Persistence resolver** | `util_resolve_persistent_storage` |
| **Call sites** | `app_main`, `app_about` |
| **Test-purpose env** | `SRM_CACHE_HOST=linux\|gitbash\|mac` selects the chain. `SRM_CACHE_SKIP=preferred` skips tier 1 with no message. Operators do not set these |
| **Not this ship unit** | `src/selfmanaged` is the bootstrap snapshot. Its older resolver is not this version’s proof |

### 2.8 Why This Requirement Exists (CIAO)

- **Caution:** Multi-user isolation without looking like a project tree on tmpfs; durable data is not mixed with the install bin.  
- **Intentional:** Storage = cache folder **and** persistence storage; about says both.  
- **Anti-fragile:** Missing `/dev/shm` still works, and the miss is silent.  
- **Over-protect:** The directory may carry `$$`. Scratch files inside it stay `mktemp` names.

---

## Under command line for normal user only

When safe-rm runs on Termux, Git Bash, Windows cmd, or the same class (this login only — no root, no dedicated system account):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** only | Enable **admin privilege** (`sudo`, write `/etc`) or a **dedicated system user** to “fix” a missing cache tier |
| Termux: Linux cache chain; cache may be `noexec` and is scratch only | Exec a binary from the cache folder |
| Git Bash and Windows cmd: same ceiling | Invoke Termux `pkg` because those hosts were detected |

Detect: Termux — `uname` contains Android, or `PREFIX` / `TERMUX_VERSION` is set. Git Bash — `MSYSTEM` or `uname -s` is MINGW*/MSYS*. Windows cmd — `OS=Windows_NT` after excluding Git Bash, Cygwin, and WSL.

**This requirement:** cache and persistence stay under this login. Do not resolve scratch into `/etc`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile cache first, user cache last for scratch.  
- Persistence is under `$HOME/.local/${APP_NAME}`, not under `bin`.  
- Isolation before convenience.  
- Create fail-closed in the resolvers. A skipped tier stays silent.  
- Cache path family is distinct from ram-drive **project** folders.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Restore `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` as the preferred cache.  
2. Label about cache lines **Storage (effective)** / **Storage (fallback)**. The labels are **Cache folder used**, **Cache folder (preferred)**, **Cache folder (1st fallback)**, **Cache folder (2nd fallback)** when that host has one.  
3. Drop persistence storage from this requirement or from `about`.  
4. Use `${HOME}/.local/bin` as persistence.  
5. Replace the cache fallback chain with a shared world-writable dump, with `XDG_CACHE_HOME`, or with one `cache-${APP_NAME}` leaf shared by every login.  
6. Scatter hard-coded `/tmp/safe-rm` roots outside the cache resolver.  
7. Leave the resolvers dead with no call sites while claiming storage is product law.  
8. Echo a tier path without creating it.  
9. Use predictable `$$` scratch **file** names. The cache **directory** itself includes `$$`. Scratch file names stay unpredictable (`mktemp` `XXXXXX`, or a token when `mktemp` is absent).  
9b. Call `mktemp` without checking that the program exists. Treat a directory at `0600` as usable. Fall back to a bare `/tmp` name when the temp maker is missing.  
10. Warn or error only because a higher cache tier was skipped.  
11. Drop `${login}` or `$$` from a volatile cache leaf, or put the login back on `/dev/shm/${APP_NAME}-${login}` outside `cache/`. Put `${login}` or `$$` on a home leaf or on persistence.  
12. Exec a binary from the cache folder, `/tmp`, or `/dev/shm` on Termux.  
13. Hardcode an app name, a login name, or a process id into a cache path.
14. Leave this process's cache leaf behind after the process exits. Remove `$HOME`, `/dev/shm/cache`, `/tmp/cache`, persistence storage, or a path that contains `..` as that cleanup.

**Violating this rule is a critical cache isolation / honesty regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Exactly one authoritative cache resolver creates and returns the cache root |
| AC-2 | Linux preferred leaf is `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` when that directory is usable. Git Bash and Mac preferred leaf is `/tmp/cache/cache-${APP_NAME}-${login}-$$` |
| AC-3 | `app_main` sets `EFFECTIVE_STORAGE_DIR` / `TMPDIR` / `PERSISTENT_STORAGE_DIR` early |
| AC-4 | `about` human prints Cache folder used, preferred, 1st fallback, 2nd fallback when present, and Persistence storage; JSON has `cache_used` / `cache_preferred` / `cache_fallback` / `cache_fallback_2` / `persistence_storage` |
| AC-5 | Scratch files use `util_mktemp`. When `mktemp` exists and works, the name is an `XXXXXX` name under the cache leaf. When it does not, the file is `${APP_NAME}.${suffix}.${token}` under that leaf, mode `0600`, and is not a `$$` name. A scratch directory created with `mkdir` is mode `0700` and searchable before any file is written |
| AC-6 | Live cache path is not `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` |
| AC-7 | Persistence path is `${HOME}/.local/${APP_NAME}` and the directory exists after resolve |
| AC-8 | Skipping a cache tier prints no warning and no error. Git Bash has no 2nd fallback. Mac 2nd fallback is `${HOME}/cache/cache-${APP_NAME}-$$`. Home leaves omit `${login}` |
| AC-9 | The cache leaf is mode `0700` while this process is alive. After the process exits, that leaf is gone. `$HOME` and the cache parents stay |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | About command; cache lines are named here |
| `requirement-shell-output-requirements` | `out_*`; resolver stdout is a data return |
| `requirement-shell-modular-function-design` | `util_*` ownership |
| `requirement-domain-safe-rm` | Remove guard. Not a cache tier |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CACHE-01** | `tests/run_dry_run.sh` | **have** — about JSON cache + persistence fields + human labels; no Storage (effective) / Storage (fallback) |
| **TP-CACHE-02** | same | **have** — Linux preferred `/dev/shm/cache/cache-${APP_NAME}-${login}-$$`; 1st `/tmp/cache/...`; 2nd `${HOME}/.cache/cache-${APP_NAME}-$$`; Git Bash and Mac chains; silent skip of preferred; the leaf is removed when the process exits; persistence `${HOME}/.local/${APP_NAME}` remains; not `/dev/shm/${APP_NAME}-${login}` |
| **TP-CACHE-03** | same | **have** — `util_mktemp` writes `mktemp` names under the cache leaf, refuses a `$$` file-name template, and when the temp maker is absent writes a mode-`0600` file under that leaf that is not a `$$` name |

The suite does not assign `HOME` to a scratch directory. `about` is not a remove path.

**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-06 | Active 1.0.1 | Bootstrap wire: `/dev/shm/${APP_NAME}-${USERNAME}` then `/tmp` then `XDG_CACHE_HOME`. About said Storage (effective) |
| 2026-09-27 | Active 1.1.0 | Per-login per-process cache leaves. Linux shm → tmp → `${HOME}/.cache`. Git Bash tmp → AppData Local Temp. Mac tmp → Library/Caches → `${HOME}/cache`. Silent tier miss. Persistence `${HOME}/.local/${APP_NAME}`. `about` prints used / preferred / 1st / 2nd. Ship unit `src/safe-rm` |
| 2026-09-30 | Active 1.1.1 | `mktemp` is not on every OS. `util_mktemp` checks the maker first. A missing or failing maker writes a mode-`0600` file under the cache folder, not a `$$` name and not a bare `/tmp` dump. A scratch directory is mode `0700` before use. |
| 2026-09-30 | Active 1.1.2 | The process removes its cache leaf on exit. The leaf stays mode `0700` while the process is alive. Cleanup does not remove `$HOME`, a cache parent, or persistence storage. |

---

**Last Updated**: 2026-09-30 (1.1.2 — the process removes its cache leaf on exit)  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
