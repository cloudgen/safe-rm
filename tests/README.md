# Tests (safe-rm)

POSIX `/bin/sh` CI. Product proof is `tests/run_dry_run.sh` against `src/safe-rm`. `tests/run.sh` runs that suite first, then the Type 0 snapshot suite against `src/selfmanaged`.

## Run locally

```sh
./tests/run.sh
```

Requires: `sh`, `curl`, `python3` (local HTTP channel), `sha256sum`, `grep`.

## What is covered

| Suite | File | Focus |
|-------|------|--------|
| CLI surface | `test_cli.sh` | `sh -n`, companion digest (bare hex), `version` / `help` / `about` (human + JSON; version via live `PRODUCT_VERSION`; about `effective_storage` / `storage_dir` + isolation), unknown command, quiet, `CHECKSUM` not on help/about, `env -u HOME`, zero-arg **pipe** install failure exit, uninstall fail-closed JSON, **TP-SI-01**..**TP-SI-08** (`self-install` copy / dest **0700** / empty argv / pipe download / help / no `chmod +x` / isolated GLOBAL_BIN **0755**), **TP-JSON-RAW-01** `out_json` `@key` raw nested, **TP-CS-01** no `util_sudo` |
| Install lifecycle | `test_install_lifecycle.sh` | Isolated `HOME` / `USER_BIN` / **`GLOBAL_BIN`**, **TP-LC-10** `inst_maybe_install` under JSON/QUIET (place or fail closed), local channel install, idempotent re-install, **Type O** zero-arg already-installed (local Case B + global Case C, not help), strict `version-check` JSON keys, self-update already-latest, human integrity transparency, uninstall refuse / `--force`, `CHECKSUM` pin match/mismatch, downgrade refuse / `--force` (older channel derived from live `PRODUCT_VERSION`) |

**Version note:** suites source `PRODUCT_VERSION` from `grep '^VERSION="' src/selfmanaged` (via `helpers.sh`). After a product version bump, regenerate `src/selfmanaged.sha256` and re-run `./tests/run.sh` — do not hardcode the semver in new tests.

**Isolation note (1.2.2+):** `ci_isolated_env` always creates a private `GLOBAL_BIN` under the temp home. Without that, a real host install at `/usr/local/bin/${APP_NAME}` makes `inst_is_installed` true and lifecycle tests false-pass. Specializee suites **must** keep this pattern.

## safe-rm dry-run suite

`./tests/run_dry_run.sh` proves `src/safe-rm`. Remove checks pass `--dry-run` twice, except `TP-SRM-39`, which execs a fixture `origin-rm` under `/tmp/safe-rm-swap.*` that exits 0 and does not unlink. The script does not point `HOME` at a scratch directory and does not call the host remover. `./tests/test_place_setup.sh` proves `TP-SRM-32` and sets `HOME` only inside that file. `./tests/run.sh` runs the dry-run suite, then that place-setup suite, then the inherited selfmanaged Type 0 suite against `src/selfmanaged`.

| Case | What it checks |
|------|----------------|
| `TP-SRM-01` .. `TP-SRM-04` | Syntax, version, help, companion digest |
| `TP-SRM-05` .. `TP-SRM-06` | Allowed temporary paths stay unremoved |
| `TP-SRM-07` .. `TP-SRM-11`, `TP-SRM-13` | Login home, `/home`, `/usr/bin`, `/`, and a mixed command are refused and still present |
| `TP-SRM-12` | A folder inside the login home is allowed and still present |
| `TP-SRM-20` | Another account home from `/etc/passwd` is refused and still present |
| `TP-SRM-14` .. `TP-SRM-19` | JSON, missing operand, unknown command, about, quiet |
| `TP-SRM-21` .. `TP-SRM-26` | The command named `rm` accepts origin-rm switches, including `-rf`. A later setup replaces a stale guard and does not move `origin-rm` again |
| `TP-SRM-27` | Each lifecycle verb is also `--` plus that name. On the command named `rm`, `rm --version` prints this program's version. A bare word such as `version` is a path, so a link with that name is a dry-run remove and stays in place |
| `TP-SRM-37` | `.`, `..`, and `./` from an allowed directory are refused and remain. `./file` and a `..` in the middle stay allowed. `rm -- -rf` is a path. Nothing is executed |
| `TP-SRM-38` | `reset` points a fixture `rm` at `origin-rm` and leaves `origin-rm` and `safe-rm`. A missing `origin-rm` changes nothing. A non-admin `reset` leaves `/usr/bin/rm`. Nothing is executed |
| `TP-SRM-39` | With `--verbal`, a finished remove names the caller and each path. On a terminal those names are italic. The fixture `origin-rm` does not unlink. The path remains |
| `TP-SRM-41` | Without `--verbal`, that line and its `[OK]` mark stay hidden. The fixture still receives the path and does not receive `--verbal`. `--verbal` with `--quiet` still hides the line. The path remains |
| `TP-SRM-40` | When `mktemp` is absent, or a maker on `PATH` exits without creating a directory, a dry-run of an allowed path is still allowed. The scratch directory is a mode-`0700` subdirectory of the cache folder, including under umask `0177`. It is not left behind. The file remains. Nothing is executed |
| `TP-CLI-EMPTY-01`, `TP-CLI-17`, `TP-CLI-19`, `TP-CLI-21`, `TP-CLI-22`, `TP-CLI-SRM-01`, `TP-CLI-SRM-02` | Main menu, including `safe-rm --debug` and the folder list under **11**. No install. No real remove |
| `TP-SRM-SWAP-01` | Before/after swap inside `/tmp/safe-rm-swap.*` only. The fixture `rm` is never executed. Non-admin setup leaves `/usr/bin/rm` unchanged |
| `TP-SRM-29` | An empty first fixture directory does not stop setup. The second directory's regular `rm` is moved. A BusyBox symlink is not renamed; `origin-rm` runs `busybox rm`. Neither fixture is executed |
| `TP-SRM-30` | Termux `$PREFIX/bin/rm` inside `/tmp/safe-rm-swap.*`. A regular file is moved. A `toybox` or `coreutils` symlink is not renamed. An empty `bin` does not ask for an admin login. `/usr/bin/rm` stays. The fixture is never executed |
| `TP-SRM-31` | Termux blacklist inside `/tmp/safe-rm-swap.*`. `$PREFIX/var` and the other prefix system directories are refused and remain. A folder inside `$PREFIX/var`, and `$PREFIX/share`, stay allowed. `rm -rf $PREFIX/var --dry-run` refuses. The fixture is never executed |
| `TP-SRM-32` | `self-install` and `self-update` run setup inside `/tmp/safe-rm-swap.*`. The guard is the placed file. A non-root place without that fixture does not ask for an admin login. The fixture is never executed. `tests/test_place_setup.sh` |
| `TP-SRM-33` | Measure 1 under a scratch `HOME`. A missing `.profile` sources `.bashrc` and keeps an existing body. The PATH line is once in `.bashrc`. `sudo` is not called. `tests/test_two_layer.sh` |
| `TP-SRM-35` | TODO. When `/bin` is ahead of `/usr/local/bin`, the PATH line is `${HOME}/.local/bin` then `/usr/local/bin` once on `.bashrc`, `.zshrc`, `.zshenv`, `.profile`, and Fish. An existing `.profile` body stays. Not in the suite yet |
| `TP-SRM-34` | Linux calls a sudo stand-in for measure 2 only. Darwin does not. A BusyBox symlink is not renamed. No real `sudo`. `tests/test_two_layer.sh` |
| `TP-CACHE-01`, `TP-CACHE-02`, `TP-CACHE-03` | Cache folder chains, silent tier miss, persistence `~/.local/safe-rm`, mktemp scratch names, and a mode-`0600` cache file when `mktemp` is absent. `about` is not a remove. HOME stays this login |

## Specializee porting checklist (A → B)

When specializing a product from this bootstrap, port tests as follows:

1. Copy `tests/` and retarget `SCRIPT` / `APP_NAME` / channel basenames only (not CIAO org URLs in requirements).  
2. Keep **`GLOBAL_BIN=${CI_GLOBAL_BIN}`** on every isolated install/update/uninstall env block.  
3. Keep Type 0 suites; add a domain suite for B’s verbs (help rows, empty argv ≠ domain, root fail-closed for host ops).  
4. Map domain TP rows in B’s `reviews/test-plan.md`.  
5. Re-baseline PASS count after green run.

Product law: `requirement-shell-cli-zero-arguments` §2.2.1 · `requirement-shell-cli-interface` §2.5.1 · `reviews/revision-plan.md`.

## CI

GitHub Actions: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs `./tests/run.sh` on push/PR to `main`/`master`.

No secrets and no root. Install tests serve the checkout over `127.0.0.1` so they do not depend on the public raw GitHub channel being published.
