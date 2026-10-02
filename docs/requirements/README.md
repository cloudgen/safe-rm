# Requirements

Authoritative product and engineering requirements for this project live here.

**Current state (2026-10-02 — safe-rm 1.0.20 adds front row **5** language, thirteen codes, leaf `${HOME}/.local/${APP_NAME}/language` (domain `1.2.21` only points at that requirement); safe-rm 1.0.19 does not read `/etc/passwd` or `getent passwd` onto the refusal list; the login home, `/home`, and a folder under `/home` outside this login stay refused (domain `1.2.20`); safe-rm 1.0.18 leaves a remove on `INT`, `HUP`, or `TERM`, refuses a missing scratch directory instead of calling it an empty path, and removes this process's cache leaf on exit (domain `1.2.19`, storage `1.1.2`); safe-rm 1.0.17 hides the finished-remove success line unless `--verbal` (domain `1.2.18`); safe-rm 1.0.16 implements domain law through 1.2.11, the 1.2.13 scratch-directory mode `0700`, the 1.2.14 refusal of a final `.` or `..`, the 1.2.15 `reset` that points the system `rm` at an existing `origin-rm`, the 1.2.16 success line that names the caller and each path, and the 1.2.17 fallback that uses a mode-`0700` subdirectory of the cache folder when `mktemp` is absent or cannot create a directory; storage law is `1.1.2`; domain law 1.2.12 and self-install 1.2.1 add the PATH block that puts `/usr/local/bin` next when `/bin` is ahead of it, and that block is not in the ship unit yet):** **One** Active class requirement (`requirement-class-software-dev`), **fourteen** Active shell requirements (actor-role-subject, automatic-checksum, CLI default-interaction, CLI interface, **cli-language**, **cli-self-install**, **cli-storage**, CLI zero-arguments, idempotency, interactive vs noninteractive, modular design, output, **script-coding**, self-management), and **one** Active domain SSOT (`requirement-domain-safe-rm`). Registry: `index.md` (must stay in sync). Ship unit `src/safe-rm`. Product version SSOT: `VERSION="1.0.20"` in that file. Do **not** invent additional requirement paths without a real ownership gap — verify on disk and register new files in `index.md` in the same change.

## Purpose

- **Plan mode** designs work by reading and **updating** these docs — not only the session `plan.md`.
- **Implement** delivers code and docs that **trace** to requirement IDs.
- **Review** verifies delivery against requirements **and** defensive (CIAO) checklists.

## Layout

| Path | Role |
|------|------|
| `docs/requirements/index.md` | Registry of all requirements (IDs, status, owners) — keep in sync with files |
| `docs/requirements/requirement-*.md` | CIAO-style project requirements (flat; primary live convention) |
| `docs/requirements/<area>/<REQ-ID>.md` | Optional council-style `REQ-<AREA>-<NNN>` files |

Suggested areas (if using subdirs): `product/`, `platform/`, `security/`, `ops/` — create as needed.

## ID scheme

- **Primary live convention:** `requirement-<topic>.md` or `requirement-<language>-<topic>.md` (e.g. `requirement-shell-cli-interface.md`, `requirement-class-software-dev.md`).
- Optional council-style: `REQ-<AREA>-<NNN>` (example: `REQ-PLAT-001`) if using area subdirs.
- IDs/keys are stable. Prefer status/`supersedes` over renumbering.
- Record every key in `index.md` when created or status changes.

## Status values

Live product law on this project uses the **file header Status** (and matching registry **Status** column):

| Status | Meaning |
|--------|---------|
| `Active` | Normative product law — implement and review against it |
| `Draft` | Proposed; not yet approved as binding law |
| `Deprecated` | No longer active; keep file for history |
| `Superseded` | Replaced by another requirement key (link it) |

Legacy/council synonyms sometimes seen in older docs (`approved`, `in-progress`, `done`) map to **Active** when the file is registered and binding. Prefer **Active** for this registry.

## Plan-mode rules (mandatory)

When planning non-trivial work:

1. Search `docs/requirements/` (and `index.md`) for related requirements.
2. Decide: **new requirement**, **update existing**, or **no requirements impact** (state why).
3. Apply requirement file changes **before** or as part of finishing the plan.
4. Session plan (`plan.md`) must list affected REQ-IDs and whether each is create / update / no-change.
5. Do not implement against unstated intent — if behavior is required, it belongs in a requirement file.

## Implementation rules

- Every non-trivial PR/change set cites one or more REQ-IDs in commit/PR/summary when requirements exist.
- Do not invent requirements only in code comments; promote durable intent here.
- **No placeholders** in requirement files: no `TBD`/`TODO` acceptance criteria, hollow sections, or stub “later” text. See `AGENTS.md` → **No-placeholder policy**.
- Product source comments cite only **live** `requirement-*.md` files (never invent basenames).

## Review rules

- Requirements changes and code/docs delivery use the project’s plan/implement/code-review/security checklist process.
- Empty registry is valid for genesis; do not invent requirements to “fill” the index.
- Software-development class requires Active `requirement-class-software-dev.md` in the registry.
