**file**: docs/requirements/requirement-shell-cli-interface.md  
**Status**: Active (Version 1.2.8)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **project Single Source of Truth** for the **POSIX shell CLI interface** of the safe-rm tool: command surface, privilege typing, global flags, dispatcher behavior, output modes, and interactive vs non-interactive rules.

It defines a **Type 0–centric self-managed shell CLI** (install / update / uninstall of the tool itself). It does **not** invent Type 1 host-bootstrap or Type 2 system-user app-ops commands unless a future requirement adds them.

**Scope:** User-facing command names, flags, dispatch, privilege labels, and mode contracts.  
**Out of scope (own requirements when specialized):** Online-install checksum mechanics detail, self-management safety beyond the command surface, shell coding style, full output-function catalog (cited, not re-owned).

### 1.1 Human-facing

**In one sentence:** This file is the **menu**: which words you type (`version`, `help`, `self-install`, `self-update`, `self-uninstall`, …), which flags (`--quiet`, `--json`, `--force`), and that **you run those as yourself** — this product does not change the host OS or switch to a dedicated account.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person who types the command | `safe-rm help` · `safe-rm version` |
| The other role | Empty argv (install-ensure) and lifecycle safety | `requirement-shell-cli-zero-arguments.md` · `requirement-shell-self-management.md` |
| Not this file | Checksum, storage paths, `out_*` internals | Peer requirements |

| Includes | Excludes |
|----------|----------|
| Command names, flags, “unknown command” fail | Host package install, dedicated-account app ops |
| Empty-argv **row** pointing at the zero-arguments file | Re-owning the full Case A/B/C matrix |

| Surface | What you open | What for |
|---------|---------------|----------|
| `safe-rm help` | Command | Listed verbs and flags |
| `./src/safe-rm` | Program file | Dispatcher |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| See the menu | Help lists self-install, version, about, self-update, self-uninstall, and flags. An unknown word is an error, not a silent no-op. | `safe-rm help` |
| Ask for JSON | Same verbs; structured objects; no human banners. | `safe-rm --json version` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Command surface (portable shape)

Every CIAO-Lite shell CLI **MUST** expose a documented command set. Commands **MUST** map to exactly one privilege type. Unclassified commands are incomplete design.

| Category | Privilege | Meaning | Portable examples |
|----------|-----------|---------|-------------------|
| **Type 0 – Self-management / CLI lifecycle** | Invoking user (no elevation required for user-owned install) | Manage the CLI binary and diagnostics | `version`, `about`, `help`, `version-check`, `self-update`, `self-uninstall` |
| **Type 0 – Install CLI binary** | Invoking user (root → global path; non-root → user path) | First-time or explicit placement of the CLI | `self-install` (canonical); `install` alias; empty argv **Type O install-ensure** — `requirement-shell-cli-zero-arguments.md` · `requirement-shell-cli-self-install.md` |
| **Type 1 – Host preparation** | Elevated (internal escalation when designed) | Host packages, system user create, Docker engine | *Not in scope for current product surface* |
| **Type 2 – App ops under system user** | Dedicated least-privilege system user | App install/configure/runtime under app identity | *Not in scope for current product surface* |

**Execution rules (core):**

1. Type 0 commands **MUST** run as the invoker without requiring a dedicated system user.
2. Type 1 (when added later) **MUST** use controlled internal escalation; normal users **MUST NOT** be forced to manually prefix every privileged sub-step as a permanent UX rule.
3. Type 2 (when added later) **MUST** run as the dedicated system user (context switch if needed). Mixing Type 1 host bootstrap with Type 2 app toolchain in one command is forbidden (see incident policy under system-user / three-layer privilege terms).
4. Privilege type for each command **MUST** be documented in help and in this requirement’s Implementation Notes.

### 2.2 Global flags (portable)

| Flag | Env / state | Behavior |
|------|-------------|----------|
| `--quiet`, `-q` | `QUIET=1` | Suppress non-error human output; errors and fatal paths still visible |
| `--json` | `JSON=1` (implies quiet) | Machine-readable structured output; no human banner text |
| `--verbal` | `VERBAL=1` | Show a finished-remove success line that is hidden by default. `--quiet` still hides that line. Does not change other success lines |
| `--debug` | `DEBUG=1` | Extra diagnostics when designed (must not break JSON purity on stdout) |
| `--force` | Force/reinstall policy vars | Skip safe confirms or force reinstall only where documented; never silent security bypass |

Additional flags **MAY** be added only when documented here (or a superseding requirement) and wired in the dispatcher.

### 2.3 Dispatcher and entry rules (portable)

1. **Single entry:** A single main dispatcher (e.g. `app_main`) **MUST** parse global flags and route commands.
2. **Unknown command:** **MUST** fail loudly with a clear error and pointer to `help` (via output SSOT).
3. **Zero-arg split:** Interactive empty argv (`TTY=1`, not quiet, not json) **MUST** open the numbered menu (`requirement-shell-cli-default-interaction.md`). Non-interactive / quiet / json empty argv **MUST** mean CLI self-install-ensure (not help, not the menu). Already installed on that path → success no-op (“already installed”), not help and not blind reinstall. How (copy vs download, dest mode): `requirement-shell-cli-self-install.md`. Full empty-argv matrix: `requirement-shell-cli-zero-arguments.md`.
4. **Idempotent install skip:** Self-install **MUST** no-op when already installed unless force/reinstall policy is set.
5. **No raw user I/O:** User-facing messages **MUST** go through the centralized `out_*` system (see output template/term).

### 2.4 Output and mode contracts (portable)

| Mode | Contract |
|------|----------|
| Human (default TTY) | Prefixed messages via `out_*`; colors only when TTY and not quiet/json |
| Quiet | Suppress info/success/plain noise; still show errors / fatal |
| JSON | Force quiet; emit structured JSON via `out_json` / `out_json_error`; no mixed human lines on success path |
| Non-interactive | Never hang on prompts; use safe defaults or `--force`/env policy |

Destructive Type 0 actions (e.g. uninstall) **MUST** confirm when interactive unless force policy is set; non-interactive **MUST NOT** block on stdin.

### 2.5 Help surface (portable)

`help` **MUST** list:

- Usage line  
- Every supported command with one-line purpose  
- Privilege category (at least Type 0 vs elevated vs system-user when those exist)  
- Global flags  

In JSON mode, help **MUST NOT** dump long human text; return a short structured success/note object instead.

**Recommended help section order** (specializee-friendly; Type 0 bootstrap uses Type 0 first):

1. Title / short description  
2. Usage  
3. **Type 0 self-management** commands  
4. **Domain commands** (when specialized B has a domain surface; **absent** on bootstrap A)  
5. Global options  
6. Environment / channel vars (never `CHECKSUM` on help)

Ship-unit injection anchors (comments in `./src/safe-rm`): `DOMAIN_HELP_ROWS`, `DOMAIN_ABOUT_FIELDS`, `DOMAIN_DISPATCH_FLAGS`, `DOMAIN_DISPATCH_COMMANDS`, `DOMAIN_DISPATCH_ROUTES`.

### 2.5.1 Specializee contract (bootstrap origin → specialized B)

When specializing product **B** from this bootstrap (**A → B only**):

| Concern | MUST | MUST NOT |
|---------|------|----------|
| **Channel** | B Config defaults `REPO_USER` / `REPO_NAME` / `SCRIPT_URL` for **B’s** product channel | Point B’s default channel at A’s raw URL (or A at B’s) without explicit user order |
| **Identity** | Retarget `APP_NAME`, descriptions, product `VERSION` on B | Leave `APP_NAME=safe-rm` on B ship unit |
| **Output** | All domain user/machine messages via `out_*` (temporary shims → `out_*` OK) | Parallel `echo`/`printf` banners or a second JSON family as product UI |
| **Host-mutating domain** | Privilege gate (**root** / designed escalation) **before** any host mutation on **every** path (interactive **and** non-interactive) | Non-interactive “success” after partial host writes as non-root |
| **Dispatch** | Single `app_main`; add domain verbs in the same parse pass as Type 0 | Drop Type 0 routes while claiming same architecture as A |
| **Help / about** | Keep Type 0 rows; add domain rows/fields at the injection anchors | Replace help entirely with domain-only text |
| **Requirements retarget** | Rewrite product identity only; keep CIAO / peer URLs (`github.com/cloudgen/ciao`, …) | Bulk `sed` org renames that break philosophy links |
| **Domain law** | After domain extend: one Active `requirement-domain-*` with four pillars | Domain law only on A; reverse-copy B domain onto A |
| **Global dest mode** | Keep `inst_cli_dest_mode`; `${GLOBAL_BIN}/B` **0755** so other logins can open the shebang | `chmod +x` on mktemp (**0711**); treat USER_BIN-only as dest-mode proof |

### 2.6 Implementation Notes (this project)

| Item | Value for safe-rm |
|------|------------------------|
| **Product / binary name** | `safe-rm` (`APP_NAME`, default `safe-rm`) |
| **Primary executable** | `src/safe-rm` (POSIX `/bin/sh`, single-file for `curl \| sh`) |
| **Dispatcher** | `app_main` (always invoked at end of script: `app_main "$@"` — no `${0##*/}` / APP_NAME basename gate; required for `curl \| sh`) |
| **Output SSOT** | `out_text` + wrappers (`out_info`, `out_success`, `out_warn`, `out_error`, `out_die`, `out_plain`, `out_json`, …) |
| **Version SSOT** | `VERSION` default `1.0.17` (script header / config block: `VERSION="1.0.17"`) |
| **Install paths** | Global: `GLOBAL_BIN` default `/usr/local/bin`; User: `USER_BIN` default `${HOME}/.local/bin` |
| **Remote channel env (help surface)** | `REPO_USER` / `REPO_NAME` / `SCRIPT_RELPATH` (defaults `cloudgen` / `safe-rm` / `src/safe-rm`); `SCRIPT_URL` composed default `https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/${SCRIPT_RELPATH}` (literal product default: `https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm`; override via env). **`help` MUST list `REPO_USER`, `REPO_NAME`, `SCRIPT_RELPATH`, and `SCRIPT_URL`, and MUST NOT list `CHECKSUM`. `about` MUST NOT list `CHECKSUM`** (install-path runtime pin only; see `requirement-shell-automatic-checksum.md`) |
| **Type 1 / Type 2 commands** | **None** on current surface — this tool is CLI lifecycle only |
| **Dedicated system user** | **Not required** for Type 0 CLI self-management |

#### Supported commands (normative for this project)

Every command is also a switch of the same name. `help` and `--help` are the same command. `version` and `--version`. `self-install` and `--self-install`. The same pair for each row below. `-restore` stays the 2023 token. Its switch is `--restore`. On the command named `rm`, only that `--` form, and `-restore`, is the command. The bare word is a path, so `rm version` removes a link named `version`.

| Command | Type | Handler (current) | Required behavior |
|---------|------|-------------------|-------------------|
| *(no command — 0-argv)* | Type 0 | `app_main` → `app_default` or `inst_self_install` | **Interactive**, including `safe-rm --debug` (`--debug` is not a command): main menu. **Non-interactive / quiet / json:** Type O CLI self-install-ensure (not help, not the menu). See `requirement-shell-cli-zero-arguments.md` · `requirement-shell-cli-default-interaction.md` |
| `menu` | Type 0 | `app_default` | Numbered list on a TTY (front **1** / **8** / **9**; remove-guard **11**; self-management **82–87**). Off a TTY: help. Sample: `safe-rm menu` |
| `main` | Type 0 | `app_default` | Alias of `menu` |
| `self-install` | Type 0 | `inst_self_install` | Place **this CLI** (copy when `$0` is a script; download when piped). Dest **0700** local / **0755** global. Dual mention: `requirement-shell-cli-self-install.md`. Sample: `safe-rm self-install` |
| `install` | Type 0 | `inst_self_install` | **Alias of `self-install`** (this product has no payload). Same copy/download/dest-mode contract. Sample: `safe-rm install` |
| `version`, `--version` | Type 0 | `app_main` / `app_version` | Print local version; JSON object when `--json`. On the command named `rm`, `--version` is this command. The bare word `version` is a path, including a link |
| `about` | Type 0 | `app_about` | Diagnostics: install presence, global/local paths, user, shell, TTY; **Cache folder used**, **Cache folder (preferred)**, **Cache folder (1st fallback)**, **Cache folder (2nd fallback)** when that host has one, and **Persistence storage** (`requirement-shell-cli-storage`); JSON when `--json`; **no `CHECKSUM` field** |
| `version-check` | Type 0 | `ver_check` | Compare local vs remote `VERSION` from `SCRIPT_URL`; fail clearly if URL unset/unreachable |
| `self-update` | Type 0 | `inst_self_update` | Fetch remote version; reinstall when policy allows; reuse install primitives |
| `self-uninstall` | Type 0 | `inst_self_uninstall` | Remove managed binary; PATH cleanup only if `~/.local/bin` empty (user installs) |
| `help`, `--help` | Type 0 | `app_help` | Full usage in human mode; short JSON note in JSON mode; Environment lists channel vars only — **not** `CHECKSUM`. Lists every command switch |
| `setup` | domain | `srm_cmd_setup` | Admin login checks the before/after table and swaps when needed. Sample: `safe-rm setup`. Law: `requirement-domain-safe-rm.md` |
| `restore` | domain | `srm_cmd_restore` | Put `origin-rm` back as `rm` and remove the `safe-rm` link. Sample: `safe-rm restore`. Law: `requirement-domain-safe-rm.md` |
| `-restore` | domain | `srm_cmd_restore` | 2023 token when this program is the `rm` people type |
| `reset` | domain | `srm_cmd_reset` | When `origin-rm` exists, point `rm` at it. Linux uses root or `sudo`. Leave `origin-rm` and `safe-rm`. Sample: `safe-rm reset`. Law: `requirement-domain-safe-rm.md` |
| *(command name is `rm`)* | domain | `srm_cmd_rm` | Basename of `$0` is `rm`. A lifecycle `--` switch is that command. A bare lifecycle word is a path (`rm version` removes a link named `version`). Other arguments are the remover's arguments (`rm -rf test`), not a second `rm` verb. Law: `requirement-domain-safe-rm.md` |

#### Global flags (normative wiring for this project)

| Flag | Required wiring |
|------|-----------------|
| `--quiet`, `-q` | Set `QUIET=1` in `app_main` |
| `--json` | Set `JSON=1` and `QUIET=1` in `app_main` |
| `--verbal` | Set `VERBAL=1` in `app_main`. On a remove, `srm_cmd_rm` sets the same flag and does not forward `--verbal` to the remover. The finished-remove line is owned by `requirement-domain-safe-rm.md` |
| `--debug` | Set `DEBUG=1` in `app_main` |
| `--force` | Parsed by `app_main` → `FORCE=1` and `FORCE_REINSTALL=1`; used by install reinstall, self-update (incl. deliberate downgrade), and uninstall confirm skip |

#### Dispatcher acceptance criteria (this project)

1. Unknown token after flag parse → `out_die` with pointer to `safe-rm help`. A remover switch on the command named `rm` is not an unknown token (`requirement-domain-safe-rm.md`).  
2. Zero-arg → interactive: numbered menu. Non-interactive / quiet / json: CLI self-install-ensure (not help, not the menu); failures non-zero. Basename `rm` is the remove, not this split.  
3. Command routing table in `app_main` **must** include every row in the command table above.  
4. Help text **must** stay aligned with that table (no orphan commands, no listed-but-unrouted commands).  
5. User-facing strings **must not** use raw `echo`/`printf` outside the `out_*` system (protected low-level helpers excepted only if already CIAO-marked and not for general messages).

#### Explicitly out of scope until a new requirement

- Type 1: `prerequisites`, `create-user`, Docker host install, etc.  
- Type 2: app `start`/`stop`/`configure` under a system user  
- The remove guard (`rm`, `--dry-run`, `setup`, `restore`, the protected-rm swap) is owned by `requirement-domain-safe-rm.md` §2.0.5. This file keeps the Type 0 menu and does not restate the refuse table. Setup writes the home guard as this login, then on Linux re-execs itself through `sudo` for the system swap. On Termux this login runs measure 2 against `$PREFIX/bin/rm` and does not call `sudo`. macOS, Git Bash, and Windows cmd stop after the home guard and do not call `sudo`. Tests use a `/tmp/safe-rm-swap.*` directory and do not remove a directory.  

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Unknown commands fail loud; force and prompts gate destructive ops; quiet/json never hide fatal errors incorrectly.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Every command has one privilege type, one handler, and documented flags.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Works under TTY, `curl | sh`, quiet, and JSON; root vs user install paths.  
- **CIAO Principle 5 – Single Source of Output** and **Principle 14 – Security & Traceability** (https://github.com/cloudgen/ciao): Central `out_*`; JSON/human separation.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` is the dispatcher SSOT.  
- **CIAO Principle 10 – Least-Privilege User** (https://github.com/cloudgen/ciao): Type 0 default for CLI self-care; no invented system-user requirement for binary lifecycle.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): No hang in non-interactive; prompts only when appropriate.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protection Rule below blocks privilege and UX regressions.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail loud on bad input; never silent wrong privilege context.  
- **Intentional:** Command table + help + dispatcher stay synchronized.  
- **Anti-fragile:** Per-user and global install; network/remote optional until `SCRIPT_URL` set.  
- **Over-protect:** Do not collapse Type 0/1/2, remove JSON quiet contract, or reintroduce raw output for user messages.  
- **SSOT:** `APP_NAME` / `VERSION` / flags at config defaults; output via `out_*`; dispatch via `app_main`.  
- **Idempotency:** Already-installed install path is a no-op unless force reinstall.  
- **Respect old working logic:** Surgical changes only; preserve Protection Zones and battle-tested install/self-management helpers unless explicitly redesigning.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Remove or rename the normative Type 0 commands without updating this requirement and help together.  
2. Add Type 1 or Type 2 commands that mix host bootstrap with app toolchain in a single privileged install (three-layer privilege: Type 0 tool self-management must stay separate from Type 1 host bootstrap and Type 2 system-user app ops).  
3. Force manual `sudo` as the only UX for every elevated sub-step when internal escalation is the designed pattern (when Type 1 is introduced).  
4. Bypass `out_*` with raw user-facing `echo`/`printf` for normal messages.  
5. Break the contract that `--json` implies quiet and machine-oriented output.  
6. Drop zero-arg install-ensure for the classic `curl | sh` path (including already-installed success no-op) without an explicit requirement change (`requirement-shell-cli-zero-arguments.md`).  
7. Document flags in help that the dispatcher does not parse (or leave `--force` documented-only).  
8. Invent a dedicated system user as mandatory for Type 0 CLI self-management without a specialized architecture requirement.

**Violating this rule is a critical CLI interface regression.**

---

## 5. Definition of done (CLI interface)

This requirement is satisfied for the safe-rm shell CLI when all of the following hold:

1. Every command in §2.6 is routed and documented.  
2. Global flags in §2.6 are parsed and honored.  
3. Output modes match §2.4 (including JSON purity).  
4. Install privilege paths remain invoker-based (root/global vs user/local).  
5. No Type 1/2 surface claims exist without matching specialized requirements.  
6. Protection Rule items are not violated in code or docs.  
7. Traceability: implementation changes cite this file path / key `requirement-shell-cli-interface`.

---

## Under command line for normal user only

This product may run on Termux, Git Bash, Windows cmd, or the same class (this login only).

**This requirement:** the command surface stays **normal user privilege** on Termux, Git Bash, Windows cmd, and macOS. Help and dispatch **MUST NOT** add admin-privilege or dedicated-account verbs on that class. **MUST NOT** recommend `sudo curl | sh`. The Linux `sudo` re-exec is setup measure 2 only (`requirement-domain-safe-rm.md` §2.0.5), not a verb of its own. Git Bash and Windows cmd **MUST NOT** invoke Termux `pkg`.

| MUST | MUST NOT |
|------|----------|
| Keep listed verbs as this-login self-care | Enable Type 1 host-prep or Type 2 app-ops on that class |
| Document Type 1/2 as unused on current surface | Wrap `sudo` / `apt` / `dnf` because “install” was requested on Termux, Git Bash, Windows cmd, or macOS |

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-self-management.md` | Lifecycle command semantics |
| `docs/requirements/requirement-shell-output-requirements.md` | Output SSOT and channels |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY / automation mode behavior |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv: interactive menu; otherwise install-ensure |
| `docs/requirements/requirement-shell-cli-self-install.md` | Dual mention `self-install`; `$0` copy vs download; dest 0755/0700 |
| `docs/requirements/requirement-shell-idempotency.md` | Re-run safety for ensure ops |
| `docs/requirements/requirement-shell-modular-function-design.md` | Prefix ownership (`app_`, `inst_`, `out_*`, `srm_`) |
| `docs/requirements/index.md` | Registry SSOT |
| `./src/selfmanaged` | Bootstrap origin ship unit (do not overwrite from safe-rm) |
| `requirement-domain-safe-rm.md` | Domain SSOT for `rm`, `--dry-run`, and `--verbal` |
| `./src/safe-rm` | Specialized ship unit |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-SRM-41** | `tests/run_dry_run.sh` | have |

**Map:** `reviews/test-plan.md`

`--verbal` shows the finished-remove line. The sentence itself is domain law. This file owns the flag wiring.

**Last Updated**: 2026-09-30 (1.2.8 — `--verbal` shows the finished-remove line; that line stays hidden by default)  
**Owner**: safe-rm project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 5, 6, 10, 16, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
