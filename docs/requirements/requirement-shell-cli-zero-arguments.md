**file**: docs/requirements/requirement-shell-cli-zero-arguments.md  
**Status**: Active (Version 1.3.0)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **zero-argument (empty argv) dispatcher behavior** of the selfmanaged POSIX `/bin/sh` Type 0 CLI.

### 1.0 Product type (template dual-model)

| Field | Value for selfmanaged |
|-------|------------------------|
| **Empty-argv type** | **Type O — Online-install** (not Type N) |
| **Rationale** | Product advertises `curl … \| sh` one-liner install; empty argv is install-ensure, not help |

Type N (non-online-install → empty argv = help) does **not** apply to this product.

It defines what happens when the tool is invoked with **no command and no flags**, including the classic one-liner:

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/selfmanaged/main/src/selfmanaged | /bin/sh
```

Interactive empty argv (`TTY=1`, not quiet, not json) opens the numbered menu and does not use the three cases below. Non-interactive empty argv means **install-ensure** for three detect cases:

| Case | Meaning |
|------|---------|
| **Not installed** | No managed binary at the resolved install path(s) |
| **Installed (local)** | Managed binary at the user path (`USER_BIN` / `${HOME}/.local/bin/selfmanaged`) |
| **Installed (global)** | Managed binary at the global path (`GLOBAL_BIN` / `/usr/local/bin/selfmanaged`) |

**Scope:** Empty-argv routing, detect cases (global / local / absent), messages, force boundary, exit status, interaction with TTY / quiet / json.  
**Out of scope (own requirements):** Full command catalog (`requirement-shell-cli-interface.md`); **how** place copies vs downloads and dest mode (`requirement-shell-cli-self-install.md`); download/checksum detail (`requirement-shell-automatic-checksum.md`); full self-update/uninstall lifecycle (`requirement-shell-self-management.md`); output function catalog (`requirement-shell-output-requirements.md`); general idempotency matrix beyond empty-argv rows (`requirement-shell-idempotency.md`).

### 1.1 Human-facing

**In one sentence:** If you run this program with **no arguments** at a terminal, it opens the numbered menu. The advertised `curl … | sh` one-liner has no terminal, so it **must place itself or confirm it is already installed** — it must not print help and it must not open the menu.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | First-time install or a healthy re-run of the one-liner | `curl -fsSL …/selfmanaged \| /bin/sh` |
| The other role | Explicit verbs: help, force reinstall, uninstall | `selfmanaged help` · `selfmanaged install --force` |
| Not this file | Full command list, checksum, update/uninstall, output printers | `requirement-shell-cli-interface.md` and peers |

| Includes | Excludes |
|----------|----------|
| Zero tokens (`$# -eq 0`): pipe one-liner, `./src/selfmanaged` with nothing after the name | `selfmanaged --json` / `selfmanaged --quiet` (those have argv; default command stays help unless you also pass `install`) |
| Not installed / already in user bin / already in system bin | Domain setup, host packages, dedicated-account ops |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/selfmanaged` | Program file people install | Live empty-argv behavior |
| `selfmanaged` with no args | Command | Install-ensure |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First install from the internet | No program is on disk yet. The pipe has no human to answer a question, so the tool **places itself** (user bin for a normal login; system bin if you already ran as root). Failure must be a real error, not a fake success. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/selfmanaged/main/src/selfmanaged \| /bin/sh` |
| Run it again when it is already installed | Same one-liner **must succeed and say it is already installed**. It must not dump help and must not require `--force`. | `selfmanaged` (no arguments) |
| Quiet or JSON with **no arguments** | No yes/no question. The tool still **places** the program (or no-ops if already installed). A helper that returns success without placing is a defect. | Environment already `JSON=1` or `QUIET=1`, then `selfmanaged` with empty argv — **not** `selfmanaged --json` alone |

Jargon: **Type O** (letter) means “no arguments = install-ensure.” That is **not** Type **0** (digit: you run as yourself).

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Definitions (portable + project)

| Term | Definition for selfmanaged |
|------|----------------------------|
| **Type O** | Online-install empty-argv product type: empty argv = install-ensure (this product). |
| **Type N** | Non-online-install empty-argv type: empty argv = help — **out of scope** for selfmanaged. |
| **Empty argv / zero-arg** | `$# -eq 0` at entry to `app_main` (no command tokens; classic `curl \| sh` with no trailing args). |
| **Install-ensure** | Converge to “managed `selfmanaged` binary present”; either perform install or success no-op. |
| **Not installed** | `inst_is_installed` returns false (`inst_get_version` → `not installed`). |
| **Installed (local)** | Executable at `${USER_BIN}/selfmanaged` (default `USER_BIN=${HOME}/.local/bin`) observed by install-detect SSOT. |
| **Installed (global)** | Executable at `${GLOBAL_BIN}/selfmanaged` (default `GLOBAL_BIN=/usr/local/bin`) observed by install-detect SSOT. |
| **Force / reinstall** | `FORCE_REINSTALL=1` from `--force` (and related force wiring in `app_main`). Required only for deliberate replace, not for ensure. |

### 2.2 Split meaning of empty argv

1. **Interactive 0-argv** (`TTY=1`, `JSON=0`, `QUIET=0`, no command token) **MUST** call `app_default` (the main menu in `requirement-shell-cli-default-interaction.md`). **MUST NOT** install-ensure and **MUST NOT** route to `app_help`. `--debug` is excluded from the command count: `safe-rm --debug` on a terminal is still interactive 0-argv and **MUST** open that menu, with debug on.  
2. When there is **no command token** and the run is **non-interactive** (no TTY, or `JSON=1`, or `QUIET=1`), `app_main` **MUST** run **install-ensure** (`inst_self_install`) — **MUST NOT** open the menu, **MUST NOT** route to `app_help`. `--debug` does not turn that path into the menu.  
3. Explicit `help` remains the full-usage path for help text. Off a terminal, `menu` and `main` print that help.  
4. Bootstrap **MUST** always call `app_main "$@"` so pipe one-liners reach this contract (no `${0##*/}` product-name gate).  
5. Non-interactive empty argv **MUST NOT** require the user to pass `install` or `install --force` merely because a previous ensure already succeeded.

### 2.2.1 Specializee contract (bootstrap origin → specialized B)

When this product is used as **bootstrap origin A** for a specialized product **B** (A→B only; never reverse-copy):

| Rule | MUST | MUST NOT |
|------|------|----------|
| Empty argv on B | Keep **non-interactive Type O install-ensure**. Interactive empty argv **MAY** be the numbered menu when that product claims it | Hijack **non-interactive** empty argv for a menu or for domain full-setup; hang a menu under `curl \| sh` |
| Domain setup verb | Use an explicit command (e.g. `run`, `setup`, domain verb catalog) | Treat bare `curl \| sh` / empty argv as host domain install |
| Case A helper | If B copies `inst_maybe_install` as first-install SSOT, quiet/json **MUST** call `inst_self_install` and return its status | Copy a helper that `return 0` under quiet/json without placing the binary |
| Tests | Isolate `HOME`, `USER_BIN`, and **`GLOBAL_BIN`** so host `/usr/local/bin/${APP_NAME}` does not shadow lifecycle CI | Assume empty `HOME` alone hides a real global install |
| Dest mode | Global dest **0755** (other-read shebang); local **0700**; keep `inst_cli_dest_mode` | `chmod +x` on `mktemp` staging; leave global dest **0711** (other logins: `/bin/sh: Permission denied`) |

**Rationale:** Specializees that rebind empty argv to interactive host setup break the online-install contract and confuse install-ensure with domain ops. Host-mutating domain work belongs under explicit verbs with privilege gates (see CLI interface specializee contract).

### 2.3 Normative case matrix

**Interactive empty argv** (`TTY=1`, not quiet, not json) is the numbered menu. It does **not** use the matrix below.

**Non-interactive** empty argv, `FORCE_REINSTALL=0`:

| Case | Detect condition (project) | Empty argv, `FORCE_REINSTALL=0` | Empty argv / install with force |
|------|----------------------------|--------------------------------|---------------------------------|
| **A. Not installed** | `inst_is_installed` false | Install into privilege-correct path (§2.4) | Same first-time install |
| **B. Installed — local** | User binary present via detect SSOT | Success no-op: already installed; no re-copy/re-download; **no help** | `inst_self_install` replace (copy or download per `$0`; user path when non-root) |
| **C. Installed — global** | Global binary present via detect SSOT | Success no-op: already installed; no re-download; **no help** | Re-download/replace (global path when root / global binary policy) |

**Already-installed rules (Cases B and C, force off):**

1. Exit status **MUST** be `0`.  
2. Human mode **MUST** use `out_success` with an **already installed** message (via `inst_self_install` no-op path).  
3. Human mode **MAY** add `out_info` tips that `--force` / `self-update` are for **deliberate** reinstall or upgrade — **MUST NOT** imply force is required for a normal one-liner re-run.  
4. JSON mode **MUST** use structured success (`out_json` success type) with already-installed message — **MUST NOT** emit help JSON.  
5. Detect **MUST** treat either global or local managed binary as installed when that is how `inst_is_installed` / `inst_get_version` resolve paths (project SSOT today prefers global when executable there, else user path).

### 2.4 Case A — not installed (modes)

When **no managed binary** is present, empty argv **MUST** place the program (or fail closed). People picture:

| Mode | What a person sees | What MUST happen |
|------|--------------------|------------------|
| **Interactive** (real terminal on stdin+stdout, not quiet/json) | The numbered list (**1** remove-guard, **8** self-management, **9** Exit) | `app_default`. Place only if the person chooses **87** / `self-install` |
| **Non-interactive** (no terminal / `curl \| sh`) | An auto-install message | Place the program (`inst_maybe_install` non-TTY branch → `inst_self_install`) |
| **Quiet or JSON** | No question | `inst_self_install` (no prompt). Failure **MUST** be non-zero. **MUST NOT** return success without placing. |
| **Failure** (network, checksum, I/O) | An error | Non-zero exit; no fake success; no help-only output |

**Dispatcher vs helper (same outcome):**

| Path | Quiet / JSON, not installed | Human TTY, not installed | Pipe, not installed |
|------|-----------------------------|--------------------------|---------------------|
| `app_main` empty argv | **MUST** call `inst_self_install` directly | **MUST** call `app_default` (no place side effect) | **MUST** call `inst_self_install` |
| `inst_maybe_install` itself | **MUST** call `inst_self_install` and return its status. **MUST NOT** `return 0` without placing | Note + `prompt_yes_no` then `inst_self_install` | Auto-install message + `inst_self_install` |

Empty-argv quiet/json in `app_main` is **not** a license for the helper to no-op. Products copied from this bootstrap that route Case A **only** through the helper **MUST** still place the binary under quiet/json.

**Placement privilege:**

| Invoker | Target |
|---------|--------|
| root (`id -u` 0), e.g. `curl … \| sudo sh` | `${GLOBAL_BIN}/selfmanaged` → `/usr/local/bin/selfmanaged` |
| non-root | `${USER_BIN}/selfmanaged` → `${HOME}/.local/bin/selfmanaged` |

### 2.5 Equivalence to explicit `install`

| Invocation | Contract |
|------------|----------|
| Empty argv | Same ensure semantics as `self-install` for Cases A/B/C (copy vs download per `$0`) |
| `self-install` | Explicit CLI place; same detect / no-op / force. How: `requirement-shell-cli-self-install.md` |
| `install` | Compatibility alias of `self-install` (no payload on this product) |
| `self-install --force` / `install --force` | Deliberate replace |
| `help` | Usage only — **not** empty-argv default |

### 2.6 Forbidden empty-argv outcomes

1. Dump full help when Case B or C applies.  
2. Silent success when Case A should install (or when Case B/C should acknowledge already installed).  
3. Require `--force` solely because detect says installed.  
4. Blind re-download every empty-argv run without force.  
5. Basename-gate main so `curl \| sh` never hits the empty-argv branch.  
6. Detect only one of global/local incorrectly so a present local install is treated as Case A (or the reverse) contrary to `inst_*` SSOT.  
7. Silent success from `inst_maybe_install` under quiet/json when Case A should place the binary.

### 2.7 Implementation Notes (this project)

| Item | Value for selfmanaged |
|------|------------------------|
| **Empty-argv type** | **Type O — Online-install** (install-ensure; not Type N help-default) |
| **Product / binary** | `selfmanaged` (`APP_NAME`) |
| **Ship unit** | `src/selfmanaged` |
| **Dispatcher** | `app_main` — empty-argv block **before** flag/command parse default help |
| **Install ensure** | `inst_self_install` on non-interactive / quiet / json empty argv (copy when `$0` is a script) |
| **Interactive empty argv** | `app_default` (numbered menu). No place side effect |
| **Friendly helper** | `inst_maybe_install` remains for direct callers (TTY confirm / non-TTY auto). Empty argv no longer calls it. Quiet/JSON through the helper **MUST** still call `inst_self_install` |
| **Detect SSOT** | `inst_is_installed` ← `inst_get_version` |
| **Global path** | `GLOBAL_BIN` default `/usr/local/bin` |
| **Local path** | `USER_BIN` default `${HOME}/.local/bin` |
| **Force wiring** | `--force` → `FORCE=1` and `FORCE_REINSTALL=1` in `app_main` |
| **Output SSOT** | `out_success` / `out_info` / `out_json` / errors via `out_*` |
| **Channel** | `SCRIPT_URL` (compose from `REPO_USER` / `REPO_NAME` / `APP_NAME`) for download path inside install |
| **Tests** | `tests/test_cli.sh` (Case A failure when not installed); `tests/test_install_lifecycle.sh` (Case B local + Case C global already-installed → not help; **TP-LC-10** / **TP-INST-MAYBE-01** helper under QUIET/JSON). |

#### Dispatcher algorithm (normative sketch)

```text
app_main:
  if [ $# -eq 0 ]; then
    if JSON or QUIET or TTY is not 1:
      inst_self_install; exit $?   # non-interactive Case A/B/C; no prompt
    else
      app_default; exit $?         # interactive numbered menu
    fi
  fi
  # else parse flags/commands; menu|main → app_default
```

#### Message contract (already installed, human)

- Success: `${APP_NAME} is already installed.` (or equivalent via `out_success`)  
- Optional info: force / `self-update` only for deliberate reinstall or upgrade  
- **MUST NOT** print the full `app_help` usage body on this path

### 2.8 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): One-liner re-runs must not look like broken install or force unnecessary reinstall.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Empty argv has one meaning for not-installed, local, and global.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Dual install paths + `curl \| sh` + TTY.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` owns empty-argv before help default.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): Case A auto under pipe; optional TTY confirm.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protection Rule against help-fallback regression.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Real failures non-zero; healthy re-runs success with clear text.  
- **Intentional:** Help is never the empty-argv default for this install CLI.  
- **Anti-fragile:** Global and local detect; idempotent second one-liner.  
- **Over-protect:** Do not “simplify” empty-argv back to `COMMAND:=help` after first install.  
- **SSOT:** `inst_is_installed` / `inst_self_install` / `inst_maybe_install` / `out_*`.  
- **Idempotent ensure:** Case B/C force off → already installed, exit 0.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Route non-interactive empty argv to `app_help`, or open the numbered menu on a pipe / quiet / json empty argv. Interactive empty argv **MUST** be the menu.  
2. Require `--force` for a healthy already-installed empty-argv re-run (local or global).  
3. Handle only Case A and leave B/C as accidental help fallthrough.  
4. Break dual-path detect so local or global installs are misclassified.  
5. Blindly reinstall on every empty-argv run without `FORCE_REINSTALL`.  
6. Exit 0 with no install and no already-installed acknowledgment when detect says installed.  
7. Reintroduce a basename-only gate that skips `app_main` under `curl \| sh`.  
8. Bypass `out_*` for empty-argv user messages.  
9. Contradict this file in peer requirements by documenting “already installed → help” as normative empty-argv behavior.  
10. Let `inst_maybe_install` return success under quiet/json when Case A should place the binary (silent skip). Empty-argv bypass in `app_main` does **not** excuse a helper that no-ops.  
11. Copy this helper into a specialized product as Case A SSOT while keeping a quiet/json `return 0` without `inst_self_install`.  
12. Download when empty argv `$0` is a readable script (that how lives on `requirement-shell-cli-self-install.md`).

**Violating this rule is a critical zero-arg / online-install regression.**

---

## 5. Definition of done

This requirement is satisfied when all of the following hold:

1. Non-interactive empty argv + not installed → Case A self-install path (quiet / json / pipe auto). Interactive empty argv opens the numbered menu and does not place. Quiet/json through the helper **MUST** place or fail closed — not `return 0` without install. Script `$0` copies; interpreter `$0` downloads.  
2. Empty argv + local install present + force off → already-installed success; not help; no re-download.  
3. Empty argv + global install present + force off → already-installed success; not help; no re-download.  
4. Empty argv + install failure → non-zero exit.  
5. `--force` only for deliberate reinstall; not required for ensure.  
6. `help` works when invoked explicitly.  
7. Tests cover Case A failure (not installed, bad channel) and already-installed not-help for local (Case B) and global (Case C).  
8. **TP-LC-10** / **TP-INST-MAYBE-01:** not installed + QUIET/JSON through `inst_maybe_install` places or fail closed.  
9. Changes cite `requirement-shell-cli-zero-arguments`.

### Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-LC-10** / **TP-INST-MAYBE-01** | `tests/test_install_lifecycle.sh` | have |

**Map:** `reviews/test-plan.md`

---

## Under command line for normal user only

This product may run on Termux, Git Bash, Windows cmd, or the same class (this login only).

**This requirement:** empty command line still means **install or re-check install for this login**. On that class, Case A **MUST** place into `USER_BIN` (this login). **MUST NOT** escalate, wrap `sudo`, or recommend `sudo curl | sh` as the empty-argv path there. Git Bash and Windows cmd **MUST NOT** invoke Termux `pkg`.

| MUST | MUST NOT |
|------|----------|
| Empty-argv ensure as this login | Empty argv that tries to become root on Termux / Git Bash / Windows cmd |
| Quiet/json helper still places or fail closed | Add an admin-privilege empty-argv branch |

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Full command surface; empty-argv row must match this SSOT |
| `docs/requirements/requirement-shell-cli-self-install.md` | How empty argv places (copy vs download; dest 0755/0700) |
| `docs/requirements/requirement-shell-idempotency.md` | Ensure re-run / force boundary |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY vs pipe for Case A |
| `docs/requirements/requirement-shell-self-management.md` | self-update / uninstall (not empty-argv default) |
| `docs/requirements/requirement-shell-output-requirements.md` | out_* / JSON purity |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Integrity on install download path |
| `src/selfmanaged` | Implementation (`app_main`, `inst_*`) |
| `tests/test_cli.sh`, `tests/test_install_lifecycle.sh` | Regression coverage |

---

## 7. Revision history

| Date | Change | Author / agent |
|------|--------|----------------|
| 2026-07-14 | Initial Active v1.0.0: empty argv = install-ensure for not-installed / local / global; forbid help fallthrough | Grok (owner request) |
| 2026-07-14 | v1.1.0: Classify product as Type O (online-install) under dual-type empty-argv template model | Grok |
| 2026-08-11 | v1.2.0: Specializee contract — empty argv stays Type O; domain setup uses explicit verbs; test GLOBAL_BIN isolation | Grok (gitlab-nginx specialize reflection) |
| 2026-09-17 | v1.3.0: Empty argv ensure handler is `inst_self_install` (script `$0` copies; dest 0700/0755); points at `requirement-shell-cli-self-install` | Grok (owner request) |

---

**Last Updated**: 2026-09-17  
**Owner**: selfmanaged project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 6, 16, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).

