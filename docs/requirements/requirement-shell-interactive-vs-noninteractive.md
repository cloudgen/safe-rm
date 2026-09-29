**file**: docs/requirements/requirement-shell-interactive-vs-noninteractive.md  
**Status**: Active (Version 1.1.1)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **project Single Source of Truth** for how the safe-rm **POSIX shell CLI** behaves in **interactive** (human + TTY) versus **non-interactive** (automation, `curl | sh`, CI/CD, pipes, `--json` / often `--quiet`) environments.

It defines interactive vs non-interactive behavior for this shell project (global flags + `prompt_*` + TTY detection—not a Node Config singleton).

**Scope:** Mode detection signals, prompt policy, auto-install vs confirm, force/skip rules, interaction with quiet/json/debug and output SSOT.  
**Out of scope (cited, not re-owned):** Full command catalog (`requirement-shell-cli-interface.md`); output function catalog (`requirement-shell-output-requirements.md`); self-update integrity (`requirement-shell-self-management.md`); idempotency matrix (`requirement-shell-idempotency.md`).

### 1.1 Human-facing

**In one sentence:** On a real terminal, empty argv opens the numbered menu, and uninstall may **ask**; under a pipe, CI, `--quiet`, or `--json` the tool **must never wait for a key** — a non-interactive first install still **places** the program; uninstall without `--force` **must stop**.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | A person at a terminal, or a script / `curl \| sh` with nobody to answer | `safe-rm` on a TTY vs `curl … \| sh` |
| The other role | Machine flags (`--json`, `--quiet`) and `--force` for deliberate uninstall | `safe-rm --json version` · `safe-rm --force self-uninstall` |
| Not this file | Empty-argv case table (peer); `out_*` printers; command catalog | `requirement-shell-cli-zero-arguments.md` |

| Includes | Excludes |
|----------|----------|
| When to ask vs auto-install vs refuse uninstall | Inventing a second “are we interactive?” check inside every helper |
| `prompt_yes_no` / `prompt_ask` as the only confirm/read path | Raw `read` in command bodies |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/safe-rm` | Program file | `TTY` at startup; `prompt_*`; `inst_maybe_install` |
| `safe-rm --quiet` / `--json` | Flags | No prompts; first install must still place |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Install from a pipe | Nobody can type yes. The tool **places** the program and prints a short auto-install note. | `curl -fsSL …/safe-rm \| /bin/sh` |
| Open the menu on a real terminal | Empty argv opens the numbered menu. It does not ask to place and it does not place. | `safe-rm` (no args, terminal) |
| Uninstall without `--force` off a terminal | The tool **must not** delete. JSON says confirm is required. | `safe-rm --json self-uninstall` |

Jargon: a **TTY** here means “this login has a real terminal on stdin and stdout.” Measure that **once** at startup (`TTY`); helpers **read `TTY`**.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Definitions (portable)

| Mode | Definition |
|------|------------|
| **Interactive** | A human is driving the tool with a usable terminal (**TTY**). Confirmations, colors, and onboarding prompts are allowed when not overridden by machine flags. |
| **Non-interactive** | No human is available to answer prompts: pipes, CI/CD, `curl \| sh`, config management, Docker build, scripts, or machine flags such as `--json` (and often `--quiet`). The tool **must never hang waiting for input** and must apply **documented safe automatic defaults**. |

### 2.2 Detection (mode SSOT for shell)

For shell CLIs without a separate Config class, the **mode SSOT** is the **global flag / TTY block** at script top + values set by the dispatcher after parsing:

| Signal | Variable / check | Meaning |
|--------|------------------|---------|
| TTY | `TTY=1` when stdin and stdout are terminals. Measure `[ -t 0 ]` and `[ -t 1 ]` **once in the main process, outside functions** (near Config). Helpers **read `TTY`**. **MUST NOT** use a second live `[ -t` inside a function as the sole “may we prompt?” gate. | Interactive UX possible |
| Quiet | `QUIET=1` (`--quiet` / `-q`) | Suppress non-essential human chatter |
| JSON | `JSON=1` (`--json`; implies quiet) | Machine output; no human hang; no human banners |
| Debug | `DEBUG=1` (`--debug`) | Extra stderr diagnostics; suppressed under JSON |
| Force | `FORCE=1` / `FORCE_REINSTALL=1` (`--force`) | Skip confirms / force reinstall / allow policy-gated downgrade |
| Explicit interactive override | `INTERACTIVE=1` (optional env) | Rare override when low-level TTY checks are flaky (prompt_ask only) |

**Rules:**

1. Prompt, color, and hang-sensitive decisions **MUST** respect these globals and/or the shared `prompt_*` helpers—not ad-hoc `read` scattered in domain logic.  
2. After global flags are parsed in `app_main`, subsequent code **MUST** see the updated `QUIET` / `JSON` / `FORCE` / `DEBUG` values.  
3. Do **not** invent a second parallel mode system in individual commands.  
4. Helpers (`prompt_*`, `inst_maybe_install`, `out_*` color) **MUST** consume process `TTY`. Command business logic **MUST** call `prompt_*` instead of re-implementing prompt guards. A `--file` vs stdin probe **MAY** read current `[ -t 0 ]` only when named as a data-source check — **not** as interactive-capability SSOT.

```text
flags + TTY / environment
           │
           ▼
  Global mode SSOT (QUIET / JSON / DEBUG / FORCE / TTY)
           │
     ┌─────┴─────┐
     ▼           ▼
interactive   non-interactive
(human UX)    (no hang, safe defaults)
```

### 2.3 Behavioral differences (portable)

#### 2.3.1 Interactive mode (TTY, not quiet/json)

| Allowed / expected | Notes |
|--------------------|--------|
| Colored / prefixed human output | Via `out_*` when TTY and not quiet/json |
| Helpful messages and about diagnostics | Full human surface |
| Confirmation prompts for destructive actions | Via `prompt_yes_no` unless `--force` |
| Onboarding / install prompt when not installed | When product supports it |
| Value prompts with defaults | Via `prompt_ask` |

#### 2.3.2 Non-interactive mode (automation)

| Required | Forbidden |
|----------|-----------|
| **Never wait** for user input | Bare `read` without mode guards |
| **Safe automatic defaults** documented per command | Assuming someone will type “yes” |
| Suppress or skip prompts under quiet/json | Hanging on confirm in CI |
| Support `--json` purity (output requirement) | Mix human text into JSON stdout |
| Non-zero exit on critical failure | Silent hang that looks like a stuck job |
| Work under `curl \| sh`, Docker, CI | Requiring a full TTY for core ensure ops that claim automation support |

#### 2.3.3 Flag interactions

| Flag / state | Interactive impact |
|--------------|--------------------|
| `--json` | Force quiet-style human suppression; no prompts; structured stdout; errors on stderr |
| `--quiet` | No prompts via `prompt_*`; reduced chatter; errors (and warnings per output requirement) still surface |
| `--force` | Skip uninstall confirm; allow reinstall/downgrade policy paths |
| `--debug` | stderr diagnostics; never block; suppressed under JSON |
| Non-TTY stdin/stdout | Treat as non-interactive for prompts |

### 2.4 Prompt SSOT (portable)

| Helper | Role |
|--------|------|
| `prompt_yes_no` | **Only** yes/no confirmation path for destructive/optional confirms |
| `prompt_ask` | **Only** simple value prompt path with default |
| `out_msg_n` | Prompt fragment without newline (human only) |

**Rules:**

1. Never implement user-visible confirms with raw `printf` + `read` outside `prompt_*`.  
2. Under `JSON=1` or `QUIET=1`, prompts **MUST NOT** block: return default / no / cancel per documented policy.  
3. Without TTY (unless `INTERACTIVE=1` where designed), prompts **MUST NOT** block.  
4. Destructive non-interactive actions that would have required confirm **MUST** either:  
   - require `--force` (fail closed without it), or  
   - document an explicit safe auto-proceed policy (e.g. zero-arg install under pipe).

### 2.5 Implementation Notes (this project)

| Item | Value for safe-rm |
|------|------------------------|
| **Product / binary** | `safe-rm` |
| **Implementation** | `src/safe-rm` |
| **Mode globals** | `TTY`, `QUIET`, `JSON`, `DEBUG`, `FORCE`, `FORCE_REINSTALL` |
| **TTY init** | `[ -t 0 ] && [ -t 1 ] && TTY=1` near config block |
| **Flag parse SSOT** | `app_main` |
| **Prompt SSOT** | `prompt_yes_no`, `prompt_ask` |
| **Output SSOT** | `out_*` (`requirement-shell-output-requirements.md`) |
| **No Node Config singleton** | Shell globals + helpers are the mode SSOT for this project |

#### Command-level interactive matrix (normative)

| Command / path | Interactive (TTY, not quiet/json) | Non-interactive / quiet / json |
|----------------|-----------------------------------|--------------------------------|
| Zero-arg, interactive (`TTY=1`, not quiet/json) | Numbered menu (`app_default`). No place side effect | — |
| Zero-arg, non-interactive / quiet / json | — | `inst_self_install` (place, or already-installed success). **MUST NOT** open the menu. **MUST NOT** print help |
| `self-install` / `install` (alias) | Place CLI with human `out_*` messages; copy when `$0` is the script | No prompt; honor force for replace; JSON structured results |
| `self-uninstall` | `prompt_yes_no` unless `--force` | Without force: fail closed with explicit “requires --force” (JSON: `out_json_error` / `confirm_required`); never pretend user cancelled; with `--force`: remove without confirm |
| `self-update` / `version-check` | Human status messages | No prompts; fail loud if `SCRIPT_URL` missing; JSON structured results |
| `about` / `version` / `help` | Human diagnostics / help | Quiet: suppress human; JSON: structured object only |
| Colors | When `TTY=1` and not quiet/json | No color under quiet/json |

#### `prompt_yes_no` contract (this project)

| Condition | Behavior |
|-----------|----------|
| `JSON=1` or `QUIET=1` | Return **1** (no / cancel)—never `read` |
| `TTY` is not `1` | Return **1** (no)—never `read` |
| `TTY=1` and not quiet/json | Prompt via `out_msg_n`; yes → 0, else → 1 |
| Uninstall without force + non-interactive | Confirm fails → uninstall cancelled (safe default) |
| Uninstall with `--force` | Skip confirm entirely |

Sample (consume `TTY`; never live `[ -t` as the gate):

```sh
prompt_yes_no() {
    : "${JSON:=0}" : "${QUIET:=0}" : "${TTY:=0}"
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        return 1
    fi
    if [ "${TTY}" -ne 1 ]; then
        return 1
    fi
    out_msg_n "${1} (y/N)? "
    read -r answer || true
    case "${answer}" in
        [Yy]*) return 0 ;;
        *)     return 1 ;;
    esac
}
```

#### `prompt_ask` contract (this project)

| Condition | Behavior |
|-----------|----------|
| `JSON=1` or `QUIET=1` | Return **default** without `read` |
| `TTY` is not `1` (and `INTERACTIVE` ≠ 1) | Return **default** without `read` |
| `TTY=1` interactive | Show current/default via `out_*`, then `read` |

Sample (consume `TTY`):

```sh
prompt_ask() {
    : "${JSON:=0}" : "${QUIET:=0}" : "${TTY:=0}" : "${INTERACTIVE:=0}"
    message="${1-}"; default="${2-}"
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        printf '%s' "${default}"
        return 0
    fi
    if [ "${TTY}" -ne 1 ] && [ "${INTERACTIVE}" -ne 1 ]; then
        printf '%s' "${default}"
        return 0
    fi
    out_msg_n "${message}: "
    read -r answer || true
    [ -z "${answer}" ] && printf '%s' "${default}" || printf '%s' "${answer}"
}
```

#### `inst_maybe_install` contract (this project)

| Condition | Behavior |
|-----------|----------|
| Already installed (force off) | Success no-op; do not ask again |
| Quiet or JSON | **No prompt.** **MUST** call `inst_self_install` and return its status. **MUST NOT** `return 0` without placing (unless already-installed no-op). Empty-argv quiet/json in `app_main` also calls `inst_self_install` directly — **both** paths **MUST** place. Copied products **MUST NOT** keep a helper that skips install under quiet/json. |
| `TTY=1` interactive (not quiet/json) | Prompt install yes/no via `prompt_yes_no`; yes → `inst_self_install` (copy when `$0` is the script) |
| Non-TTY (pipe / automation) | **Auto-install** with a clear human message when not quiet/json → `inst_self_install` |

This dual policy is intentional: **pipe / quiet / json first-install proceeds**; **destructive uninstall does not** without `--force`.

**Honesty (this ship unit, 2026-09-17):** `prompt_yes_no`, `prompt_ask`, and `inst_maybe_install` consume process `TTY`. Quiet/JSON Case A through the helper calls `inst_self_install` (SM-BUG-01 still: place, not skip).

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Never hang automation; destructive ops fail closed without force.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Explicit matrices for install vs uninstall vs flags.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Works under `curl | sh`, CI, and human TTY.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): First-class mode policy.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protected `prompt_*` helpers; no raw read regressions.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Prefer cancel over destructive auto-action when intent is ambiguous; prefer auto-install for classic one-liner when not installed.  
- **Intentional:** Mode globals + `prompt_*` ownership is documented and stable.  
- **Anti-fragile:** Non-TTY and quiet/json paths always terminate without stdin.  
- **Over-protect:** Do not “simplify” prompt guards or replace `prompt_yes_no` with ad-hoc `read`.  
- **Pair with output SSOT:** Prompts use `out_msg_n` / `out_*`; JSON never shows prompts.  
- **Pair with CLI interface:** Flag meanings stay aligned with `requirement-shell-cli-interface.md`.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Add `read` or confirmation prompts outside `prompt_ask` / `prompt_yes_no` without updating this requirement.  
2. Allow prompts to run under `--json` or `--quiet`.  
3. Hang on prompts when stdin/stdout are not TTYs (except explicit `INTERACTIVE=1` for `prompt_ask` only).  
4. Break the invariant that `--json` forces quiet-style non-interactive human suppression.  
5. Auto-delete / uninstall without confirm **or** `--force` in interactive design—and must not auto-uninstall in non-interactive without `--force`.  
6. Remove the zero-arg non-TTY auto-install path for classic `curl | sh` without an explicit requirement change.  
7. Bypass `out_*` for prompt text (raw `echo`/`printf` user messages).  
8. Scatter ad-hoc TTY/mode logic that contradicts the global flag SSOT and `prompt_*` contracts.  
9. Hardcode project-specific secrets or release URLs into prompt strings.  
10. Let `inst_maybe_install` return success under `--quiet` / `--json` without calling `inst_perform_install` when the program is not installed.  
11. Re-test `[ -t 0 ]` / `[ -t 1 ]` inside helpers as the sole interactive gate; helpers **MUST** consume process `TTY`.

**Supporting non-interactive environments cleanly is mandatory for CIAO compliance.**

---

## 5. Definition of done (shell interactive vs non-interactive)

Mode-related work for safe-rm is **not done** if any of the following fail:

1. No code path blocks on `read` under `--json`, `--quiet`, or non-TTY (except documented `INTERACTIVE=1` value prompt).  
2. Destructive uninstall without `--force` does not silently proceed in non-interactive mode.  
3. Zero-arg install-ensure supports automation (`curl | sh` / quiet/json): not-installed installs; already-installed (local or global) success no-op without help (`requirement-shell-cli-zero-arguments.md`). Quiet/json through `inst_maybe_install` **MUST** place or fail closed.  
4. All confirms go through `prompt_yes_no`.  
5. Colors only when TTY and not quiet/json.  
6. JSON/human contracts remain aligned with `requirement-shell-output-requirements.md`.  
7. Changes cite `requirement-shell-interactive-vs-noninteractive`.

---

## Under command line for normal user only

This product may run on Termux, Git Bash, Windows cmd, or the same class (this login only).

**This requirement:** TTY confirm and pipe auto-install stay **this login**. Helpers consume `TTY`; they **MUST NOT** use `TTY` as a gate to start `sudo`. Linux measure 2 calls `sudo` because the host is Linux and the invoker is not root (`requirement-domain-safe-rm.md` §2.0.5), including when stdin is a pipe. `sudo` reads its own password prompt from the terminal. A refused `sudo` leaves measure 1 in place. Termux, Git Bash, Windows cmd, and macOS **MUST NOT** start `sudo`. Git Bash and Windows cmd **MUST NOT** invoke Termux `pkg`.

| MUST | MUST NOT |
|------|----------|
| Prompt / pipe paths as this login | Password-sudo ladder copied from portable Type 1 molds |

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Flags and commands |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv install-ensure matrix |
| `docs/requirements/requirement-shell-cli-self-install.md` | TTY yes copies `$0` when it is the script |
| `docs/requirements/requirement-shell-output-requirements.md` | quiet/json/debug output contracts |
| `docs/requirements/requirement-shell-self-management.md` | Uninstall confirm / force policy |
| `docs/requirements/requirement-shell-idempotency.md` | Re-run safety under automation |
| `docs/requirements/index.md` | Registry SSOT |
| `./src/safe-rm` | Implementation under test |

---

**Last Updated**: 2026-09-29 (1.1.1 — `TTY` is not the gate for the Linux measure-2 `sudo`)  
**Owner**: safe-rm project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 16, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
