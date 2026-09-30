**file**: docs/requirements/requirement-shell-script-coding.md
**Status**: Active (Version 1.0.1)
**Area**: shell
**Key**: `requirement-shell-script-coding`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **specialize-in home** for POSIX `/bin/sh` coding lessons on this product. **Without this file, portable learned lessons arrive raw** (agents treat coding skills as product law).

It owns **how** the single-file ship unit `./src/safe-rm` is written: shebang, quoting, function headers, prefix discipline (by pointer), and what this product must **not** add (`util_sudo`, a password ladder, admin helpers on Termux). The one allowed `sudo` is the Linux measure-2 re-exec.

**Scope:** POSIX `/bin/sh` coding contract for `./src/safe-rm`.  
**Out of scope (own-or-point):** Command catalog (`requirement-shell-cli-interface.md`); `out_*` catalog (`requirement-shell-output-requirements.md`); prefix table body (`requirement-shell-modular-function-design.md`); TTY / prompt bodies (`requirement-shell-interactive-vs-noninteractive.md`); scratch roots (`requirement-shell-cli-storage.md`). This file **points**; it does **not** duplicate those tables.

### 1.1 Human-facing

**In one sentence:** People still install **one** POSIX `/bin/sh` file; maintainers must write that file so it runs on a small Unix, a pipe, and a phone userspace — not as a bash-only or root-only tool.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Maintainer editing `./src/safe-rm` | Add a helper with an `out_` / `inst_` / `app_` prefix |
| The other role | Operator running as themselves (Termux, Git Bash, Windows cmd, Linux) | `safe-rm about` with no root |
| Not this file | What verbs mean; how JSON is shaped; where scratch lives | Peer shell requirements |

| Includes | Excludes |
|----------|----------|
| Shebang `/bin/sh`, quoting, headers, “do not capture `read`” | A second copy of the `out_*` catalog or Case A/B/C matrix |
| The one Linux measure-2 `sudo` re-exec, specified in the domain requirement | Inventing `util_sudo` / `useradd` because a mold shows them |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/safe-rm` | Program file people install | Live coding contract |
| `safe-rm help` | Command | Listed verbs stay Type-0 self-care |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Add a helper | Give it a prefix, a header, and safe defaults. Print through `out_*`. | Edit `./src/safe-rm`; run `./tests/run_dry_run.sh` |
| Run on a phone userspace | Keep **normal user privilege**. Do not call `sudo` on Termux. | `safe-rm about` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Specialize-in intention (sacred)

1. **MUST** treat this file as the home for portable POSIX-sh coding lessons specialized onto **this** product.  
2. **MUST NOT** tell agents to follow coding skills or law molds as product behavioral authority. Product source comments cite **live** `requirement-*.md` only.  
3. **MUST** own-or-point: if a peer already owns a slice, this file **points** and does **not** paste the full body.

### 2.2 Shebang, dialect, quoting

4. **MUST** keep shebang `#!/bin/sh`.  
5. **MUST** prefer POSIX syntax: quote `"${VAR}"`; use `command -v`; use `.` not `source`.  
6. **MUST NOT** introduce arrays, `[[ ]]`, process substitution, or here-strings as **new** product law.  
7. **SHOULD** use `: "${VAR:=default}"` at the top of functions that read those variables.  
8. **MUST NOT** switch the product to `set -e` / `set -eu` as a “cleanup.” Existing `set -u` with documented defaults stays (see `requirement-shell-interactive-vs-noninteractive.md` / suite `env -u HOME`).

### 2.3 Function headers and prefixes (point)

9. **MUST** use the prefix families owned by `requirement-shell-modular-function-design.md` (`out_`, `inst_`, `app_`, `util_`, `ver_`, `path_`, `prompt_`).  
10. Domain helpers **MUST** use the prefix `srm_` owned by `requirement-domain-safe-rm.md`. **MUST NOT** add a second product-ops prefix.  
11. New **critical** helpers **SHOULD** keep a CIAO header (General Purpose + do-not-simplify when the helper is reusable). **MUST NOT** strip existing Protection Zones.  
12. Product-source `ALIGNMENT` / `See` lines **MUST** cite only live `docs/requirements/requirement-*.md` paths.

### 2.4 Output, TTY, temps, prompts (point)

13. Product messages **MUST** go through `out_*` (`requirement-shell-output-requirements.md`).  
14. Interactive capability **MUST** be measured outside functions; helpers **consume `TTY`** (`requirement-shell-interactive-vs-noninteractive.md`).  
15. Scratch files **MUST** use the storage resolver / `TMPDIR` (`requirement-shell-cli-storage.md`). **MUST NOT** invent `$$` temp names.  
16. **MUST NOT** capture `prompt_ask` / `prompt_yes_no` / any `read` helper with `$()` or backticks.

### 2.5 In-tool sudo (one re-exec)

17. The only in-tool `sudo` is the Linux measure-2 re-exec in `requirement-domain-safe-rm.md` §2.0.5. This product **MUST NOT** add a `util_sudo` wrap, `useradd`, or a sudoers emitter. There is **no** separate `requirement-shell-sudo-command`; the allow table is that section.
18. **MUST NOT** copy a Type 1 password-sudo ladder from portable molds into `./src/safe-rm`. The program **MUST NOT** read the password. `sudo` prompts on its own terminal.
19. A further `sudo` outside that measure **MUST** be written into §2.0.5 first. It **MUST NOT** live only as a wrapper in the script. Termux, Git Bash, Windows cmd, and macOS **MUST NOT** call `sudo`.

### 2.6 Implementation Notes (this project)

| Field | Value (safe-rm) |
|-------|---------------------|
| **Ship unit** | `./src/safe-rm` (POSIX `/bin/sh`, single file) |
| **Shebang** | `#!/bin/sh` |
| **Primary dialect** | POSIX `/bin/sh` (dash / bash-as-sh / BusyBox ash intended) |
| **Inherited non-POSIX** | Existing `local` in some helpers is **bootstrap inheritance** — **MUST NOT** mass-rewrite; **SHOULD NOT** add new `local` when a POSIX assignment works |
| **`set -u`** | Present at script top with documented defaults (`HOME`, privilege, storage) |
| **In-tool sudo** | Ship unit `1.0.12` has one Linux measure-2 re-exec (`${SRM_SUDO:-sudo}` in §2.0.5 of the domain requirement). No `util_sudo`, no password reader, no sudoers file |
| **Domain prefix** | `srm_` for the guard (`requirement-domain-safe-rm.md`). Specializee anchors `DOMAIN_*` stay for a later product |
| **Coding-style owner** | **this file** |
| **Peer pointers** | modular-function-design (prefixes); output-requirements (`out_*`); interactive (TTY / `prompt_*`); cli-storage (scratch root) |

---

## Under command line for normal user only

This product may run on Termux, Git Bash, Windows cmd, or the same class (this login only).

**This requirement:** helpers in `./src/safe-rm` stay **normal user privilege** except the one Linux measure-2 re-exec in `requirement-domain-safe-rm.md` §2.0.5. Do **not** add `util_sudo`, wrap `apt`/`dnf`, create a dedicated system user, or recommend `sudo curl | sh`. Git Bash, Windows cmd, Termux, and macOS **MUST NOT** call `sudo`. Git Bash and Windows cmd **MUST NOT** invoke Termux `pkg`. Termux named `pkg` as this login remains ordinary (not admin privilege) **if** a future Termux-ish REQ is added; this product does **not** wrap `pkg` today.

On detect of that class:

| MUST | MUST NOT |
|------|----------|
| Keep helpers at this-login privilege | Enable a dedicated system user, or a password ladder inside this program |
| Keep coding helpers Type-0 self-care | Implement the portable Type 1 password-sudo ladder |
| Document Type 1/2 **unused** | Scatter `sudo` outside the Linux measure-2 re-exec |

---

## 3. Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Without this file, portable lessons arrive raw.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): POSIX dialect and no silent sudo.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Survive dash, pipe install, Termux, Git Bash.  
- **CIAO Principle 4 / 20 – Over-protect** (https://github.com/cloudgen/ciao): Do not strip headers or add elevation “for completeness.”  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Core portable; Implementation Notes filled.

---

## 4. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Assume the next editor will paste a bashism or a `sudo` example.  
- **Intentional:** Own-or-point — one home for coding lessons, not a second output/prefix law.  
- **Anti-fragile:** Prefer POSIX; do not mass-rewrite inherited `local`.  
- **Over-protect:** Protection Rule below is sacred.

---

## 5. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Delete this file while the workspace remains software-development.  
2. Treat coding skills or molds as product-source authority.  
3. Change the shebang away from `#!/bin/sh` without an authorized redesign.  
4. Add `util_sudo`, `useradd`, or a `sudo` call that is not the Linux measure-2 re-exec.  
5. Duplicate full `out_*`, prefix, TTY, or storage tables here.  
6. Capture `prompt_*` / `read` helpers with `$()`.  
7. Strip Protection Zones or “simplify” defensive headers.  
8. Implement admin-privilege or dedicated-account helpers on Termux / Git Bash / Windows cmd.  
9. Mass-rewrite inherited `local` as a drive-by POSIX purity pass.

**Violating any of these is a critical regression.**

---

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-01** (syntax `sh -n`) | `tests/test_cli.sh` | have |
| **TP-SETU-01** (`env -u HOME`) | `tests/test_cli.sh` | have |
| Static: no `util_sudo`. The safe-rm re-exec is `${SRM_SUDO:-sudo}` and is not a bare `sudo` command. **TP-CS-01** still rejects `util_sudo` on the Type 0 snapshot | `tests/test_cli.sh` (**TP-CS-01**); `tests/test_two_layer.sh` | have |

**Map:** `reviews/test-plan.md`

---

## 7. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-class-software-dev.md` | Class residual points here |
| `docs/requirements/requirement-shell-modular-function-design.md` | Prefix table owner |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_*` owner |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY / `prompt_*` owner |
| `docs/requirements/requirement-shell-cli-storage.md` | Scratch root owner |
| `docs/requirements/requirement-shell-cli-interface.md` | Command surface |
| `./src/safe-rm` | Implementation under test |

---

**Last Updated**: 2026-09-30 (1.0.1 — ship unit `1.0.12` has the one Linux measure-2 re-exec; other hosts do not call it)
**Owner**: safe-rm project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 4, 20, 21 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
