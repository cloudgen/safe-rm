**file**: docs/requirements/requirement-shell-cli-self-install.md  
**Status**: Active (Version 1.2.0)  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the product law for **how safe-rm places itself**: the `self-install` verb, and **non-interactive empty argv** (`curl | sh`, quiet, json). That path puts the program file on disk (or says it is already there). This product has **no payload** — there is no package install or host daemon on this path.

`install` is a **compatibility alias** of `self-install` (same CLI place). It is **not** a second payload verb.

### 1.1 Human-facing

**In one sentence:** A pipe with no extra words copies **this program** into your bin; if you already ran the file (`./src/safe-rm self-install`), it copies **that file** and does not download.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | First-time pipe, or a checkout you already have | `curl … \| sh` · `./src/safe-rm self-install` |
| The other role | Channel refresh of an already-managed binary | `safe-rm self-update` |
| Not this file | Checksum math; uninstall confirm; TTY vs pipe prompt rules | `requirement-shell-automatic-checksum.md` · `requirement-shell-self-management.md` |

| Includes | Excludes |
|----------|----------|
| `self-install`; empty argv CLI place; copy when `$0` is the script; dest mode 0700 local / 0755 global | Payload `pkg` / host daemon start; dumping help as empty-argv default |
| Already-installed success, then setup when this login may | Treating `$0` = `/bin/bash` as “the script” |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/safe-rm` | Ship unit | Copy source when you run it |
| `safe-rm self-install` | Command | Same ensure as a pipe with no args |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First install from the internet | The pipe has no human to answer. `$0` is the shell (`sh` / `bash` / …). The program **downloads** itself into user bin, or system bin if you are root. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm \| /bin/sh` |
| Install from a file you already have | `$0` is the script, not `sh`. Copy that file into bin. No network. Interactive yes/no still copies this file — it does **not** re-download. | `./src/safe-rm self-install` · `sh ./src/safe-rm self-install` · `./src/safe-rm` (TTY yes) |
| Name the place verb | Online self-manageable place is **`self-install`**, not a payload `install`. `install` still works as the same place. | `safe-rm self-install` |

Jargon: **Type O** (letter) means pipe / no-args **places the CLI**. That is not Type **0** (you run as yourself).

---

## 2. Core Rules / Requirements (Mandatory)

### 2.0 Specializee contract (bootstrap origin → specialized B)

When this product is **bootstrap origin A** for specialized product **B** (A→B only):

| Rule | MUST | MUST NOT |
|------|------|----------|
| Dest helper | Keep `inst_cli_dest_mode` + dest-mode `chmod` on copy **and** atomic download | Replace with `chmod +x` on `mktemp` 0600 |
| Global dest | `${GLOBAL_BIN}/B` mode **0755** (other-read shebang) | Leave **0711** / **0700** on a global dest (`/bin/sh: Permission denied` for other logins) |
| Local dest | `${USER_BIN}/B` mode **0700** | Collapse local **0700** into global **0755**, or the reverse |
| Tests | Keep **TP-SI-07** (no `chmod +x`) and **TP-SI-08** (isolated `GLOBAL_BIN` **0755**) when copying the Type 0 suite | Treat USER_BIN-only **0700** as proof that other users can open a global dest |
| Empty argv place | `inst_self_install` (or the same dest-mode atomic path) | Download-always `inst_perform_install` that still `chmod +x` |

**Rationale:** A dedicated login (for example a Type 2 system user) running a root-placed CLI needs **other-read** on `/usr/local/bin`. Execute-only **0711** is the shebang-open class (**PP-A-28**). Specializees copied from an older origin that used `chmod +x` reintroduce this on every `sudo curl \| sh`.

### 2.1 Route

1. When argv is empty and the run is **non-interactive** (no TTY, or `JSON=1`, or `QUIET=1`), `app_main` **MUST** call `inst_self_install` — **MUST NOT** call `inst_perform_install` as the empty-argv default, **MUST NOT** open a menu, **MUST NOT** call `app_help`.  
2. `safe-rm self-install` **MUST** call `inst_self_install`.  
3. `safe-rm install` **MUST** call `inst_self_install` (alias; this product has no payload). Dual mention: `requirement-shell-cli-interface.md`.  
4. Interactive empty argv **MUST** open the numbered menu (`requirement-shell-cli-default-interaction.md`) and **MUST NOT** place as a side effect. Choosing **87** or `self-install` on that menu **MUST** call `inst_self_install` (copy when `$0` is the script).  
5. `inst_maybe_install` **MAY** still confirm on a TTY when a caller invokes the helper directly. Empty argv **MUST NOT** call it.

### 2.2 `$0` source

| `$0` | Place |
|------|-------|
| Interpreter basename `sh` `bash` `dash` `ash` `zsh` `ksh` `mksh` `yash` `posh` `csh` `tcsh` `fish` `busybox` (login dash prefix stripped; paths like `/bin/sh` and `/bin/bash` count) | Download from `SCRIPT_URL` + companion digest |
| Any other `$0` (the file you ran: `src/safe-rm`, `./src/safe-rm`, `sh src/safe-rm`) | The file is local. **Copy** it. **MUST NOT** download. Unreadable → fail |

**MUST NOT** treat `$0` as product identity for whether main runs. A pipe **MUST** still reach `app_main`.

### 2.3 Copy (no download)

When `$0` is not a shell interpreter, the file is already on disk. **MUST NOT** fetch `SCRIPT_URL`.

1. Resolve a readable path of the running script (`$0`, or `command -v` when `$0` is a basename).  
2. Root (the operator already ran `sudo` on this command): `cp` that file into `${GLOBAL_BIN}/` (default `/usr/local/bin/`). The process is root, so this `cp` is the global place. The program **MUST NOT** invoke `sudo` itself.  
3. Not root: `cp` that file into `${USER_BIN}/` (default `${HOME}/.local/bin/`).  
4. `chmod` the dest mode on the placed file (**0755** global / **0700** local). **MUST NOT** `chmod +x` alone (that mints **0711**).  
5. **MUST** run **path-ensure** and **profile-ensure** (`path_add_shell`, which calls `path_ensure_profile`) for a non-root place, per §2.7. **MUST NOT** require network.
6. After the place finishes, including the already-installed success, run setup per `requirement-domain-safe-rm.md` §2.0.5. Measure 1 is this login. The place step itself **MUST NOT** invoke `sudo`. The only `sudo` is measure 2 on Linux, inside that setup, when this login is not root. A refused `sudo` leaves measure 1 in place and setup exits non-zero. The place has still succeeded.

`sudo src/safe-rm install --force` is the global copy. `src/safe-rm install` is the local copy. `--force` replaces a file that is already there. Without `--force`, an existing install is a success and does not copy again. Both still run setup when this login may.

### 2.4 Dest mode

| Invoker | Path | Mode |
|---------|------|------|
| root | `${GLOBAL_BIN}/safe-rm` | **0755** |
| non-root | `${USER_BIN}/safe-rm` | **0700** |

Global **0755** is other-read + exec so unprivileged `/bin/sh` can **open** the shebang file. Local **0700** is this-login owner-only. **MUST NOT** leave local dest **0711** or global dest **0700** / **0711** on this path.

The same dest mode **MUST** apply after the download/atomic path (pipe / `self-update` reuse of download helpers).

### 2.5 Already installed

Force off → `out_success` already installed; exit 0; no re-copy; no download. Force → replace via copy or download per `$0`. Either way, run setup when this login may (`requirement-domain-safe-rm.md`).

### 2.6 Implementation Notes (this project)

| Item | Value for safe-rm |
|------|-------------------|
| **Handler** | `inst_self_install` |
| **Detect** | `inst_argv0_is_shell_interpreter` · `inst_resolve_self_script` |
| **Copy** | `inst_self_install_copy_from_script` |
| **Dest mode helper** | `inst_cli_dest_mode` → **0755** root / **0700** non-root |
| **Download peer** | `inst_perform_install_download_*` + `inst_perform_install_atomic_install` then dest-mode chmod |
| **PATH** | `path_add_shell` on this path (CLI on PATH). §2.7: **path-ensure** writes the user-bin line; **profile-ensure** creates a missing `.profile` that sources `.bashrc` |
| **Dispatcher** | `app_main` empty-argv NI / quiet / json → `inst_self_install`; interactive empty argv → `app_default`; command `self-install` same; `install` alias same |
| **TTY first-shot** | Numbered menu (`app_default`). Place only when the person chooses **87** / `self-install` |
| **Global bin** | `/usr/local/bin` |
| **Local bin** | `${HOME}/.local/bin` |
| **Channel** | `SCRIPT_URL` default `https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm` (pipe / interpreter `$0` only) |
| **Tests** | `tests/test_cli.sh` **TP-SI-01** .. **TP-SI-06**; helper quiet/json still **TP-LC-10** / **TP-INST-MAYBE-01** |

#### Dispatcher sample

```sh
if [ $# -eq 0 ]; then
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ] || [ "${TTY}" -ne 1 ]; then
        inst_self_install
        exit $?
    fi
    app_default
    exit $?
fi
```

#### Invocation samples

| Verb | Sample |
|------|--------|
| empty argv (pipe) | `curl -fsSL https://raw.githubusercontent.com/cloudgen/safe-rm/main/src/safe-rm \| /bin/sh` |
| `self-install` | `safe-rm self-install` · `./src/safe-rm self-install` |
| `install` (alias) | `safe-rm install` · `sudo src/safe-rm install --force` (copies this file into `/usr/local/bin/`; no download) · `src/safe-rm install` (copies into `${HOME}/.local/bin/`) |
| empty argv (TTY checkout) | `./src/safe-rm` opens the numbered menu and does not place (`requirement-shell-cli-default-interaction.md`) |

### 2.x Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Copy does not need a live channel; download still verifies.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Place verb is **`self-install`**; `$0` script vs interpreter has one meaning.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Checkout works offline.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` owns empty argv.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): TTY may confirm; a yes still copies the running file.  
- **CIAO Principle 22 – File modes** (https://github.com/cloudgen/ciao): 0755 global / 0700 local.

### 2.7 Path-ensure and profile-ensure

Two named startup-file edits run together after a non-root place, and again from measure 1 of setup (`requirement-domain-safe-rm.md` §2.0.5). This login writes both. Neither calls `sudo`. The measure-2 child does not run them.

**Path-ensure** prepends the user bin, default `${HOME}/.local/bin`:

```sh
export PATH="${HOME}/.local/bin:$PATH"
```

Fish uses `set -gx PATH ${HOME}/.local/bin $PATH`. Each written file gets `# Added by safe-rm installer (VERSION)` immediately above that line. A second run does not append a second copy of that exact line. A mention of the directory in some other line is not “already present.”

| File | When it is missing | What is written |
|------|--------------------|-----------------|
| `${HOME}/.bashrc` | Create it, mode `0644`, owned by this login | The PATH block |
| `${HOME}/.zshenv` | Create it, mode `0644`, only when this login’s shell is zsh, or `ZSHENV` is set, or the file already exists | The PATH block |
| `${HOME}/.config/fish/config.fish` | Create the directory and the file | The Fish line |

Path-ensure **MUST NOT** write that line into `${HOME}/.profile`, `${HOME}/.zshrc`, `${HOME}/.bash_profile`, or `${HOME}/.zprofile`. It **MUST NOT** create `.bash_profile` or `.zprofile`. It **MUST NOT** prepend `/usr/local/bin` ahead of `${HOME}/.local/bin`, and **MUST NOT** write a `PATH` line into the pyenv shims directory or `/opt/homebrew`.

On the reported Mac, `PATH` already lists `${HOME}/.local/bin` ahead of `/bin`, and `/bin` ahead of `/usr/local/bin`. Path-ensure is what puts that user-bin line on `.bashrc` and, for zsh, on `.zshenv`, for a login that does not have it yet.

**Profile-ensure** is the rule for keeping the login profile. A missing `.profile` means a login `sh`, and a login `bash` that has no `.bash_profile` and no `.bash_login`, never reads `.bashrc`. The feature checks `${HOME}/.profile` (tests may retarget `PROFILE`).

| State | What this login does |
|-------|----------------------|
| Absent | Create it, mode `0644`, owned by this login, with the sample below. The sample sources `.bashrc`. It does **not** contain the PATH line |
| Present | Do **not** replace the body. A marker the operator wrote stays |

```sh
# BEGIN safe-rm profile source-bashrc
# Created so a bash login shell sources interactive rc.
if [ -n "${BASH_VERSION:-}" ]; then
    if [ -f "${HOME}/.bashrc" ]; then
        . "${HOME}/.bashrc"
    fi
fi
# END safe-rm profile source-bashrc
```

A second run creates the file once and does not append a second sample. Login bash reaches the path-ensure line because this sample sources `.bashrc`. Zsh reaches its line on `.zshenv`. This product does not add a `.zprofile` for that.

Uninstall removes the path-ensure blocks from `.bashrc`, `.zshenv`, and the Fish file only when `${HOME}/.local/bin` is empty (`requirement-shell-self-management.md`). It **MUST NOT** delete `.profile`, and it **MUST NOT** strip the profile-ensure sample.

## Under command line for normal user only

When Termux, Git Bash, Windows cmd, or macOS is detected: Type 1/2 unused; the place step does not call `sudo`; no `sudo curl | sh`. **This requirement:** self-install stays this-login place (local **0700**) and runs §2.7 path-ensure and profile-ensure. Measure 2's `sudo` is Linux-only and lives in `requirement-domain-safe-rm.md` §2.0.5. Git Bash and Windows cmd do not invoke Termux `pkg` on this path.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail closed on copy/download I/O.  
- **Intentional:** One meaning for empty argv; `self-install` is the place name.  
- **Anti-fragile:** Script `$0` does not need curl.  
- **Over-protect:** Interpreter list; dest-mode table; no `chmod +x` 0711 trap.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Route non-interactive empty argv to `inst_perform_install` as the default (download-always).  
2. Download when `$0` is not an interpreter, including when the local path cannot be read (fail instead).  
3. Treat interactive TTY yes as an online re-download when `$0` is the script.  
4. Leave local dest **0711** or global dest **0700**/**0711** on this path.  
5. Drop `self-install` from help or dispatcher.  
6. Basename-gate main so `curl | sh` never reaches `inst_self_install`.  
7. Invent a payload `install` that empty argv also runs (this product has no payload).  
8. Strip **Under command line for normal user only**.  
9. Specialize B from this origin while restoring `chmod +x` or dropping `inst_cli_dest_mode` / **TP-SI-07** / **TP-SI-08**.
10. Skip profile-ensure because `${HOME}/.profile` is missing, overwrite an existing `.profile` body, write the PATH line into `.profile` or `.zshrc`, or append a second copy of the exact user-bin line.
11. Call `sudo` from the place step. The Linux `sudo` re-exec belongs to setup measure 2, after this place.

## 5. Definition of done

1. NI empty argv places the CLI (copy or download per `$0`).  
2. `./src/safe-rm self-install` with a dead `SCRIPT_URL` still places (copy).  
3. Interactive TTY yes with script `$0` copies (no download).  
4. Local dest **0700**; global dest **0755**.  
5. Already-installed no-op.  
6. Help lists `self-install`.  
7. Tests **TP-SI-01** .. **TP-SI-08**.  
8. Changes cite this file.
9. A missing `${HOME}/.profile` is created once and sources `.bashrc`. It does not contain the PATH line. That line is in `.bashrc` once. A second run does not append it again and does not replace an existing `.profile` body.

### Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-SI-01** script `$0` copy, no network | `tests/test_cli.sh` | have |
| **TP-SI-02** local dest **0700** | `tests/test_cli.sh` | have |
| **TP-SI-03** NI empty argv is self-install (copy) | `tests/test_cli.sh` | have |
| **TP-SI-04** interpreter `$0` download | `tests/test_cli.sh` | have |
| **TP-SI-05** already-installed no-op | `tests/test_cli.sh` | have |
| **TP-SI-06** help lists `self-install` | `tests/test_cli.sh` | have |
| **TP-SI-07** no live `chmod +x`; dest helper present | `tests/test_cli.sh` | have |
| **TP-SI-08** isolated GLOBAL_BIN **0755** (heals **0711**) | `tests/test_cli.sh` | have |

**Map:** `reviews/test-plan.md`

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv Type O ensure (points here for how) |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `self-install` / `install` alias |
| `docs/requirements/requirement-shell-self-management.md` | `self-update` still downloads; `self-uninstall` |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | Numbered menu vs pipe auto |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Integrity on **download** path only |
| `./src/safe-rm` | Implementation |

**Last Updated**: 2026-09-29 (1.2.0 — §2.7 names **profile-ensure** and **path-ensure**. A missing `.profile` sources `.bashrc` and is not overwritten. The PATH line stays on `.bashrc`, `.zshenv`, and Fish)  
**Owner**: safe-rm project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
