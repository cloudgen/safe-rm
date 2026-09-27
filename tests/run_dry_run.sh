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

cleanup() {
    case "${SCRATCH-}" in
        /tmp/safe-rm-dry.*)
            if [ -n "${HOME-}" ] && [ "$SCRATCH" = "$HOME" ]; then
                return 0
            fi
            /bin/rm -rf -- "$SCRATCH"
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

# TP-SRM-18 about mentions the guard
out=$(sh "$SAFE_RM" about 2>/dev/null)
assert_contains "TP-SRM-18 about remove guard" "$out" "Remove guard:"

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
        /bin/rm -rf -- "$SWAP"
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
