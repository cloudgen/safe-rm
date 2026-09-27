# Requirements index

**Product:** safe-rm (POSIX `/bin/sh` Type 0 CLI plus a guarded `rm`, specialized from selfmanaged)  
**Workspace state:** Specialized product law (not blank genesis); **software-development** class; one Active domain SSOT.  
**Updated:** 2026-09-27 (each lifecycle verb is also its `--` switch; `rm version` is this program's version)

| ID / key | Title | Area | Status | Path | Updated |
|----------|-------|------|--------|------|---------|
| requirement-actor-role-subject | Who may run the menu, the guard, and setup (the origin-rm check) | shell | Active | `requirement-actor-role-subject.md` | 2026-09-27 |
| requirement-class-software-dev | Software-development class law + residual stack (posix-sh, no package tool) | class | Active | `requirement-class-software-dev.md` | 2026-09-06 |
| requirement-shell-automatic-checksum | Automatic companion-digest integrity (transparent link/value/result; CHECKSUM not help/about) | shell | Active | `requirement-shell-automatic-checksum.md` | 2026-09-06 |
| requirement-shell-cli-default-interaction | Main menu (interactive 0-argv, including --debug alone, opens it; the command named rm does not) | shell | Active | `requirement-shell-cli-default-interaction.md` | 2026-09-27 |
| requirement-shell-cli-interface | Shell CLI interface (commands, flags, dispatch, modes; each command is also `--command`; command name rm takes origin-rm switches) | shell | Active | `requirement-shell-cli-interface.md` | 2026-09-27 |
| requirement-shell-cli-self-install | CLI self-place (`self-install`; script `$0` copy; dest 0755/0700) | shell | Active | `requirement-shell-cli-self-install.md` | 2026-09-17 |
| requirement-shell-cli-storage | Cache folder (Linux shm → tmp → `~/.cache`; Git Bash tmp → AppData; Mac tmp → Library/Caches → `~/cache`) and persistence `${HOME}/.local/${APP_NAME}`; silent tier miss | shell | Active (1.1.0) | `requirement-shell-cli-storage.md` | 2026-09-27 |
| requirement-shell-cli-zero-arguments | Empty argv: interactive numbered menu; otherwise Type O install-ensure; basename rm is the remove | shell | Active | `requirement-shell-cli-zero-arguments.md` | 2026-09-27 |
| requirement-shell-idempotency | Shell idempotency / re-run safety for ensure-style ops | shell | Active | `requirement-shell-idempotency.md` | 2026-09-17 |
| requirement-shell-interactive-vs-noninteractive | Interactive vs non-interactive / `curl\|sh` behavior | shell | Active | `requirement-shell-interactive-vs-noninteractive.md` | 2026-09-17 |
| requirement-shell-modular-function-design | Single-file modular function design (prefixes, zones) | shell | Active | `requirement-shell-modular-function-design.md` | 2026-09-17 |
| requirement-shell-output-requirements | Central `out_*` output SSOT (stdout/stderr, modes; `@key` raw nested JSON) | shell | Active | `requirement-shell-output-requirements.md` | 2026-09-06 |
| requirement-shell-script-coding | POSIX `/bin/sh` coding-style specialize-in home (without it, portable lessons arrive raw) | shell | Active | `requirement-shell-script-coding.md` | 2026-09-06 |
| requirement-shell-self-management | Self-management lifecycle (version-check, update, uninstall, about) | shell | Active | `requirement-shell-self-management.md` | 2026-09-17 |
| requirement-domain-safe-rm | Protected rm (swap system rm to this guard, origin-rm kept, restore; the command named rm accepts origin-rm switches including -rf; lifecycle verbs on that command are this program, not files; any home directory refused; a folder inside any home allowed; --dry-run) | domain | Active | `requirement-domain-safe-rm.md` | 2026-09-27 |

**Rules for agents:**

1. Treat rows above as the **live product-law inventory** for safe-rm. Shell rows are the inherited Type 0 law. `requirement-domain-safe-rm` is the current domain SSOT.  
2. **Do not invent** additional `requirement-*.md` paths — verify on disk and add a registry row in the same change when creating one.  
3. Product source comments cite **only** these live requirement files (or future registered ones) — never `template-*` / `skill-*` as behavioral authority.  
4. This versioned surface lists **requirement rows only** — do not dump templates / skills / terminologies / incidents path inventories here (git-surface; INC-20260712-005).  
5. Keep Status and Path in sync with each file’s header when status changes.  
6. **Registry discipline (summary only):** invent no paths; same-change file+row; empty registry valid at genesis; this file stays **requirement rows only** (no harness tree dumps).  
7. **Class gate:** software-development requires exactly one Active `requirement-class-software-dev.md` (this registry includes it).

When adding a requirement: append a row, create the file under `docs/requirements/`, keep Status in sync with the file header.
