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
assert_contains "TP-SRM-02 version names safe-rm" "$out" "safe-rm version 1.0.0"

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

# TP-SRM-12 a path inside the login home
inside="$REPO_ROOT"
out=$(srm "$inside" 2>"$err")
ec=$?
assert_eq "TP-SRM-12 inside-home exit" 1 "$ec"
assert_contains "TP-SRM-12 inside-home refused" "$(cat "$err")" "login home"
if [ -d "$inside" ]; then
    t_pass "TP-SRM-12 project directory still exists"
else
    t_fail "TP-SRM-12 project directory missing"
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

printf '\n== summary ==\n'
printf 'PASS=%s FAIL=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf 'RESULT: FAILED\n' >&2
    exit 1
fi
printf 'RESULT: OK\n'
exit 0
