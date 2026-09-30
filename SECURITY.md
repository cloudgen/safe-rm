# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| **1.0.15** (current) | Yes — a finished remove names the caller and each path. On a terminal those names are italic |
| **1.0.14** | Yes — `reset` points the system `rm` at an existing `origin-rm`. Root or the Linux `sudo` re-exec does that. `origin-rm` stays |
| **1.0.13** | Yes — `.` and `..` are refused when the directory would otherwise be allowed. Name the directory to remove it |
| **1.0.12** | Yes — the remove check's scratch directory is mode `0700`, including when umask would leave `mktemp -d` at `0600` |
| **1.0.11** | Yes — setup writes `~/.local/bin` first (home `rm` → `safe-rm`, original saved as `origin-rm`). On Linux it then uses `sudo` to move `/usr/bin/rm` and `/bin/rm`. macOS leaves `/bin/rm`. A missing `~/.profile` is created so login bash sources `~/.bashrc` |
| **1.0.10** | Yes — a root `self-install` or `self-update` runs `setup`, so `rm` is the file just placed. On Termux, this login's place runs that setup |
| **1.0.9** | Yes — on Termux, `$PREFIX/var` and the other prefix matches of the Linux system directories are refused |
| **1.0.8** | Yes — on Termux, `setup` moves `$PREFIX/bin/rm` as this login and does not call `sudo` |
| **1.0.7** | Yes — `setup` checks `/usr/bin/rm` and `/bin/rm`, including a BusyBox `rm` |
| **1.0.6** | Yes — a local `install` copies this file and does not download |
| **1.0.5** | Yes — on the command named `rm`, a bare word is a path |
| **1.0.4** | Yes — `rm version` on this guard prints this program's version, so a link named `version` is not removed |
| **1.0.3** | Yes — `rm version` on this older guard still tries to remove a file named `version` |
| **1.0.2** | Yes — the guard people type as `rm` could stay on this older file after a later install |
| 1.0.1 | Yes |
| 1.0.0 | Yes |

## Remove guard

`rm -rf` of any account home is refused. A folder inside any account home may be removed. An operand whose final component is `.` or `..` is refused even when that directory would otherwise be allowed. Name the directory itself. `/home`, `/usr/bin`, and the system directories named in the product README are refused. One refused path cancels the whole command. `--dry-run` does not call `origin-rm`. A finished `self-install` or `self-update` runs `safe-rm setup`. Measure 1 writes `~/.local/bin/safe-rm`, a `rm` symlink, and `origin-rm` as this login. On Linux, measure 2 re-execs this program through `sudo` and moves `/usr/bin/rm` and `/bin/rm` to `origin-rm`. If `sudo` fails, the home guard stays and those system paths stay as they were. macOS does not move `/bin/rm`. On Alpine those paths differ: `rm` is `/bin/rm` (BusyBox) and `/usr/bin/rm` may be absent. That symlink is not renamed. On Termux, `which rm` is `$PREFIX/bin/rm` (`/data/data/com.termux/files/usr/bin/rm`). This login runs that swap and does not call `sudo`. `/usr/bin/rm` and `/bin/rm` stay untouched. The same blacklist applies under `$PREFIX`: `$PREFIX/var` and the other prefix matches of those system directories are refused, and a folder inside `$PREFIX/var` may be removed. A missing `~/.profile` is created so a bash login sources `~/.bashrc`. Tests of the before/after table use a scratch directory and do not delete a directory.

## Reporting a Vulnerability

Please **do not** open a public issue for security-sensitive reports when a private channel is available.

**Maintainer contact (email):** `cloudgen.wong@gmail.com`

- Source of contact: product **author-email** SSOT in [`LICENSE.md`](./LICENSE.md) (Copyright line).  
- Prefer email for vulnerability details, reproduction steps, and impact.  
- You should receive an acknowledgment when the report is received and actionable.  
- Do not include exploit weaponization guides in public channels.

For non-sensitive questions, product usage, or general bugs that are not security-sensitive, use normal project channels (for example public issues on the project repository when available).

## Security Design Principles (CIAO)

This project follows **[CIAO](https://github.com/cloudgen/ciao)** / **CIAO-Lite** defensive design. Security-relevant intent:

| Letter | Principle | Security application |
|--------|-----------|----------------------|
| **C** | **Caution** | Assume hostile input, hostile networks, and misconfiguration. Validate install paths, checksums, and privilege boundaries; fail closed on integrity mismatch when a digest is present. |
| **I** | **Intentional** | Privilege typing (Type 0 self-management), channel URL (`SCRIPT_URL`), checksum modes, and the cache folder (per login, per process, with a separate persistence directory) are deliberate and documented—not accidental. Prefer clear “why” over silent magic. |
| **A** | **Anti-fragile** | Survive harsh environments (minimal containers, missing tools, non-interactive `curl \| sh`). Prefer automatic SHA-256 sidecar checks when available, least privilege for day-to-day use, and recoverable failure over brittle trust. |
| **O** | **Over-protect** | Defense in depth on critical paths (integrity verify before install/update, isolated scratch roots, CIAO Protection Zones in the ship unit, loud failure). Do not “simplify away” safety for brevity. |

Full principles: [CIAO Defensive Programming](https://github.com/cloudgen/ciao) · agent contract: [CIAO-Lite](https://github.com/cloudgen/ciao-lite).

This section describes **design posture**. It is **not** a claim of third-party certification (ISO, OWASP “compliant”, etc.).

## Scope notes

- Preferred language for reports: English.  
- Out of scope: social engineering of third parties, physical attacks, spam.  
- Online install integrity: automatic `${SCRIPT_URL}.sha256` (SHA-256) when present; optional strict `CHECKSUM` pin — see [`README.md`](./README.md). Same-channel digests prove **consistency** of script + companion on that channel; they are **not** a claim of cryptographic signing or third-party authenticity.  
- Scratch/cache paths are resolved per user (`APP_NAME` + username isolation); install staging uses the effective root as `TMPDIR` — see README Environment and product law `requirement-shell-cli-storage`.  
- Related product docs: [`README.md`](./README.md), [`LICENSE.md`](./LICENSE.md), [`CHANGELOG.md`](./CHANGELOG.md).
