#!/bin/sh
# Domain suite for safe-rm. Every remove check uses --dry-run.
# This file does not assign HOME to a scratch directory and does not call
# the product without --dry-run on a remove path.
set -u

TESTS_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${TESTS_ROOT}/.." && pwd)
SAFE_RM="${REPO_ROOT}/src/safe-rm"
PASS=0
FAIL=0

SCRATCH=$(mktemp -d /tmp/safe-rm-dry.XXXXXX) || exit 2

# Scratch cleanup uses the remover, not the guard. /bin/rm is this program
# after setup, and a remove path in this file always carries --dry-run.
scratch_rm() {
    if [ -x /usr/bin/origin-rm ]; then
        /usr/bin/origin-rm "$@"
    elif [ -x /bin/origin-rm ]; then
        /bin/origin-rm "$@"
    else
        /bin/rm "$@"
    fi
}

cleanup() {
    case "${SCRATCH-}" in
        /tmp/safe-rm-dry.*)
            if [ -n "${HOME-}" ] && [ "$SCRATCH" = "$HOME" ]; then
                return 0
            fi
            scratch_rm -rf -- "$SCRATCH"
            ;;
    esac
}
trap cleanup EXIT INT HUP TERM

t_pass() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$*"; }
t_fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$*" >&2; }

assert_eq() {
    if [ "$2" = "$3" ]; then
        t_pass "$1"
    else
        t_fail "$1 (expected '$2' actual '$3')"
    fi
}

assert_contains() {
    case "$2" in
        *"$3"*) t_pass "$1" ;;
        *) t_fail "$1 (missing '$3')" ;;
    esac
}

assert_not_contains() {
    case "$2" in
        *"$3"*) t_fail "$1 (unexpected '$3')" ;;
        *) t_pass "$1" ;;
    esac
}

# Remove checks. Both --dry-run positions are always present.
srm() {
    sh "$SAFE_RM" --dry-run rm --dry-run "$@"
}

srm_json() {
    sh "$SAFE_RM" --json --dry-run rm --dry-run "$@"
}

printf 'safe-rm dry-run tests\n'
printf 'script: %s\n' "$SAFE_RM"

if [ ! -f "$SAFE_RM" ]; then
    printf 'ERROR: missing %s\n' "$SAFE_RM" >&2
    exit 2
fi

# TP-SRM-01 syntax
sh -n "$SAFE_RM"
assert_eq "TP-SRM-01 sh -n" 0 "$?"

# TP-SRM-02 version
out=$(sh "$SAFE_RM" version 2>/dev/null)
ec=$?
assert_eq "TP-SRM-02 version exit" 0 "$ec"
assert_contains "TP-SRM-02 version names safe-rm" "$out" "safe-rm version $(grep '^VERSION="' "$SAFE_RM" | head -n1 | cut -d'"' -f2)"

# TP-SRM-03 help
out=$(sh "$SAFE_RM" help 2>/dev/null)
assert_contains "TP-SRM-03 help lists self-install" "$out" "self-install"
assert_contains "TP-SRM-03 help lists rm" "$out" "rm"
assert_contains "TP-SRM-03 help lists --dry-run" "$out" "--dry-run"
assert_contains "TP-SRM-03 help tells agents not to retry rm" "$out" "Do not retry with rm"
assert_contains "TP-SRM-03 help lists rm -rf" "$out" "rm -rf"

# TP-SRM-04 companion digest
if [ -f "${REPO_ROOT}/src/safe-rm.sha256" ]; then
    expected=$(tr -d ' \n\r\t' < "${REPO_ROOT}/src/safe-rm.sha256")
    actual=$(sha256sum "$SAFE_RM" | awk '{print $1}')
    assert_eq "TP-SRM-04 sha256 matches" "$expected" "$actual"
else
    t_fail "TP-SRM-04 sha256 file missing"
fi

# TP-SRM-05 existing temp directory is allowed and remains
mkdir -p "$SCRATCH/leaf"
printf 'keep\n' > "$SCRATCH/leaf/file"
err="$SCRATCH/err"
out=$(srm "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-05 allow exit" 0 "$ec"
assert_contains "TP-SRM-05 says exists" "$out" "exists (dir)"
assert_contains "TP-SRM-05 says allowed" "$out" "Removal is allowed"
assert_contains "TP-SRM-05 says nothing removed" "$out" "Nothing was removed"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-05 file still exists"
else
    t_fail "TP-SRM-05 file was removed"
fi

# TP-SRM-06 missing path outside home: allowed verdict, still absent
missing="/tmp/safe-rm-no-such-file-dry"
if [ -e "$missing" ]; then
    t_fail "TP-SRM-06 fixture unexpectedly exists"
else
    out=$(srm "$missing" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-06 missing exit" 0 "$ec"
    assert_contains "TP-SRM-06 does not exist" "$out" "does not exist"
    assert_contains "TP-SRM-06 would be allowed" "$out" "would be allowed"
    if [ -e "$missing" ]; then
        t_fail "TP-SRM-06 created the missing path"
    else
        t_pass "TP-SRM-06 still absent"
    fi
fi

# TP-SRM-07 login home refused and still present
out=$(srm "$HOME" 2>"$err")
ec=$?
assert_eq "TP-SRM-07 home exit" 1 "$ec"
assert_contains "TP-SRM-07 refuses home" "$(cat "$err")" "Refusing to remove"
assert_contains "TP-SRM-07 says STOP" "$(cat "$err")" "STOP"
if [ -d "$HOME" ]; then
    t_pass "TP-SRM-07 login home still exists"
else
    t_fail "TP-SRM-07 login home missing"
fi
out=$(srm "$HOME/." 2>"$err")
ec=$?
assert_eq "TP-SRM-07 home/. exit" 1 "$ec"
assert_contains "TP-SRM-07 home/. refused" "$(cat "$err")" "Refusing to remove"
out=$(srm "$HOME/.." 2>"$err")
ec=$?
assert_eq "TP-SRM-07 home/.. exit" 1 "$ec"
assert_contains "TP-SRM-07 home/.. refused" "$(cat "$err")" "Refusing to remove"

# TP-SRM-08 literal tokens
for token in '$HOME' '${HOME}' '~'; do
    out=$(srm "$token" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-08 exit for $token" 1 "$ec"
    assert_contains "TP-SRM-08 refuses $token" "$(cat "$err")" "Refusing to remove"
done

# TP-SRM-09 /home and a non-existent user directory
out=$(srm /home 2>"$err")
ec=$?
assert_eq "TP-SRM-09 /home exit" 1 "$ec"
assert_contains "TP-SRM-09 /home refused" "$(cat "$err")" "Refusing to remove"
fake="/home/safe-rm-no-such-user"
existed=0
[ -e "$fake" ] && existed=1
out=$(srm "$fake" 2>"$err")
ec=$?
assert_eq "TP-SRM-09 fake user home exit" 1 "$ec"
assert_contains "TP-SRM-09 fake user home refused" "$(cat "$err")" "Refusing to remove"
if [ "$existed" -eq 0 ] && [ -e "$fake" ]; then
    t_fail "TP-SRM-09 created $fake"
else
    t_pass "TP-SRM-09 fake user path not created"
fi

# TP-SRM-10 /usr/bin tree
out=$(srm /usr/bin 2>"$err")
ec=$?
assert_eq "TP-SRM-10 /usr/bin exit" 1 "$ec"
assert_contains "TP-SRM-10 /usr/bin refused" "$(cat "$err")" "/usr/bin"
if [ -d /usr/bin ]; then
    t_pass "TP-SRM-10 /usr/bin still exists"
else
    t_fail "TP-SRM-10 /usr/bin missing"
fi
out=$(srm /usr/bin/sh 2>"$err")
ec=$?
assert_eq "TP-SRM-10 /usr/bin/sh exit" 1 "$ec"
if [ -e /usr/bin/sh ] || [ -L /usr/bin/sh ]; then
    t_pass "TP-SRM-10 /usr/bin/sh still exists"
else
    t_fail "TP-SRM-10 /usr/bin/sh missing"
fi

# TP-SRM-11 filesystem root
out=$(srm / 2>"$err")
ec=$?
assert_eq "TP-SRM-11 / exit" 1 "$ec"
assert_contains "TP-SRM-11 root refused" "$(cat "$err")" "Refusing to remove"
if [ -d / ]; then
    t_pass "TP-SRM-11 / still exists"
else
    t_fail "TP-SRM-11 / missing"
fi

# TP-SRM-12 a folder inside the login home is allowed and remains
inside="$REPO_ROOT"
out=$(srm "$inside" 2>"$err")
ec=$?
assert_eq "TP-SRM-12 inside-home exit" 0 "$ec"
assert_contains "TP-SRM-12 inside-home allowed" "$out" "Removal is allowed"
assert_contains "TP-SRM-12 inside-home nothing removed" "$out" "Nothing was removed"
if [ -d "$inside" ]; then
    t_pass "TP-SRM-12 project directory still exists"
else
    t_fail "TP-SRM-12 project directory missing"
fi
cache="${HOME}/.cache"
cache_existed=0
[ -e "$cache" ] && cache_existed=1
out=$(srm "$cache" 2>"$err")
ec=$?
assert_eq "TP-SRM-12 cache exit" 0 "$ec"
if [ "$cache_existed" -eq 1 ]; then
    assert_contains "TP-SRM-12 cache allowed" "$out" "Removal is allowed"
    if [ -e "$cache" ]; then
        t_pass "TP-SRM-12 cache still exists"
    else
        t_fail "TP-SRM-12 cache was removed"
    fi
else
    assert_contains "TP-SRM-12 cache would be allowed" "$out" "would be allowed"
    if [ -e "$cache" ]; then
        t_fail "TP-SRM-12 cache was created"
    else
        t_pass "TP-SRM-12 cache still absent"
    fi
fi
out=$(srm '${HOME}/.cache' 2>"$err")
ec=$?
assert_eq "TP-SRM-12 literal cache exit" 0 "$ec"
assert_contains "TP-SRM-12 literal cache allowed" "$out" "allowed"

# TP-SRM-20 another account home from /etc/passwd is refused
other=$(awk -F: -v h="$HOME" '$1 !~ /^#/ && $6 ~ /^\// && $6 != "/" && $6 != h { print $6; exit }' /etc/passwd)
if [ -z "$other" ]; then
    t_fail "TP-SRM-20 no other account home in /etc/passwd"
else
    other_existed=0
    [ -e "$other" ] && other_existed=1
    out=$(srm "$other" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-20 other home exit" 1 "$ec"
    assert_contains "TP-SRM-20 other home names passwd" "$(cat "$err")" "/etc/passwd"
    if [ "$other_existed" -eq 1 ]; then
        if [ -e "$other" ]; then
            t_pass "TP-SRM-20 other home still exists"
        else
            t_fail "TP-SRM-20 other home was removed"
        fi
    else
        if [ -e "$other" ]; then
            t_fail "TP-SRM-20 other home was created"
        else
            t_pass "TP-SRM-20 other home still absent"
        fi
    fi
fi

# TP-SRM-13 one allowed path plus one refused path removes nothing
out=$(srm "$SCRATCH/leaf" /usr/bin 2>"$err")
ec=$?
assert_eq "TP-SRM-13 mixed exit" 1 "$ec"
assert_contains "TP-SRM-13 mixed refuses" "$(cat "$err")" "Nothing was removed"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-13 allowed path still exists"
else
    t_fail "TP-SRM-13 allowed path was removed"
fi

# TP-SRM-14 JSON allow
out=$(srm_json "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-14 json exit" 0 "$ec"
assert_contains "TP-SRM-14 dry_run true" "$out" '"dry_run":"true"'
assert_contains "TP-SRM-14 removed false" "$out" '"removed":"false"'
assert_contains "TP-SRM-14 verdict allow" "$out" '"verdict":"allow"'
assert_contains "TP-SRM-14 exists true" "$out" '"exists":"true"'

# TP-SRM-15 JSON refuse
out=$(srm_json /usr/bin 2>"$err")
ec=$?
assert_eq "TP-SRM-15 json refuse exit" 1 "$ec"
assert_contains "TP-SRM-15 json verdict refuse" "$out" '"verdict":"refuse"'
assert_contains "TP-SRM-15 json removed false" "$out" '"removed":"false"'
assert_contains "TP-SRM-15 stderr STOP" "$(cat "$err")" "STOP"

# TP-SRM-16 no path
out=$(srm 2>"$err")
ec=$?
assert_eq "TP-SRM-16 no path exit" 1 "$ec"
assert_contains "TP-SRM-16 no path message" "$(cat "$err")" "No path was given"

# TP-SRM-17 unknown command still fails and is not a remove
out=$(sh "$SAFE_RM" nosuch 2>"$err")
ec=$?
assert_eq "TP-SRM-17 unknown exit" 1 "$ec"
assert_contains "TP-SRM-17 unknown points at help" "$(cat "$err")" "help"

# Command name rm: a symlink whose basename is rm. Switches are origin-rm's.
ln -s "$SAFE_RM" "$SCRATCH/rm"

# TP-SRM-21 rm -rf of an allowed folder
out=$("$SCRATCH/rm" -rf --dry-run "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-21 -rf exit" 0 "$ec"
assert_contains "TP-SRM-21 -rf allowed" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-21 -rf is not unknown" "$(cat "$err")" "Unknown command"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-21 file still exists"
else
    t_fail "TP-SRM-21 file was removed"
fi

# TP-SRM-22 other origin-rm switches
out=$("$SCRATCH/rm" --preserve-root=all --one-file-system --interactive=never -rf --dry-run "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-22 other switches exit" 0 "$ec"
assert_contains "TP-SRM-22 other switches allowed" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-22 other switches are not unknown" "$(cat "$err")" "Unknown"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-22 file still exists"
else
    t_fail "TP-SRM-22 file was removed"
fi

# TP-SRM-23 rm -rf of the login home is still refused
out=$("$SCRATCH/rm" -rf --dry-run "$HOME" 2>"$err")
ec=$?
assert_eq "TP-SRM-23 home exit" 1 "$ec"
assert_contains "TP-SRM-23 home refused" "$(cat "$err")" "STOP"
if [ -d "$HOME" ]; then
    t_pass "TP-SRM-23 home still exists"
else
    t_fail "TP-SRM-23 home was removed"
fi

# TP-SRM-24 safe-rm rm -rf with another switch
out=$(sh "$SAFE_RM" rm -rf --preserve-root --dry-run "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-24 verb -rf exit" 0 "$ec"
assert_contains "TP-SRM-24 verb -rf allowed" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-24 verb -rf is not unknown" "$(cat "$err")" "Unknown"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-24 file still exists"
else
    t_fail "TP-SRM-24 file was removed"
fi

# Command named rm with no path is the remove, not the menu.
out=$("$SCRATCH/rm" --debug --dry-run </dev/null 2>"$err")
ec=$?
assert_eq "TP-SRM-25 no path exit" 1 "$ec"
assert_contains "TP-SRM-25 no path message" "$(cat "$err")" "No path was given"
assert_not_contains "TP-SRM-25 is not the menu" "$out$(cat "$err")" "Choice:"

# TP-SRM-27 lifecycle verbs are switches. Not a remove path, so no --dry-run.
# A real path check below still uses --dry-run. No file named "version" is passed
# to a live remove.
ver=$(grep '^VERSION="' "$SAFE_RM" | head -n1 | cut -d'"' -f2)
out=$(sh "$SAFE_RM" --version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 --version exit" 0 "$ec"
assert_contains "TP-SRM-27 --version names safe-rm" "$out" "safe-rm version ${ver}"
assert_not_contains "TP-SRM-27 --version is not GNU" "$out$(cat "$err")" "GNU coreutils"

out=$(sh "$SAFE_RM" --json --version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 json --version exit" 0 "$ec"
assert_contains "TP-SRM-27 json --version value" "$out" "\"version\":\"${ver}\""

out=$(sh "$SAFE_RM" --help 2>/dev/null)
assert_contains "TP-SRM-27 --help lists --self-install" "$out" "--self-install"
assert_contains "TP-SRM-27 --help lists --version" "$out" "--version"
assert_contains "TP-SRM-27 --help lists --about" "$out" "--about"
assert_contains "TP-SRM-27 --help lists --version-check" "$out" "--version-check"
assert_contains "TP-SRM-27 --help lists --self-update" "$out" "--self-update"
assert_contains "TP-SRM-27 --help lists --self-uninstall" "$out" "--self-uninstall"
assert_contains "TP-SRM-27 --help lists --install" "$out" "--install"
assert_contains "TP-SRM-27 --help lists --menu" "$out" "--menu"
assert_contains "TP-SRM-27 --help lists --main" "$out" "--main"
assert_contains "TP-SRM-27 --help lists --setup" "$out" "--setup"
assert_contains "TP-SRM-27 --help lists --restore" "$out" "--restore"
assert_contains "TP-SRM-27 --help lists --rm" "$out" "--rm"

out=$(sh "$SAFE_RM" --about 2>/dev/null)
assert_contains "TP-SRM-27 --about remove guard" "$out" "Remove guard:"

out=$(TTY=0 sh "$SAFE_RM" --menu </dev/null 2>/dev/null)
assert_contains "TP-SRM-27 --menu off a terminal is help" "$out" "--self-install"

out=$("$SCRATCH/rm" version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 rm version exit" 0 "$ec"
assert_contains "TP-SRM-27 rm version names safe-rm" "$out" "safe-rm version ${ver}"
assert_not_contains "TP-SRM-27 rm version does not remove" "$out$(cat "$err")" "cannot remove"
assert_not_contains "TP-SRM-27 rm version is not GNU" "$out$(cat "$err")" "GNU coreutils"

out=$("$SCRATCH/rm" --version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 rm --version exit" 0 "$ec"
assert_contains "TP-SRM-27 rm --version names safe-rm" "$out" "safe-rm version ${ver}"
assert_not_contains "TP-SRM-27 rm --version is not GNU" "$out$(cat "$err")" "GNU coreutils"

out=$("$SCRATCH/rm" help 2>/dev/null)
assert_contains "TP-SRM-27 rm help lists --self-install" "$out" "--self-install"

out=$("$SCRATCH/rm" --help 2>/dev/null)
assert_contains "TP-SRM-27 rm --help lists --setup" "$out" "--setup"

out=$(sh "$SAFE_RM" rm --version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 safe-rm rm --version exit" 0 "$ec"
assert_contains "TP-SRM-27 safe-rm rm --version names safe-rm" "$out" "safe-rm version ${ver}"

out=$("$SCRATCH/rm" --about 2>/dev/null)
assert_contains "TP-SRM-27 rm --about remove guard" "$out" "Remove guard:"

printf 'keep\n' > "$SCRATCH/version"
out=$("$SCRATCH/rm" --dry-run "$SCRATCH/version" 2>"$err")
ec=$?
assert_eq "TP-SRM-27 path version exit" 0 "$ec"
assert_contains "TP-SRM-27 path version allowed" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-27 path version is not the version command" "$out" "safe-rm version"
if [ -f "$SCRATCH/version" ]; then
    t_pass "TP-SRM-27 path version still exists"
else
    t_fail "TP-SRM-27 path version was removed"
fi

out=$("$SCRATCH/rm" version "$SCRATCH/missing-leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-27 mixed exit" 1 "$ec"
assert_contains "TP-SRM-27 mixed says command" "$(cat "$err")" "--version"
assert_contains "TP-SRM-27 mixed nothing removed" "$(cat "$err")" "Nothing was removed"

out=$("$SCRATCH/rm" --dry-run -- version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 end-of-options exit" 0 "$ec"
assert_not_contains "TP-SRM-27 end-of-options is not the version command" "$out$(cat "$err")" "safe-rm version"

out=$(sh "$SAFE_RM" --rm --dry-run "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-27 --rm exit" 0 "$ec"
assert_contains "TP-SRM-27 --rm allowed" "$out" "Removal is allowed"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-27 --rm file still exists"
else
    t_fail "TP-SRM-27 --rm file was removed"
fi

# TP-SRM-18 about mentions the guard
out=$(sh "$SAFE_RM" about 2>/dev/null)
assert_contains "TP-SRM-18 about remove guard" "$out" "Remove guard:"

# TP-CACHE-01 / TP-CACHE-02 cache folder.
# about is not a remove path. This block does not assign HOME.
login=$(id -un 2>/dev/null || echo "unknown")
case "$login" in
    *[!A-Za-z0-9._-]*)
        login=$(printf '%s' "$login" | tr -c 'A-Za-z0-9._-' '_')
        ;;
esac
[ -n "$login" ] || login="unknown"
app=safe-rm
json=$(sh "$SAFE_RM" --json about 2>/dev/null)
ec=$?
assert_eq "TP-CACHE-01 about json exit" 0 "$ec"
assert_contains "TP-CACHE-01 cache_used" "$json" '"cache_used"'
assert_contains "TP-CACHE-01 cache_preferred" "$json" '"cache_preferred"'
assert_contains "TP-CACHE-01 cache_fallback" "$json" '"cache_fallback"'
assert_contains "TP-CACHE-01 cache_fallback_2" "$json" '"cache_fallback_2"'
assert_contains "TP-CACHE-01 persistence_storage" "$json" '"persistence_storage"'
assert_contains "TP-CACHE-01 effective_storage" "$json" '"effective_storage"'
assert_not_contains "TP-CACHE-01 no CHECKSUM" "$json" "CHECKSUM"
hum=$(sh "$SAFE_RM" about 2>/dev/null)
assert_contains "TP-CACHE-01 human used" "$hum" "Cache folder used:"
assert_contains "TP-CACHE-01 human preferred" "$hum" "Cache folder (preferred):"
assert_contains "TP-CACHE-01 human 1st" "$hum" "Cache folder (1st fallback):"
assert_contains "TP-CACHE-01 human 2nd" "$hum" "Cache folder (2nd fallback):"
assert_contains "TP-CACHE-01 human persistence" "$hum" "Persistence storage:"
assert_not_contains "TP-CACHE-01 no Storage (effective)" "$hum" "Storage (effective)"
assert_not_contains "TP-CACHE-01 no Storage (fallback)" "$hum" "Storage (fallback)"
pref=$(printf '%s' "$json" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
pid="${pref##*-}"
case "$pref" in
    /dev/shm/cache/cache-${app}-${login}-[0-9]*)
        t_pass "TP-CACHE-02 cache_preferred is shm login process leaf"
        ;;
    *)
        t_fail "TP-CACHE-02 cache_preferred unexpected: ${pref:-empty}"
        ;;
esac
fb=$(printf '%s' "$json" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 cache_fallback 1st" "/tmp/cache/cache-${app}-${login}-${pid}" "$fb"
fb2=$(printf '%s' "$json" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 cache_fallback 2nd" "${HOME}/.cache/cache-${app}-${pid}" "$fb2"
used=$(printf '%s' "$json" | sed -n 's/.*"cache_used":"\([^"]*\)".*/\1/p' | head -n1)
eff=$(printf '%s' "$json" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
sdir=$(printf '%s' "$json" | sed -n 's/.*"storage_dir":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 cache_used matches effective" "$eff" "$used"
assert_eq "TP-CACHE-02 storage_dir is 1st fallback" "$fb" "$sdir"
if [ -n "$eff" ] && [ -d "$eff" ]; then
    t_pass "TP-CACHE-02 effective cache directory exists"
else
    t_fail "TP-CACHE-02 effective cache missing: ${eff:-empty}"
fi
case "$eff" in
    /dev/shm/${app}|/dev/shm/${app}-*)
        t_fail "TP-CACHE-02 effective cache must not be a ram-drive project shape: ${eff}"
        ;;
    *)
        t_pass "TP-CACHE-02 effective cache is not a ram-drive project shape"
        ;;
esac
mode=$(stat -c %a "$eff" 2>/dev/null || echo "")
assert_eq "TP-CACHE-02 effective cache mode 0700" "700" "$mode"
errc=$(SRM_CACHE_SKIP=preferred sh "$SAFE_RM" about 2>&1 >/dev/null)
assert_not_contains "TP-CACHE-02 silent cache fallback" "$errc" "fallback"
assert_not_contains "TP-CACHE-02 silent cache fallback error" "$errc" "Cannot create cache"
skip_hum=$(SRM_CACHE_SKIP=preferred sh "$SAFE_RM" about 2>/dev/null)
assert_not_contains "TP-CACHE-02 no warn on skip" "$skip_hum" "[WARN]"
assert_not_contains "TP-CACHE-02 no error on skip" "$skip_hum" "[ERROR]"
skip=$(SRM_CACHE_SKIP=preferred sh "$SAFE_RM" --json about 2>/dev/null)
skip_eff=$(printf '%s' "$skip" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
skip_fb=$(printf '%s' "$skip" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
skip_pref=$(printf '%s' "$skip" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 skipped preferred uses 1st fallback" "$skip_fb" "$skip_eff"
if [ -n "$skip_pref" ] && [ "$skip_pref" != "$skip_eff" ]; then
    t_pass "TP-CACHE-02 skipped preferred still names the preferred path"
else
    t_fail "TP-CACHE-02 preferred path should stay visible when unused"
fi
gb=$(SRM_CACHE_HOST=gitbash sh "$SAFE_RM" --json about 2>/dev/null)
gb_pref=$(printf '%s' "$gb" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
gb_pid="${gb_pref##*-}"
assert_eq "TP-CACHE-02 gitbash preferred" "/tmp/cache/cache-${app}-${login}-${gb_pid}" "$gb_pref"
gb_fb=$(printf '%s' "$gb" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 gitbash 1st fallback" "${HOME}/AppData/Local/Temp/cache-${app}-${gb_pid}" "$gb_fb"
assert_contains "TP-CACHE-02 gitbash json has empty cache_fallback_2" "$gb" '"cache_fallback_2":""'
gb_fb2=$(printf '%s' "$gb" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 gitbash no 2nd fallback" "" "$gb_fb2"
mac=$(SRM_CACHE_HOST=mac sh "$SAFE_RM" --json about 2>/dev/null)
mac_pref=$(printf '%s' "$mac" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
mac_pid="${mac_pref##*-}"
assert_eq "TP-CACHE-02 mac preferred" "/tmp/cache/cache-${app}-${login}-${mac_pid}" "$mac_pref"
mac_fb=$(printf '%s' "$mac" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 mac 1st fallback" "${HOME}/Library/Caches/cache-${app}-${mac_pid}" "$mac_fb"
mac_fb2=$(printf '%s' "$mac" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 mac 2nd fallback" "${HOME}/cache/cache-${app}-${mac_pid}" "$mac_fb2"
hum_l=$(sh "$SAFE_RM" about 2>/dev/null)
used_line=$(printf '%s\n' "$hum_l" | sed -n 's/.*Cache folder used: //p' | head -n1)
pref_line=$(printf '%s\n' "$hum_l" | sed -n 's/.*Cache folder (preferred): //p' | head -n1)
assert_eq "TP-CACHE-02 used matches preferred when preferred works" "$pref_line" "$used_line"
assert_contains "TP-CACHE-02 linux about preferred path" "$hum_l" "/dev/shm/cache/cache-${app}-${login}-"
assert_contains "TP-CACHE-02 linux about 2nd path" "$hum_l" "/.cache/cache-${app}-"
hum_gb=$(SRM_CACHE_HOST=gitbash sh "$SAFE_RM" about 2>/dev/null)
assert_contains "TP-CACHE-02 gitbash about 1st" "$hum_gb" "AppData/Local/Temp/cache-${app}-"
assert_not_contains "TP-CACHE-02 gitbash about omits 2nd" "$hum_gb" "Cache folder (2nd fallback)"
hum_mac=$(SRM_CACHE_HOST=mac sh "$SAFE_RM" about 2>/dev/null)
assert_contains "TP-CACHE-02 mac about 1st" "$hum_mac" "Library/Caches/cache-${app}-"
assert_contains "TP-CACHE-02 mac about 2nd path" "$hum_mac" "Cache folder (2nd fallback): ${HOME}/cache/cache-${app}-"
persist=$(printf '%s' "$json" | sed -n 's/.*"persistence_storage":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 persistence_storage path" "${HOME}/.local/${app}" "$persist"
if [ -n "$persist" ] && [ -d "$persist" ]; then
    t_pass "TP-CACHE-02 persistence storage directory exists"
else
    t_fail "TP-CACHE-02 persistence storage missing: ${persist:-empty}"
fi
case "$persist" in
    */.local/bin|*/.local/bin/)
        t_fail "TP-CACHE-02 persistence must not be USER_BIN: ${persist}"
        ;;
    *)
        t_pass "TP-CACHE-02 persistence is not the install bin directory"
        ;;
esac
j2=$(sh "$SAFE_RM" --json about 2>/dev/null)
p2=$(printf '%s' "$j2" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
p2="${p2##*-}"
if [ -n "$pid" ] && [ -n "$p2" ] && [ "$pid" != "$p2" ]; then
    t_pass "TP-CACHE-02 each process has its own cache leaf"
else
    t_fail "TP-CACHE-02 cache leaf pid reused (${pid:-empty} vs ${p2:-empty})"
fi

# TP-CACHE-03 scratch file names stay mktemp names inside the cache directory.
lib=$(mktemp /tmp/safe-rm-lib.XXXXXX) || exit 2
awk '
    /^app_main "\$@"$/ { print "# app_main stripped"; next }
    { print }
' "$SAFE_RM" > "$lib"
leaf=$(sh -c '. "$1"; util_mktemp tmp' sh "$lib" 2>/dev/null) || leaf=""
case "$leaf" in
    /dev/shm/cache/cache-${app}-${login}-[0-9]*/${app}.tmp.*)
        base=${leaf##*/}
        case "$base" in
            *.\$\$|${app}.\$\$)
                t_fail "TP-CACHE-03 scratch file uses a dollar name: ${base}"
                ;;
            *)
                t_pass "TP-CACHE-03 scratch file is an mktemp name under the cache leaf"
                ;;
        esac
        ;;
    *)
        t_fail "TP-CACHE-03 scratch file unexpected: ${leaf:-empty}"
        ;;
esac
if [ -n "$leaf" ] && [ -f "$leaf" ]; then
    scratch_rm -f -- "$leaf"
fi
dollars=$(printf '%s%s' '$' '$')
bad=$(sh -c '. "$1"; util_mktemp "$2"' sh "$lib" "x${dollars}y" 2>&1 >/dev/null) || true
assert_contains "TP-CACHE-03 refuses a dollar file name" "$bad" "refuse predictable"
scratch_rm -f -- "$lib"

# TP-SRM-19 quiet still shows the refusal
out=$(sh "$SAFE_RM" --quiet --dry-run rm --dry-run /usr/bin 2>"$err")
ec=$?
assert_eq "TP-SRM-19 quiet exit" 1 "$ec"
assert_contains "TP-SRM-19 quiet still shows error" "$(cat "$err")" "[ERROR]"

# Numbered menu. These probes answer 9 / 0 and do not place the program.
ver=$(grep '^VERSION="' "$SAFE_RM" | head -n1 | cut -d'"' -f2)

# TP-CLI-EMPTY-01 / TP-CLI-17 / TP-CLI-SRM-01 front board
out=$(printf '9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-EMPTY-01 menu exit" 0 "$ec"
out_dbg=$(printf '9\n' | TTY=1 sh "$SAFE_RM" --debug 2>&1)
ec_dbg=$?
assert_eq "TP-CLI-EMPTY-01 --debug menu exit" 0 "$ec_dbg"
assert_contains "TP-CLI-EMPTY-01 --debug opens the menu" "$out_dbg" "remove-guard"
case "$out_dbg" in
    *"not installed yet"*) t_fail "TP-CLI-EMPTY-01 --debug offered install" ;;
    *) t_pass "TP-CLI-EMPTY-01 --debug does not offer install" ;;
esac
assert_contains "TP-CLI-EMPTY-01 names remove-guard" "$out" "remove-guard"
assert_contains "TP-CLI-EMPTY-01 names self-management" "$out" "self-management"
assert_contains "TP-CLI-EMPTY-01 exit row" "$out" "9. Exit"
assert_contains "TP-CLI-17 bold short" "$out" "$(printf '\033[1mremove-guard\033[0m')"
assert_contains "TP-CLI-17 italic explain" "$out" "$(printf '\033[3;37mcheck a path and remove it only when it is allowed\033[0m')"
assert_contains "TP-CLI-17 italic version" "$out" "$(printf '\033[3m%s\033[0m' "$ver")"
case "$out" in
    *"not installed yet"*) t_fail "TP-CLI-EMPTY-01 still offers install" ;;
    *) t_pass "TP-CLI-EMPTY-01 does not offer install" ;;
esac
case "$out" in
    *"11."*) t_fail "TP-CLI-SRM-01 front lists 11" ;;
    *) t_pass "TP-CLI-SRM-01 front omits 11" ;;
esac
case "$out" in
    *"82."*) t_fail "TP-CLI-SRM-01 front lists a lifecycle row" ;;
    *) t_pass "TP-CLI-SRM-01 front omits lifecycle rows" ;;
esac

out=$(printf '9\n' | TTY=1 sh "$SAFE_RM" --json menu 2>&1)
ec=$?
assert_eq "TP-CLI-17 menu --json on a TTY exit" 0 "$ec"
assert_contains "TP-CLI-17 menu --json still draws the list" "$out" "self-management"
case "$out" in
    *'"command":"help"'*) t_fail "TP-CLI-17 menu --json on a TTY is JSON help" ;;
    *) t_pass "TP-CLI-17 menu --json on a TTY is not JSON help" ;;
esac

# TP-CLI-19 bad pick reprints this layer
out=$(printf '3\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-19 bad pick exit" 0 "$ec"
assert_contains "TP-CLI-19 names the pick" "$out" "Not a menu choice '3'"
case "$out" in
    *"Unknown command"*) t_fail "TP-CLI-19 treated as unknown argv" ;;
    *) t_pass "TP-CLI-19 is not unknown argv" ;;
esac
n=$(printf '%s\n' "$out" | grep -c 'this CLI install, version, update, uninstall' || true)
assert_eq "TP-CLI-19 reprints the front board" "2" "$n"

# TP-CLI-21 finished 82 redisplays the front board
out=$(printf '8\n82\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-21 version leaf exit" 0 "$ec"
assert_contains "TP-CLI-21 version ran" "$out" "$ver"
n=$(printf '%s\n' "$out" | grep -c 'this CLI install, version, update, uninstall' || true)
assert_eq "TP-CLI-21 front board after the leaf" "2" "$n"

# TP-CLI-22 self-management rows; off-TTY menu is help
out=$(printf '8\n0\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-22 submenu exit" 0 "$ec"
assert_contains "TP-CLI-22 lists 87 self-install" "$out" "87."
assert_contains "TP-CLI-22 lists back" "$out" "0. Back"
case "$out" in
    *"81."*) t_fail "TP-CLI-22 printed reserved 81" ;;
    *) t_pass "TP-CLI-22 omits reserved 81" ;;
esac
out=$(sh "$SAFE_RM" menu </dev/null 2>&1)
ec=$?
assert_eq "TP-CLI-22 off-tty menu exit" 0 "$ec"
assert_contains "TP-CLI-22 off-tty menu is help" "$out" "Usage:"
case "$out" in
    *"82."*) t_fail "TP-CLI-22 off-tty menu drew 82" ;;
    *) t_pass "TP-CLI-22 off-tty menu does not draw 82" ;;
esac

# TP-CLI-SRM-01 rm lives under 1 as 11
out=$(printf '1\n0\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-SRM-01 remove-guard exit" 0 "$ec"
assert_contains "TP-CLI-SRM-01 lists 11 rm" "$out" "11."
assert_contains "TP-CLI-SRM-01 remove-guard back" "$out" "0. Back"

# TP-CLI-SRM-02 path board. Choices are Back, an empty custom path, or a
# bad number. No folder is chosen, so the remover is not called.
PICK="${SCRATCH}/pick"
EMPTY="${SCRATCH}/nofolders"
mkdir -p "${PICK}/alpha" "${PICK}/beta" "${PICK}/leaf one" "${PICK}/.hidden" "${EMPTY}"
printf 'x\n' > "${PICK}/note.txt"
printf 'x\n' > "${EMPTY}/note.txt"
_b_alpha=$(printf '\033[1malpha\033[0m')
_b_beta=$(printf '\033[1mbeta\033[0m')
_b_leaf=$(printf '\033[1mleaf one\033[0m')
_b_custom=$(printf '\033[1mcustom-path\033[0m')

out=$(cd "$PICK" && printf '1\n11\n0\n0\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-SRM-02 list exit" 0 "$ec"
assert_contains "TP-CLI-SRM-02 current path" "$out" "Current path: ${PICK}"
assert_contains "TP-CLI-SRM-02 alpha is 1" "$out" "1. ${_b_alpha}"
assert_contains "TP-CLI-SRM-02 beta is 2" "$out" "2. ${_b_beta}"
assert_contains "TP-CLI-SRM-02 spaced name is 3" "$out" "3. ${_b_leaf}"
assert_contains "TP-CLI-SRM-02 shows the spaced path" "$out" "${PICK}/leaf one"
assert_contains "TP-CLI-SRM-02 custom-path is 4" "$out" "4. ${_b_custom}"
assert_contains "TP-CLI-SRM-02 custom explain" "$out" "type a path"
assert_contains "TP-CLI-SRM-02 path back" "$out" "0. Back"
n=$(printf '%s\n' "$out" | grep -c 'check each path and remove only when every path is allowed' || true)
assert_eq "TP-CLI-SRM-02 back returns to remove-guard" "2" "$n"
case "$out" in
    *note.txt*) t_fail "TP-CLI-SRM-02 listed a file" ;;
    *) t_pass "TP-CLI-SRM-02 omits files" ;;
esac
case "$out" in
    *".hidden"*) t_fail "TP-CLI-SRM-02 listed a dotfolder" ;;
    *) t_pass "TP-CLI-SRM-02 omits dotfolders" ;;
esac
if [ -d "${PICK}/alpha" ] && [ -d "${PICK}/beta" ] && [ -d "${PICK}/leaf one" ]; then
    t_pass "TP-CLI-SRM-02 folders still present"
else
    t_fail "TP-CLI-SRM-02 a folder was removed"
fi

out=$(cd "$PICK" && printf '1\n11\n4\n\n0\n0\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-SRM-02 empty custom exit" 0 "$ec"
assert_contains "TP-CLI-SRM-02 custom asks Path" "$out" "Path: "
assert_contains "TP-CLI-SRM-02 empty path error" "$out" "No path was given"
n=$(printf '%s\n' "$out" | grep -c 'Current path:' || true)
assert_eq "TP-CLI-SRM-02 empty path reprints the path board" "2" "$n"
if [ -d "${PICK}/alpha" ]; then
    t_pass "TP-CLI-SRM-02 empty path removed nothing"
else
    t_fail "TP-CLI-SRM-02 empty path removed a folder"
fi

out=$(cd "$PICK" && printf '1\n11\n99\n0\n0\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-SRM-02 bad pick exit" 0 "$ec"
assert_contains "TP-CLI-SRM-02 bad pick names 99" "$out" "Not a menu choice '99'"
n=$(printf '%s\n' "$out" | grep -c 'Current path:' || true)
assert_eq "TP-CLI-SRM-02 bad pick reprints the path board" "2" "$n"

out=$(cd "$EMPTY" && printf '1\n11\n0\n0\n9\n' | TTY=1 sh "$SAFE_RM" 2>&1)
ec=$?
assert_eq "TP-CLI-SRM-02 no-folder exit" 0 "$ec"
assert_contains "TP-CLI-SRM-02 no-folder custom is 1" "$out" "1. ${_b_custom}"
case "$out" in
    *"2. "*) t_fail "TP-CLI-SRM-02 no-folder listed a second row" ;;
    *) t_pass "TP-CLI-SRM-02 no-folder has no second folder row" ;;
esac
unset _b_alpha _b_beta _b_leaf _b_custom

# TP-SRM-SWAP-01 layout only. The fixture rm is never executed.
# This block does not remove a directory. It moves one regular file inside
# /tmp/safe-rm-swap.* and puts it back.
usr_before=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
out=$(sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-SWAP-01 non-admin setup exit" 1 "$ec"
assert_contains "TP-SRM-SWAP-01 non-admin moved nothing" "$(cat "$err")" "Nothing was moved"
usr_after=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
assert_eq "TP-SRM-SWAP-01 system rm unchanged" "$usr_before" "$usr_after"

SWAP=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
printf '#!/bin/sh\nexit 0\n' > "$SWAP/rm"
chmod 0755 "$SWAP/rm"
origin_before=$(stat -c '%d:%i' "$SWAP/rm")
out=$(SRM_SWAP_ROOT="$SWAP" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-SWAP-01 setup exit" 0 "$ec"
assert_contains "TP-SRM-SWAP-01 moved rm" "$out" "Moved ${SWAP}/rm to ${SWAP}/origin-rm"
if [ -L "$SWAP/rm" ]; then
    t_pass "TP-SRM-SWAP-01 rm is a symlink"
else
    t_fail "TP-SRM-SWAP-01 rm is not a symlink"
fi
assert_contains "TP-SRM-SWAP-01 link target" "$(readlink "$SWAP/rm")" "${SWAP}/safe-rm"
if [ -f "$SWAP/safe-rm" ]; then
    t_pass "TP-SRM-SWAP-01 safe-rm installed"
else
    t_fail "TP-SRM-SWAP-01 safe-rm missing"
fi
origin_after=$(stat -c '%d:%i' "$SWAP/origin-rm" 2>/dev/null || true)
assert_eq "TP-SRM-SWAP-01 origin-rm is the original file" "$origin_before" "$origin_after"
if [ -d "$SWAP/origin-rm" ]; then
    t_fail "TP-SRM-SWAP-01 origin-rm is a directory"
else
    t_pass "TP-SRM-SWAP-01 origin-rm is not a directory"
fi
out=$(SRM_SWAP_ROOT="$SWAP" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-SWAP-01 second setup exit" 0 "$ec"
assert_contains "TP-SRM-SWAP-01 second setup sees origin" "$out" "Already swapped"
origin_again=$(stat -c '%d:%i' "$SWAP/origin-rm" 2>/dev/null || true)
assert_eq "TP-SRM-SWAP-01 second setup did not move again" "$origin_after" "$origin_again"

# A stale guard is replaced. origin-rm stays. The command named rm accepts -rf.
printf '#!/bin/sh\nprintf "STALE\\n"\nexit 9\n' > "$SWAP/safe-rm"
chmod 0755 "$SWAP/safe-rm"
out=$(SRM_SWAP_ROOT="$SWAP" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-26 refresh exit" 0 "$ec"
assert_contains "TP-SRM-26 replaced the guard" "$out" "Replaced ${SWAP}/safe-rm"
origin_refresh=$(stat -c '%d:%i' "$SWAP/origin-rm" 2>/dev/null || true)
assert_eq "TP-SRM-26 origin-rm was not moved" "$origin_again" "$origin_refresh"
if grep -q 'srm_invoked_as_rm' "$SWAP/safe-rm"; then
    t_pass "TP-SRM-26 guard is this program"
else
    t_fail "TP-SRM-26 guard is still the stub"
fi
out=$("$SWAP/rm" -rf --dry-run "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-26 -rf exit" 0 "$ec"
assert_contains "TP-SRM-26 -rf allowed" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-26 -rf is not unknown" "$(cat "$err")" "Unknown command"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-26 file still exists"
else
    t_fail "TP-SRM-26 file was removed"
fi

out=$(SRM_SWAP_ROOT="$SWAP" sh "$SAFE_RM" restore 2>"$err")
ec=$?
assert_eq "TP-SRM-SWAP-01 restore exit" 0 "$ec"
assert_contains "TP-SRM-SWAP-01 restored" "$out" "Restored ${SWAP}/rm"
if [ -f "$SWAP/rm" ] && [ ! -L "$SWAP/rm" ]; then
    t_pass "TP-SRM-SWAP-01 rm is the original file again"
else
    t_fail "TP-SRM-SWAP-01 rm was not restored"
fi
restored=$(stat -c '%d:%i' "$SWAP/rm" 2>/dev/null || true)
assert_eq "TP-SRM-SWAP-01 restored inode" "$origin_before" "$restored"
if [ -e "$SWAP/origin-rm" ]; then
    t_fail "TP-SRM-SWAP-01 origin-rm still exists"
else
    t_pass "TP-SRM-SWAP-01 origin-rm removed by restore"
fi
if [ -e "$SWAP/safe-rm" ]; then
    t_fail "TP-SRM-SWAP-01 safe-rm still exists"
else
    t_pass "TP-SRM-SWAP-01 safe-rm removed by restore"
fi
case "$SWAP" in
    /tmp/safe-rm-swap.*)
        scratch_rm -rf -- "$SWAP"
        ;;
esac

printf '\n== summary ==\n'
printf 'PASS=%s FAIL=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf 'RESULT: FAILED\n' >&2
    exit 1
fi
printf 'RESULT: OK\n'
exit 0
