# Requirements index

**Product:** safe-rm (POSIX `/bin/sh` Type 0 CLI plus a guarded `rm`)  
**Workspace state:** Specialized product law (not blank genesis); **software-development** class; one Active domain SSOT.  
**Updated:** 2026-09-29 (Two layers: home `~/.local/bin` first, then Linux system `rm` through an internal `sudo`. macOS does not move `/bin/rm`. **Profile-ensure** creates a missing `.profile` that sources `.bashrc`. **Path-ensure** writes the user-bin line on `.bashrc` and `.zshenv`.)

| ID / key | Title | Area | Status | Path | Updated |
|----------|-------|------|--------|------|---------|
| requirement-actor-role-subject | Who may run the menu, the guard, and setup (measure 1 is this login; Linux measure 2 is a `sudo` re-exec; Termux `$PREFIX/bin/rm` is this login with no `sudo`; macOS does not move `/bin/rm`) | shell | Active | `requirement-actor-role-subject.md` | 2026-09-29 |
| requirement-class-software-dev | Software-development class law + residual stack (posix-sh, no package tool) | class | Active | `requirement-class-software-dev.md` | 2026-09-06 |
| requirement-shell-automatic-checksum | Automatic companion-digest integrity (transparent link/value/result; CHECKSUM not help/about) | shell | Active | `requirement-shell-automatic-checksum.md` | 2026-09-06 |
| requirement-shell-cli-default-interaction | Main menu (interactive 0-argv, including --debug alone, opens it; the command named rm does not) | shell | Active | `requirement-shell-cli-default-interaction.md` | 2026-09-27 |
| requirement-shell-cli-interface | Shell CLI interface (commands, flags, dispatch, modes; each command is also `--command`; on the command named rm a bare word is a path and the `--` switch stays the command; setup is the two-layer guard, Linux measure 2 via `sudo`) | shell | Active | `requirement-shell-cli-interface.md` | 2026-09-29 |
| requirement-shell-cli-self-install | CLI self-place (`self-install`; script `$0` copy; dest 0755/0700; **profile-ensure** creates a missing `.profile` that sources `.bashrc`; **path-ensure** writes `.bashrc` and `.zshenv`) | shell | Active | `requirement-shell-cli-self-install.md` | 2026-09-29 |
| requirement-shell-cli-storage | Cache folder (Linux shm → tmp → `~/.cache`; Git Bash tmp → AppData; Mac tmp → Library/Caches → `~/cache`) and persistence `${HOME}/.local/${APP_NAME}`; silent tier miss | shell | Active (1.1.0) | `requirement-shell-cli-storage.md` | 2026-09-27 |
| requirement-shell-cli-zero-arguments | Empty argv: interactive numbered menu; otherwise Type O install-ensure; basename rm is the remove; that place does not call `sudo` on Termux, Git Bash, Windows cmd, or macOS | shell | Active | `requirement-shell-cli-zero-arguments.md` | 2026-09-29 |
| requirement-shell-idempotency | Shell idempotency / re-run safety for ensure-style ops (profile-ensure creates a missing `.profile` once and keeps an existing body; Linux measure 2 may re-enter through `sudo` and must not move `origin-rm` again) | shell | Active | `requirement-shell-idempotency.md` | 2026-09-29 |
| requirement-shell-interactive-vs-noninteractive | Interactive vs non-interactive / `curl\|sh` behavior (`TTY` is not the gate for the Linux measure-2 `sudo`) | shell | Active | `requirement-shell-interactive-vs-noninteractive.md` | 2026-09-29 |
| requirement-shell-modular-function-design | Single-file modular function design (prefixes, zones; no `util_sudo` family) | shell | Active | `requirement-shell-modular-function-design.md` | 2026-09-29 |
| requirement-shell-output-requirements | Central `out_*` output SSOT (stdout/stderr, modes; `@key` raw nested JSON) | shell | Active | `requirement-shell-output-requirements.md` | 2026-09-06 |
| requirement-shell-script-coding | POSIX `/bin/sh` coding-style specialize-in home (without it, portable lessons arrive raw; the one `sudo` is the Linux measure-2 re-exec) | shell | Active | `requirement-shell-script-coding.md` | 2026-09-29 |
| requirement-shell-self-management | Self-management lifecycle (version-check, update, uninstall, about; path-ensure cleanup stays off `.profile`; the profile-ensure sample is kept) | shell | Active | `requirement-shell-self-management.md` | 2026-09-29 |
| requirement-domain-safe-rm | Protected rm (two layers: `${HOME}/.local/bin` first, then on Linux `/usr/bin/rm` and `/bin/rm` moved to `origin-rm` through an internal `sudo` when not root; macOS does not move `/bin/rm` and does not call `sudo`; Termux `$PREFIX/bin/rm` is this login with no sudo; Alpine `/bin` and `/usr/bin` both checked; Termux blacklist; origin-rm switches including -rf; a lifecycle `--` switch on the command named rm is this program and a bare word is a path; any home refused; a folder inside any home allowed; --dry-run) | domain | Active | `requirement-domain-safe-rm.md` | 2026-09-29 |

**Rules for agents:**

1. Treat rows above as the **live product-law inventory** for safe-rm. Shell rows are the inherited Type 0 law. `requirement-domain-safe-rm` is the current domain SSOT.  
2. **Do not invent** additional `requirement-*.md` paths — verify on disk and add a registry row in the same change when creating one.  
3. Product source comments cite **only** these live requirement files (or future registered ones) — never `template-*` / `skill-*` as behavioral authority.  
4. This versioned surface lists **requirement rows only** — do not dump templates / skills / terminologies / incidents path inventories here (git-surface; INC-20260712-005).  
5. Keep Status and Path in sync with each file’s header when status changes.  
6. **Registry discipline (summary only):** invent no paths; same-change file+row; empty registry valid at genesis; this file stays **requirement rows only** (no harness tree dumps).  
7. **Class gate:** software-development requires exactly one Active `requirement-class-software-dev.md` (this registry includes it).

When adding a requirement: append a row, create the file under `docs/requirements/`, keep Status in sync with the file header.
