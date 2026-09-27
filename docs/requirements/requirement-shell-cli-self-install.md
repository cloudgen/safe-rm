**file**: docs/requirements/requirement-shell-cli-self-install.md  
**Status**: Active (Version 1.0.0)  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the product law for **how selfmanaged places itself**: the `self-install` verb, and **empty argv** (`curl | sh`, quiet, json, TTY confirm). That path puts the program file on disk (or says it is already there). This product has **no payload** — there is no package install or host daemon on this path.

`install` is a **compatibility alias** of `self-install` (same CLI place). It is **not** a second payload verb.

### 1.1 Human-facing

**In one sentence:** A pipe with no extra words copies **this program** into your bin; if you already ran the file (`./src/selfmanaged self-install`), it copies **that file** and does not download.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | First-time pipe, or a checkout you already have | `curl … \| sh` · `./src/selfmanaged self-install` |
| The other role | Channel refresh of an already-managed binary | `selfmanaged self-update` |
| Not this file | Checksum math; uninstall confirm; TTY vs pipe prompt rules | `requirement-shell-automatic-checksum.md` · `requirement-shell-self-management.md` |

| Includes | Excludes |
|----------|----------|
| `self-install`; empty argv CLI place; copy when `$0` is the script; dest mode 0700 local / 0755 global | Payload `pkg` / host daemon start; dumping help as empty-argv default |
| Already-installed success no-op | Treating `$0` = `/bin/bash` as “the script” |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./src/selfmanaged` | Ship unit | Copy source when you run it |
| `selfmanaged self-install` | Command | Same ensure as a pipe with no args |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First install from the internet | The pipe has no human to answer. `$0` is the shell (`sh` / `bash` / …). The program **downloads** itself into user bin, or system bin if you are root. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/selfmanaged/main/src/selfmanaged \| /bin/sh` |
| Install from a file you already have | `$0` is the script, not `sh`. Copy that file into bin. No network. Interactive yes/no still copies this file — it does **not** re-download. | `./src/selfmanaged self-install` · `sh ./src/selfmanaged self-install` · `./src/selfmanaged` (TTY yes) |
| Name the place verb | Online self-manageable place is **`self-install`**, not a payload `install`. `install` still works as the same place. | `selfmanaged self-install` |

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
2. `selfmanaged self-install` **MUST** call `inst_self_install`.  
3. `selfmanaged install` **MUST** call `inst_self_install` (alias; this product has no payload). Dual mention: `requirement-shell-cli-interface.md`.  
4. Interactive empty argv **MUST** open the numbered menu (`requirement-shell-cli-default-interaction.md`) and **MUST NOT** place as a side effect. Choosing **87** or `self-install` on that menu **MUST** call `inst_self_install` (copy when `$0` is the script).  
5. `inst_maybe_install` **MAY** still confirm on a TTY when a caller invokes the helper directly. Empty argv **MUST NOT** call it.

### 2.2 `$0` source

| `$0` | Place |
|------|-------|
| Interpreter basename `sh` `bash` `dash` `ash` `zsh` `ksh` `mksh` `yash` `posh` `csh` `tcsh` `fish` `busybox` (login dash prefix stripped; paths like `/bin/sh` and `/bin/bash` count) | Download from `SCRIPT_URL` + companion digest |
| Readable regular file (`./src/selfmanaged`, `sh /path/to/selfmanaged`) | **Copy** that file — **MUST NOT** download |
| Basename-only, `command -v` finds a readable file | Copy that file |

**MUST NOT** treat `$0` as product identity for whether main runs. A pipe **MUST** still reach `app_main`.

### 2.3 Copy (no download)

When `$0` is a script source:

1. Resolve an absolute readable path of the running script.  
2. `mktemp -t` under isolated `TMPDIR` (storage resolver): leaf `selfmanaged-XXXXXX`.  
3. `cp` source → stage.  
4. `chmod` dest mode on stage **before** `mv`. **MUST NOT** `chmod +x` alone (that mints **0711** from `mktemp` **0600**).  
5. `mv` onto `INSTALL_PATH`.  
6. `chmod` dest mode on dest.  
7. **MAY** run PATH rc ensure (`path_add_shell`). **MUST NOT** fetch `SCRIPT_URL`. **MUST NOT** require network.

### 2.4 Dest mode

| Invoker | Path | Mode |
|---------|------|------|
| root | `${GLOBAL_BIN}/selfmanaged` | **0755** |
| non-root | `${USER_BIN}/selfmanaged` | **0700** |

Global **0755** is other-read + exec so unprivileged `/bin/sh` can **open** the shebang file. Local **0700** is this-login owner-only. **MUST NOT** leave local dest **0711** or global dest **0700** / **0711** on this path.

The same dest mode **MUST** apply after the download/atomic path (pipe / `self-update` reuse of download helpers).

### 2.5 Already installed

Force off → `out_success` already installed; exit 0; no re-copy; no download. Force → replace via copy or download per `$0`.

### 2.6 Implementation Notes (this project)

| Item | Value for selfmanaged |
|------|-------------------|
| **Handler** | `inst_self_install` |
| **Detect** | `inst_argv0_is_shell_interpreter` · `inst_resolve_self_script` |
| **Copy** | `inst_self_install_copy_from_script` |
| **Dest mode helper** | `inst_cli_dest_mode` → **0755** root / **0700** non-root |
| **Download peer** | `inst_perform_install_download_*` + `inst_perform_install_atomic_install` then dest-mode chmod |
| **PATH** | `path_add_shell` on this path (CLI on PATH) |
| **Dispatcher** | `app_main` empty-argv NI / quiet / json → `inst_self_install`; interactive empty argv → `app_default`; command `self-install` same; `install` alias same |
| **TTY first-shot** | Numbered menu (`app_default`). Place only when the person chooses **87** / `self-install` |
| **Global bin** | `/usr/local/bin` |
| **Local bin** | `${HOME}/.local/bin` |
| **Channel** | `SCRIPT_URL` default `https://raw.githubusercontent.com/cloudgen/selfmanaged/main/src/selfmanaged` (pipe / interpreter `$0` only) |
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
| empty argv (pipe) | `curl -fsSL https://raw.githubusercontent.com/cloudgen/selfmanaged/main/src/selfmanaged \| /bin/sh` |
| `self-install` | `selfmanaged self-install` · `./src/selfmanaged self-install` |
| `install` (alias) | `selfmanaged install` · `./src/selfmanaged install` |
| empty argv (TTY checkout) | `./src/selfmanaged` then yes → copy from that file |

### 2.x Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Copy does not need a live channel; download still verifies.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Place verb is **`self-install`**; `$0` script vs interpreter has one meaning.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Checkout works offline.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` owns empty argv.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): TTY may confirm; a yes still copies the running file.  
- **CIAO Principle 22 – File modes** (https://github.com/cloudgen/ciao): 0755 global / 0700 local.

## Under command line for normal user only

When Termux, Git Bash, Windows cmd, or the same class is detected: Type 1/2 unused; no in-tool sudo; no `sudo curl | sh`. **This requirement:** self-install stays this-login place (local **0700**). Git Bash and Windows cmd do not invoke Termux `pkg` on this path.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail closed on copy/download I/O.  
- **Intentional:** One meaning for empty argv; `self-install` is the place name.  
- **Anti-fragile:** Script `$0` does not need curl.  
- **Over-protect:** Interpreter list; dest-mode table; no `chmod +x` 0711 trap.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Route non-interactive empty argv to `inst_perform_install` as the default (download-always).  
2. Download when `$0` is a readable script.  
3. Treat interactive TTY yes as an online re-download when `$0` is the script.  
4. Leave local dest **0711** or global dest **0700**/**0711** on this path.  
5. Drop `self-install` from help or dispatcher.  
6. Basename-gate main so `curl | sh` never reaches `inst_self_install`.  
7. Invent a payload `install` that empty argv also runs (this product has no payload).  
8. Strip **Under command line for normal user only**.  
9. Specialize B from this origin while restoring `chmod +x` or dropping `inst_cli_dest_mode` / **TP-SI-07** / **TP-SI-08**.

## 5. Definition of done

1. NI empty argv places the CLI (copy or download per `$0`).  
2. `./src/selfmanaged self-install` with a dead `SCRIPT_URL` still places (copy).  
3. Interactive TTY yes with script `$0` copies (no download).  
4. Local dest **0700**; global dest **0755**.  
5. Already-installed no-op.  
6. Help lists `self-install`.  
7. Tests **TP-SI-01** .. **TP-SI-08**.  
8. Changes cite this file.

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
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY confirm vs pipe auto |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Integrity on **download** path only |
| `./src/selfmanaged` | Implementation |

**Last Updated**: 2026-09-17  
**Owner**: selfmanaged project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
