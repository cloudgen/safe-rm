#!/bin/sh
# Domain suite for safe-rm. Remove checks use --dry-run, except TP-SRM-39.
# That check points SRM_SWAP_ROOT at /tmp/safe-rm-swap.* whose origin-rm
# exits 0 and does not unlink. The listed path remains.
# The swap block points HOME at /tmp/safe-rm-place.* and restores the login
# HOME before later checks.
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
    case "${REPORT_SWAP-}" in
        /tmp/safe-rm-swap.*)
            if [ -n "${HOME-}" ] && [ "$REPORT_SWAP" = "$HOME" ]; then
                return 0
            fi
            scratch_rm -rf -- "$REPORT_SWAP"
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
assert_contains "TP-SRM-32 help says place runs setup" "$out" "When this login may run setup, that setup runs"
assert_contains "TP-SRM-28 help says local install does not download" "$out" "does not download"
assert_contains "TP-SRM-28 help names the global bin" "$out" "/usr/local/bin/"
assert_contains "TP-SRM-28 help names the local bin" "$out" "\${HOME}/.local/bin/"
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

# TP-SRM-36 scratch directory stays searchable.
# mktemp -d applies umask, so 0177 leaves the directory at 0600.
# A mktemp that returns 0600 is the same failure. A 0600 directory cannot
# hold the path list, and removal of that directory fails.
srm36_work_now() {
    find /dev/shm/cache /tmp/cache "${HOME}/.cache" \
        -maxdepth 3 -type d -name 'safe-rm-work.*' -mmin -2 \
        2>/dev/null | sort
}
_real_mktemp=$(command -v mktemp 2>/dev/null || true)
_wrap="${SCRATCH}/mktemp-bin"
mkdir -p "$_wrap"
if [ -n "$_real_mktemp" ] && [ -x "$_real_mktemp" ]; then
    cat > "${_wrap}/mktemp" << EOF
#!/bin/sh
_dir=0
for _a in "\$@"; do
    [ "\$_a" = "-d" ] && _dir=1
done
if [ "\$_dir" -eq 1 ]; then
    _name=\$("${_real_mktemp}" "\$@") || exit 1
    chmod 0600 "\$_name" || exit 1
    printf '%s\\n' "\$_name"
    exit 0
fi
exec "${_real_mktemp}" "\$@"
EOF
    chmod 0755 "${_wrap}/mktemp"
    _srm36_before=$(srm36_work_now)
    out=$(PATH="${_wrap}:${PATH}" srm "$SCRATCH/leaf" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-36 mode 0600 dry-run exit" 0 "$ec"
    assert_contains "TP-SRM-36 mode 0600 allows the path" "$out" "Removal is allowed"
    assert_not_contains "TP-SRM-36 mode 0600 no permission denied" "$(cat "$err")" "Permission denied"
    _srm36_after=$(srm36_work_now)
    if [ "$_srm36_before" = "$_srm36_after" ]; then
        t_pass "TP-SRM-36 mode 0600 scratch directory was removed"
    else
        t_fail "TP-SRM-36 mode 0600 left a scratch directory"
    fi
else
    t_fail "TP-SRM-36 mktemp missing"
fi
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-36 mode 0600 file still exists"
else
    t_fail "TP-SRM-36 mode 0600 file was removed"
fi
_srm36_before=$(srm36_work_now)
out=$(umask 0177; srm "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-36 umask 0177 dry-run exit" 0 "$ec"
assert_contains "TP-SRM-36 umask 0177 allows the path" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-36 umask 0177 no permission denied" "$(cat "$err")" "Permission denied"
_srm36_after=$(srm36_work_now)
if [ "$_srm36_before" = "$_srm36_after" ]; then
    t_pass "TP-SRM-36 umask 0177 scratch directory was removed"
else
    t_fail "TP-SRM-36 umask 0177 left a scratch directory"
fi
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-36 umask 0177 file still exists"
else
    t_fail "TP-SRM-36 umask 0177 file was removed"
fi
unset _real_mktemp _wrap _srm36_before _srm36_after

# TP-SRM-40 the temp maker may be absent. The scratch directory is then
# a subdirectory of the cache folder, mode 0700, including under umask 0177.
_srm40_before=$(srm36_work_now)
out=$(umask 0177; SRM_MKTEMP_BIN= srm "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-40 absent mktemp dry-run exit" 0 "$ec"
assert_contains "TP-SRM-40 absent mktemp allows the path" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-40 absent mktemp no permission denied" "$(cat "$err")" "Permission denied"
assert_not_contains "TP-SRM-40 absent mktemp no scratch failure" "$(cat "$err")" "Could not create a scratch directory"
_srm40_after=$(srm36_work_now)
if [ "$_srm40_before" = "$_srm40_after" ]; then
    t_pass "TP-SRM-40 absent mktemp scratch directory was removed"
else
    t_fail "TP-SRM-40 absent mktemp left a scratch directory"
fi
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-40 absent mktemp file still exists"
else
    t_fail "TP-SRM-40 absent mktemp file was removed"
fi
_srm40_stub="${SCRATCH}/mktemp-missing"
mkdir -p "$_srm40_stub"
cat > "${_srm40_stub}/mktemp" << 'EOF'
#!/bin/sh
printf 'called\n' >> "${SRM40_MARK:?}"
exit 127
EOF
chmod 0755 "${_srm40_stub}/mktemp"
_srm40_mark="${SCRATCH}/mktemp-called"
: > "$_srm40_mark"
_srm40_before=$(srm36_work_now)
out=$(umask 0177; SRM40_MARK="$_srm40_mark" PATH="${_srm40_stub}:${PATH}" srm "$SCRATCH/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-40 failing mktemp dry-run exit" 0 "$ec"
assert_contains "TP-SRM-40 failing mktemp allows the path" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-40 failing mktemp no permission denied" "$(cat "$err")" "Permission denied"
if [ -s "$_srm40_mark" ]; then
    t_pass "TP-SRM-40 failing mktemp was invoked"
else
    t_fail "TP-SRM-40 failing mktemp was not invoked"
fi
_srm40_after=$(srm36_work_now)
if [ "$_srm40_before" = "$_srm40_after" ]; then
    t_pass "TP-SRM-40 failing mktemp scratch directory was removed"
else
    t_fail "TP-SRM-40 failing mktemp left a scratch directory"
fi
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-40 failing mktemp file still exists"
else
    t_fail "TP-SRM-40 failing mktemp file was removed"
fi
unset _srm40_before _srm40_after _srm40_stub _srm40_mark

# TP-SRM-42 a stop signal leaves the process. An empty scratch directory is
# not an empty operand. This process's cache leaf is removed on exit.
# Nothing is executed. The allowed path remains.
srm42_login=$(id -un 2>/dev/null || echo "unknown")
case "$srm42_login" in
    *[!A-Za-z0-9._-]*)
        srm42_login=$(printf '%s' "$srm42_login" | tr -c 'A-Za-z0-9._-' '_')
        ;;
esac
[ -n "$srm42_login" ] || srm42_login="unknown"
srm42_find_leaf() {
    _srm42_p=$1
    for _srm42_c in \
        "/dev/shm/cache/cache-safe-rm-${srm42_login}-${_srm42_p}" \
        "/tmp/cache/cache-safe-rm-${srm42_login}-${_srm42_p}" \
        "${HOME}/.cache/cache-safe-rm-${_srm42_p}"
    do
        if [ -d "$_srm42_c" ]; then
            printf '%s\n' "$_srm42_c"
            return 0
        fi
    done
    return 1
}
srm42_wait_hold() {
    _srm42_p=$1
    _srm42_i=0
    while [ "$_srm42_i" -lt 40 ]; do
        _srm42_leaf=$(srm42_find_leaf "$_srm42_p" 2>/dev/null || true)
        if [ -n "$_srm42_leaf" ] && find "$_srm42_leaf" -maxdepth 2 -type f -name hold 2>/dev/null | grep -q .; then
            printf '%s\n' "$_srm42_leaf"
            return 0
        fi
        _srm42_i=$((_srm42_i + 1))
        sleep 0.2
    done
    return 1
}
srm42_stop() {
    _srm42_stop=$1
    if [ -n "$_srm42_stop" ]; then
        kill -TERM "$_srm42_stop" 2>/dev/null || true
        wait "$_srm42_stop" 2>/dev/null || true
    fi
}

sh "$SAFE_RM" --dry-run rm --dry-run "$SCRATCH/leaf" >"$SCRATCH/srm42-plain.out" 2>"$SCRATCH/srm42-plain.err" &
srm42_pid=$!
wait "$srm42_pid"
srm42_ec=$?
assert_eq "TP-SRM-42 dry-run exit" 0 "$srm42_ec"
if srm42_find_leaf "$srm42_pid" >/dev/null 2>&1; then
    t_fail "TP-SRM-42 dry-run left the cache leaf"
else
    t_pass "TP-SRM-42 dry-run cache leaf was removed"
fi
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-42 dry-run file still exists"
else
    t_fail "TP-SRM-42 dry-run file was removed"
fi

srm42_fifo="$SCRATCH/srm42-signal.fifo"
rm -f "$srm42_fifo"
mkfifo "$srm42_fifo" || t_fail "TP-SRM-42 signal fifo"
SRM_SIGNAL_HOLD="$srm42_fifo" sh "$SAFE_RM" --dry-run rm --dry-run "$SCRATCH/leaf" >"$SCRATCH/srm42-signal.out" 2>"$SCRATCH/srm42-signal.err" &
srm42_pid=$!
srm42_leaf=$(srm42_wait_hold "$srm42_pid" || true)
if [ -z "$srm42_leaf" ]; then
    srm42_stop "$srm42_pid"
    t_fail "TP-SRM-42 signal did not reach the hold"
else
    srm42_mode=$(stat -c %a "$srm42_leaf" 2>/dev/null || echo "")
    assert_eq "TP-SRM-42 cache leaf mode 0700" "700" "$srm42_mode"
    kill -TERM "$srm42_pid"
    wait "$srm42_pid"
    srm42_ec=$?
    assert_eq "TP-SRM-42 signal exit" 1 "$srm42_ec"
    srm42_err=$(cat "$SCRATCH/srm42-signal.err")
    assert_contains "TP-SRM-42 signal says it stopped" "$srm42_err" "A signal interrupted the remove check"
    assert_not_contains "TP-SRM-42 signal is not an empty path" "$srm42_err" "empty path"
    assert_not_contains "TP-SRM-42 signal does not write /flags" "$srm42_err" "/flags"
    assert_not_contains "TP-SRM-42 signal does not write /path" "$srm42_err" "/path."
    assert_not_contains "TP-SRM-42 signal does not report a missing directory" "$srm42_err" "Directory nonexistent"
    if srm42_find_leaf "$srm42_pid" >/dev/null 2>&1; then
        t_fail "TP-SRM-42 signal left the cache leaf"
    else
        t_pass "TP-SRM-42 signal cache leaf was removed"
    fi
fi
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-42 signal file still exists"
else
    t_fail "TP-SRM-42 signal file was removed"
fi

srm42_fifo="$SCRATCH/srm42-gone.fifo"
rm -f "$srm42_fifo"
mkfifo "$srm42_fifo" || t_fail "TP-SRM-42 scratch fifo"
SRM_SIGNAL_HOLD="$srm42_fifo" sh "$SAFE_RM" --dry-run rm --dry-run "$SCRATCH/leaf" >"$SCRATCH/srm42-gone.out" 2>"$SCRATCH/srm42-gone.err" &
srm42_pid=$!
srm42_leaf=$(srm42_wait_hold "$srm42_pid" || true)
if [ -z "$srm42_leaf" ]; then
    srm42_stop "$srm42_pid"
    t_fail "TP-SRM-42 scratch removal did not reach the hold"
else
    srm42_work=$(find "$srm42_leaf" -maxdepth 1 -type d -name 'safe-rm-work.*' 2>/dev/null | head -n 1)
    case "$srm42_work" in
        "$srm42_leaf"/safe-rm-work.*)
            scratch_rm -rf -- "$srm42_work"
            ;;
        *)
            t_fail "TP-SRM-42 scratch directory was not under the cache leaf"
            srm42_work=
            ;;
    esac
    printf '\n' > "$srm42_fifo" &
    srm42_writer=$!
    wait "$srm42_pid"
    srm42_ec=$?
    kill "$srm42_writer" 2>/dev/null || true
    wait "$srm42_writer" 2>/dev/null || true
    assert_eq "TP-SRM-42 missing scratch exit" 1 "$srm42_ec"
    srm42_err=$(cat "$SCRATCH/srm42-gone.err")
    assert_contains "TP-SRM-42 missing scratch says it is gone" "$srm42_err" "scratch directory for the remove check is gone"
    assert_not_contains "TP-SRM-42 missing scratch is not an empty path" "$srm42_err" "empty path"
    assert_not_contains "TP-SRM-42 missing scratch does not write /flags" "$srm42_err" "/flags"
    assert_not_contains "TP-SRM-42 missing scratch does not write /path" "$srm42_err" "/path."
    if srm42_find_leaf "$srm42_pid" >/dev/null 2>&1; then
        t_fail "TP-SRM-42 missing scratch left the cache leaf"
    else
        t_pass "TP-SRM-42 missing scratch cache leaf was removed"
    fi
fi
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-42 missing scratch file still exists"
else
    t_fail "TP-SRM-42 missing scratch file was removed"
fi
unset srm42_login srm42_pid srm42_ec srm42_leaf srm42_mode srm42_err srm42_work srm42_writer srm42_fifo
unset -f srm42_find_leaf srm42_wait_hold srm42_stop

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
assert_not_contains "TP-SRM-09 fake user home is not a passwd search" "$(cat "$err")" "/etc/passwd"
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

# TP-SRM-37 '.' and '..' are refused when the directory itself would be allowed.
# A '..' in the middle stays the resolved directory. A name that starts with
# '-' is a path after '--'. Nothing here is removed.
out=$(cd "$SCRATCH/leaf" && sh "$SAFE_RM" --dry-run rm --dry-run . 2>"$err")
ec=$?
assert_eq "TP-SRM-37 dot exit" 1 "$ec"
assert_contains "TP-SRM-37 dot refused" "$(cat "$err")" "'.' or '..'"
assert_contains "TP-SRM-37 dot STOP" "$(cat "$err")" "STOP"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-37 dot left the file"
else
    t_fail "TP-SRM-37 dot removed the file"
fi
out=$(cd "$SCRATCH/leaf" && sh "$SAFE_RM" --dry-run rm --dry-run .. 2>"$err")
ec=$?
assert_eq "TP-SRM-37 dotdot exit" 1 "$ec"
assert_contains "TP-SRM-37 dotdot refused" "$(cat "$err")" "Refusing to remove"
if [ -d "$SCRATCH/leaf" ]; then
    t_pass "TP-SRM-37 dotdot left the directory"
else
    t_fail "TP-SRM-37 dotdot removed the directory"
fi
out=$(cd "$SCRATCH/leaf" && sh "$SAFE_RM" --dry-run rm --dry-run ./ 2>"$err")
ec=$?
assert_eq "TP-SRM-37 dot slash exit" 1 "$ec"
out=$(cd "$SCRATCH/leaf" && sh "$SAFE_RM" --dry-run rm --dry-run ./file 2>"$err")
ec=$?
assert_eq "TP-SRM-37 ./file exit" 0 "$ec"
assert_contains "TP-SRM-37 ./file allowed" "$out" "Removal is allowed"
if [ -f "$SCRATCH/leaf/file" ]; then
    t_pass "TP-SRM-37 ./file still exists"
else
    t_fail "TP-SRM-37 ./file was removed"
fi
out=$(srm "$SCRATCH/leaf/../leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-37 middle dotdot exit" 0 "$ec"
assert_contains "TP-SRM-37 middle dotdot allowed" "$out" "Removal is allowed"
if [ -d "$SCRATCH/leaf" ]; then
    t_pass "TP-SRM-37 middle dotdot left the directory"
else
    t_fail "TP-SRM-37 middle dotdot removed the directory"
fi
out=$(srm "$SCRATCH/leaf/.." 2>"$err")
ec=$?
assert_eq "TP-SRM-37 final dotdot exit" 1 "$ec"
assert_contains "TP-SRM-37 final dotdot refused" "$(cat "$err")" "'.' or '..'"
out=$(srm "$SCRATCH/leaf" . 2>"$err")
ec=$?
assert_eq "TP-SRM-37 mixed dot exit" 1 "$ec"
assert_contains "TP-SRM-37 mixed dot nothing removed" "$(cat "$err")" "Nothing was removed"
if [ -d "$SCRATCH/leaf" ]; then
    t_pass "TP-SRM-37 mixed dot left the allowed directory"
else
    t_fail "TP-SRM-37 mixed dot removed the allowed directory"
fi
json=$(cd "$SCRATCH/leaf" && sh "$SAFE_RM" --json --dry-run rm --dry-run . 2>"$err")
ec=$?
assert_eq "TP-SRM-37 json dot exit" 1 "$ec"
assert_contains "TP-SRM-37 json class" "$json" '"class":"DENY-DOT"'
assert_contains "TP-SRM-37 json verdict" "$json" '"verdict":"refuse"'
printf 'dash\n' > "$SCRATCH/-rf"
out=$(cd "$SCRATCH" && sh "$SAFE_RM" rm --dry-run -- -rf 2>"$err")
ec=$?
assert_eq "TP-SRM-37 hyphen path exit" 0 "$ec"
assert_contains "TP-SRM-37 hyphen path allowed" "$out" "Removal is allowed"
if [ -f "$SCRATCH/-rf" ]; then
    t_pass "TP-SRM-37 hyphen file still exists"
else
    t_fail "TP-SRM-37 hyphen file was removed"
fi
out=$(cd "$SCRATCH" && sh "$SAFE_RM" rm --dry-run -rf 2>"$err")
ec=$?
assert_eq "TP-SRM-37 bare -rf is a switch" 1 "$ec"
assert_contains "TP-SRM-37 bare -rf no path" "$(cat "$err")" "No path was given"
if [ -f "$SCRATCH/-rf" ]; then
    t_pass "TP-SRM-37 bare -rf left the file"
else
    t_fail "TP-SRM-37 bare -rf removed the file"
fi
help=$(sh "$SAFE_RM" help 2>/dev/null)
assert_contains "TP-SRM-37 help names --" "$help" "A name that starts with - is a path after --"
assert_contains "TP-SRM-37 help names dot" "$help" "'.' and '..' are refused"

# TP-SRM-20 an account home outside the remaining list is not refused
# because it appears in /etc/passwd. Dry-run only. The path is not created
# or removed. Homes under /home, the login home, and system directories
# stay on the list for those other reasons.
other=$(awk -F: -v h="$HOME" '
    $1 ~ /^#/ { next }
    $6 !~ /^\// { next }
    $6 == "/" || $6 == "/home" || $6 == h { next }
    index($6, "/home/") == 1 { next }
    index(h "/", $6 "/") == 1 { next }
    $6 == "/usr" || $6 == "/bin" || $6 == "/sbin" || $6 == "/etc" || $6 == "/var" || $6 == "/boot" || $6 == "/root" || $6 == "/lib" || $6 == "/lib64" || $6 == "/opt" || $6 == "/dev" || $6 == "/proc" || $6 == "/sys" { next }
    $6 == "/usr/bin" || index($6, "/usr/bin/") == 1 { next }
    { print $6; exit }
' /etc/passwd)
if [ -z "$other" ]; then
    t_fail "TP-SRM-20 no account home outside the remaining list"
else
    other_existed=0
    [ -e "$other" ] && other_existed=1
    out=$(srm "$other" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-20 other home exit" 0 "$ec"
    assert_contains "TP-SRM-20 other home allowed" "$out" "allowed"
    assert_not_contains "TP-SRM-20 other home does not name passwd" "$(cat "$err")" "/etc/passwd"
    json=$(srm_json "$other" 2>"$err")
    assert_contains "TP-SRM-20 json class" "$json" '"class":"ALLOW"'
    assert_not_contains "TP-SRM-20 json is not an account-home class" "$json" "DENY-ACCOUNT-HOME"
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

# TP-SRM-27 lifecycle verbs are switches. On safe-rm the bare word is that
# command. On the command named rm only the --switch is that command, and a
# bare word is a path checked with --dry-run. No live remove of a link.
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
assert_contains "TP-SRM-27 --help lists --reset" "$out" "--reset"
assert_contains "TP-SRM-27 --help lists --rm" "$out" "--rm"

out=$(sh "$SAFE_RM" --about 2>/dev/null)
assert_contains "TP-SRM-27 --about remove guard" "$out" "Remove guard:"

out=$(TTY=0 sh "$SAFE_RM" --menu </dev/null 2>/dev/null)
assert_contains "TP-SRM-27 --menu off a terminal is help" "$out" "--self-install"

out=$("$SCRATCH/rm" --version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 rm --version exit" 0 "$ec"
assert_contains "TP-SRM-27 rm --version names safe-rm" "$out" "safe-rm version ${ver}"
assert_not_contains "TP-SRM-27 rm --version is not GNU" "$out$(cat "$err")" "GNU coreutils"

out=$("$SCRATCH/rm" --help 2>/dev/null)
assert_contains "TP-SRM-27 rm --help lists --setup" "$out" "--setup"
assert_contains "TP-SRM-27 rm --help says bare version is a path" "$out" "rm version removes a link named version"

out=$(sh "$SAFE_RM" rm --version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 safe-rm rm --version exit" 0 "$ec"
assert_contains "TP-SRM-27 safe-rm rm --version names safe-rm" "$out" "safe-rm version ${ver}"

out=$("$SCRATCH/rm" --about 2>/dev/null)
assert_contains "TP-SRM-27 rm --about remove guard" "$out" "Remove guard:"

# Bare words on the command named rm are paths. A symlink named version
# stays in place under --dry-run. --version above is still this program.
# -restore stays a command and is not invoked here.
printf 'keep\n' > "$SCRATCH/link-target"
for name in help version about version-check self-update self-uninstall self-install install menu main setup restore reset; do
    ln -s link-target "$SCRATCH/$name"
    out=$(cd "$SCRATCH" && "$SCRATCH/rm" --dry-run "$name" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-27 rm ${name} exit" 0 "$ec"
    assert_contains "TP-SRM-27 rm ${name} is a path" "$out" "Dry-run: ${name} exists"
    assert_not_contains "TP-SRM-27 rm ${name} is not a command" "$out$(cat "$err")" "safe-rm version"
    if [ -L "$SCRATCH/$name" ]; then
        t_pass "TP-SRM-27 link ${name} still exists"
    else
        t_fail "TP-SRM-27 link ${name} was removed"
    fi
done

out=$(cd "$SCRATCH" && "$SCRATCH/rm" --version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 rm --version beside the link exit" 0 "$ec"
assert_contains "TP-SRM-27 rm --version beside the link" "$out" "safe-rm version ${ver}"
if [ -L "$SCRATCH/version" ]; then
    t_pass "TP-SRM-27 rm --version left the link"
else
    t_fail "TP-SRM-27 rm --version removed the link"
fi

out=$(cd "$SCRATCH" && sh "$SAFE_RM" --dry-run rm version 2>"$err")
ec=$?
assert_eq "TP-SRM-27 safe-rm rm version exit" 0 "$ec"
assert_contains "TP-SRM-27 safe-rm rm version is a path" "$out" "Dry-run: version exists"
assert_not_contains "TP-SRM-27 safe-rm rm version is not the version command" "$out$(cat "$err")" "safe-rm version"
if [ -L "$SCRATCH/version" ]; then
    t_pass "TP-SRM-27 safe-rm rm version left the link"
else
    t_fail "TP-SRM-27 safe-rm rm version removed the link"
fi

out=$("$SCRATCH/rm" --dry-run "$SCRATCH/version" 2>"$err")
ec=$?
assert_eq "TP-SRM-27 path version exit" 0 "$ec"
assert_contains "TP-SRM-27 path version allowed" "$out" "Removal is allowed"
assert_not_contains "TP-SRM-27 path version is not the version command" "$out" "safe-rm version"
if [ -L "$SCRATCH/version" ]; then
    t_pass "TP-SRM-27 path version still exists"
else
    t_fail "TP-SRM-27 path version was removed"
fi

out=$("$SCRATCH/rm" --version "$SCRATCH/missing-leaf" 2>"$err")
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
if [ -n "$eff" ] && [ ! -d "$eff" ]; then
    t_pass "TP-CACHE-02 effective cache directory was removed on exit"
else
    t_fail "TP-CACHE-02 effective cache still present: ${eff:-empty}"
fi
case "$eff" in
    /dev/shm/${app}|/dev/shm/${app}-*)
        t_fail "TP-CACHE-02 effective cache must not be a ram-drive project shape: ${eff}"
        ;;
    *)
        t_pass "TP-CACHE-02 effective cache is not a ram-drive project shape"
        ;;
esac
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
if [ -n "$skip_eff" ] && [ ! -d "$skip_eff" ]; then
    t_pass "TP-CACHE-02 skipped preferred cache leaf was removed on exit"
else
    t_fail "TP-CACHE-02 skipped preferred cache leaf still present: ${skip_eff:-empty}"
fi
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
gb_eff=$(printf '%s' "$gb" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
if [ -n "$gb_eff" ] && [ ! -d "$gb_eff" ]; then
    t_pass "TP-CACHE-02 gitbash cache leaf was removed on exit"
else
    t_fail "TP-CACHE-02 gitbash cache leaf still present: ${gb_eff:-empty}"
fi
mac=$(SRM_CACHE_HOST=mac sh "$SAFE_RM" --json about 2>/dev/null)
mac_pref=$(printf '%s' "$mac" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
mac_pid="${mac_pref##*-}"
assert_eq "TP-CACHE-02 mac preferred" "/tmp/cache/cache-${app}-${login}-${mac_pid}" "$mac_pref"
mac_fb=$(printf '%s' "$mac" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 mac 1st fallback" "${HOME}/Library/Caches/cache-${app}-${mac_pid}" "$mac_fb"
mac_fb2=$(printf '%s' "$mac" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
assert_eq "TP-CACHE-02 mac 2nd fallback" "${HOME}/cache/cache-${app}-${mac_pid}" "$mac_fb2"
mac_eff=$(printf '%s' "$mac" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
if [ -n "$mac_eff" ] && [ ! -d "$mac_eff" ]; then
    t_pass "TP-CACHE-02 mac cache leaf was removed on exit"
else
    t_fail "TP-CACHE-02 mac cache leaf still present: ${mac_eff:-empty}"
fi
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
fb=$(sh -c '. "$1"; SRM_MKTEMP_BIN= util_mktemp tmp' sh "$lib" 2>/dev/null) || fb=""
case "$fb" in
    /dev/shm/cache/cache-${app}-${login}-[0-9]*/${app}.tmp.*)
        base=${fb##*/}
        case "$base" in
            *'$$'*)
                t_fail "TP-CACHE-03 absent mktemp uses a dollar name: ${base}"
                ;;
            *)
                mode=$(stat -c '%a' "$fb" 2>/dev/null || echo "")
                if [ "$mode" = "600" ]; then
                    t_pass "TP-CACHE-03 absent mktemp writes a mode-0600 file under the cache leaf"
                else
                    t_fail "TP-CACHE-03 absent mktemp mode ${mode:-empty} for ${fb}"
                fi
                ;;
        esac
        ;;
    *)
        t_fail "TP-CACHE-03 absent mktemp unexpected: ${fb:-empty}"
        ;;
esac
if [ -n "$fb" ] && [ -f "$fb" ]; then
    scratch_rm -f -- "$fb"
fi
unset fb base mode
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
# HOME and SRM_SUDO stay inside this block so measure 1 does not edit the
# login rc and a failed measure 2 does not prompt for a password.
_saved_home=${HOME-}
LAYER_HOME=$(mktemp -d /tmp/safe-rm-place.XXXXXX) || exit 2
export HOME="${LAYER_HOME}"
export SRM_SUDO=false
usr_before=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
out=$(sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-SWAP-01 non-admin setup exit" 1 "$ec"
assert_contains "TP-SRM-SWAP-01 non-admin left the system rm" "$(cat "$err")" "/usr/bin/rm and /bin/rm were not moved."
usr_after=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
assert_eq "TP-SRM-SWAP-01 system rm unchanged" "$usr_before" "$usr_after"
out=$(sh "$SAFE_RM" reset 2>"$err")
ec=$?
assert_eq "TP-SRM-38 non-admin reset exit" 1 "$ec"
assert_contains "TP-SRM-38 non-admin left the system rm" "$(cat "$err")" "/usr/bin/rm and /bin/rm were not reset."
usr_after=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
assert_eq "TP-SRM-38 system rm unchanged" "$usr_before" "$usr_after"
if [ -f "${LAYER_HOME}/.local/bin/safe-rm" ]; then
    t_pass "TP-SRM-SWAP-01 measure 1 kept the home guard"
else
    t_fail "TP-SRM-SWAP-01 measure 1 missed the home guard"
fi

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

origin_reset=$(stat -c '%d:%i' "$SWAP/origin-rm" 2>/dev/null || true)
out=$(SRM_SWAP_ROOT="$SWAP" sh "$SAFE_RM" reset 2>"$err")
ec=$?
assert_eq "TP-SRM-38 reset exit" 0 "$ec"
assert_contains "TP-SRM-38 pointed rm" "$out" "Pointed ${SWAP}/rm at ${SWAP}/origin-rm"
assert_eq "TP-SRM-38 link target" "origin-rm" "$(readlink "$SWAP/rm" 2>/dev/null || true)"
assert_eq "TP-SRM-38 origin-rm stayed" "$origin_reset" "$(stat -c '%d:%i' "$SWAP/origin-rm" 2>/dev/null || true)"
if [ -f "$SWAP/safe-rm" ]; then
    t_pass "TP-SRM-38 safe-rm stayed"
else
    t_fail "TP-SRM-38 safe-rm was removed"
fi
if [ -e "${LAYER_HOME}/.local/bin/rm" ]; then
    t_pass "TP-SRM-38 home rm stayed"
else
    t_fail "TP-SRM-38 home rm was removed"
fi
out=$(SRM_SWAP_ROOT="$SWAP" sh "$SAFE_RM" reset 2>"$err")
ec=$?
assert_eq "TP-SRM-38 second reset exit" 0 "$ec"
assert_eq "TP-SRM-38 second link target" "origin-rm" "$(readlink "$SWAP/rm" 2>/dev/null || true)"
RESET_MISS=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
printf '#!/bin/sh\nexit 0\n' > "$RESET_MISS/rm"
chmod 0755 "$RESET_MISS/rm"
miss_before=$(stat -c '%d:%i' "$RESET_MISS/rm")
out=$(SRM_SWAP_ROOT="$RESET_MISS" sh "$SAFE_RM" reset 2>"$err")
ec=$?
assert_eq "TP-SRM-38 missing origin exit" 1 "$ec"
assert_contains "TP-SRM-38 missing origin changed nothing" "$(cat "$err")" "Nothing was changed."
assert_eq "TP-SRM-38 missing origin left rm" "$miss_before" "$(stat -c '%d:%i' "$RESET_MISS/rm" 2>/dev/null || true)"
if [ -L "$RESET_MISS/rm" ]; then
    t_fail "TP-SRM-38 missing origin replaced rm"
else
    t_pass "TP-SRM-38 missing origin left a regular rm"
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
case "$RESET_MISS" in
    /tmp/safe-rm-swap.*)
        scratch_rm -rf -- "$RESET_MISS"
        ;;
esac
unset RESET_MISS

# TP-SRM-29: /usr/bin/rm may be absent. /bin/rm may be the rm people type.
# Two fixture directories. Neither is executed. BusyBox stays a symlink
# target; origin-rm is the small program that runs busybox rm.
REG_U=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
REG_B=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
printf '#!/bin/sh\nexit 0\n' > "$REG_B/rm"
chmod 0755 "$REG_B/rm"
reg_before=$(stat -c '%d:%i' "$REG_B/rm")
out=$(SRM_SWAP_ROOT="$REG_U" SRM_SWAP_BIN="$REG_B" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-29 regular other-path exit" 0 "$ec"
assert_contains "TP-SRM-29 names the empty rm" "$out" "No original rm at ${REG_U}/rm"
assert_contains "TP-SRM-29 moves the rm that exists" "$out" "Moved ${REG_B}/rm to ${REG_B}/origin-rm"
if [ -e "$REG_U/rm" ] || [ -e "$REG_U/safe-rm" ] || [ -e "$REG_U/origin-rm" ]; then
    t_fail "TP-SRM-29 empty directory was written"
else
    t_pass "TP-SRM-29 empty directory was not written"
fi
if [ -L "$REG_B/rm" ]; then
    t_pass "TP-SRM-29 other-path rm is a symlink"
else
    t_fail "TP-SRM-29 other-path rm is not a symlink"
fi
assert_eq "TP-SRM-29 other-path origin inode" "$reg_before" "$(stat -c '%d:%i' "$REG_B/origin-rm" 2>/dev/null || true)"
out=$(SRM_SWAP_ROOT="$REG_U" SRM_SWAP_BIN="$REG_B" sh "$SAFE_RM" restore 2>"$err")
ec=$?
assert_eq "TP-SRM-29 regular restore exit" 0 "$ec"
assert_eq "TP-SRM-29 regular restored inode" "$reg_before" "$(stat -c '%d:%i' "$REG_B/rm" 2>/dev/null || true)"

BB_U=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
BB_B=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
printf '#!/bin/sh\nexit 0\n' > "$BB_B/busybox"
chmod 0755 "$BB_B/busybox"
ln -s busybox "$BB_B/rm"
bb_before=$(stat -c '%d:%i' "$BB_B/busybox")
out=$(SRM_SWAP_ROOT="$BB_U" SRM_SWAP_BIN="$BB_B" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-29 busybox exit" 0 "$ec"
assert_contains "TP-SRM-29 busybox skips empty rm" "$out" "No original rm at ${BB_U}/rm"
assert_contains "TP-SRM-29 busybox keeps the applet" "$out" "Kept BusyBox rm as ${BB_B}/origin-rm"
assert_contains "TP-SRM-29 busybox points rm" "$out" "Pointed ${BB_B}/rm at ${BB_B}/safe-rm"
if [ -e "$BB_U/rm" ] || [ -e "$BB_U/safe-rm" ] || [ -e "$BB_U/origin-rm" ]; then
    t_fail "TP-SRM-29 busybox wrote the empty directory"
else
    t_pass "TP-SRM-29 busybox left the empty directory alone"
fi
assert_contains "TP-SRM-29 busybox link target" "$(readlink "$BB_B/rm")" "${BB_B}/safe-rm"
assert_contains "TP-SRM-29 origin names busybox" "$(cat "$BB_B/origin-rm")" "safe-rm busybox-origin"
assert_contains "TP-SRM-29 origin runs busybox rm" "$(cat "$BB_B/origin-rm")" "${BB_B}/busybox"
assert_eq "TP-SRM-29 busybox inode unchanged" "$bb_before" "$(stat -c '%d:%i' "$BB_B/busybox" 2>/dev/null || true)"
out=$(SRM_SWAP_ROOT="$BB_U" SRM_SWAP_BIN="$BB_B" sh "$SAFE_RM" reset 2>"$err")
ec=$?
assert_eq "TP-SRM-38 busybox reset exit" 0 "$ec"
assert_eq "TP-SRM-38 busybox link target" "origin-rm" "$(readlink "$BB_B/rm" 2>/dev/null || true)"
assert_contains "TP-SRM-38 busybox origin stayed" "$(cat "$BB_B/origin-rm")" "safe-rm busybox-origin"
if [ -e "$BB_U/rm" ] || [ -e "$BB_U/origin-rm" ]; then
    t_fail "TP-SRM-38 busybox reset wrote the empty directory"
else
    t_pass "TP-SRM-38 busybox reset left the empty directory alone"
fi
out=$(SRM_SWAP_ROOT="$BB_U" SRM_SWAP_BIN="$BB_B" sh "$SAFE_RM" restore 2>"$err")
ec=$?
assert_eq "TP-SRM-29 busybox restore exit" 0 "$ec"
assert_eq "TP-SRM-29 busybox link restored" "busybox" "$(readlink "$BB_B/rm" 2>/dev/null || true)"
assert_eq "TP-SRM-29 busybox still the same file" "$bb_before" "$(stat -c '%d:%i' "$BB_B/busybox" 2>/dev/null || true)"
if [ -e "$BB_B/origin-rm" ]; then
    t_fail "TP-SRM-29 busybox origin-rm still exists"
else
    t_pass "TP-SRM-29 busybox origin-rm removed"
fi
if [ -e "$BB_B/safe-rm" ]; then
    t_fail "TP-SRM-29 busybox safe-rm still exists"
else
    t_pass "TP-SRM-29 busybox safe-rm removed"
fi

EMPTY_U=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
EMPTY_B=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
out=$(SRM_SWAP_ROOT="$EMPTY_U" SRM_SWAP_BIN="$EMPTY_B" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-29 neither path exit" 1 "$ec"
assert_contains "TP-SRM-29 neither path names both" "$(cat "$err")" "No original rm at ${EMPTY_U}/rm or ${EMPTY_B}/rm"
assert_contains "TP-SRM-29 neither path moved nothing" "$(cat "$err")" "Nothing was moved"
if [ -e "$EMPTY_U/safe-rm" ] || [ -e "$EMPTY_B/safe-rm" ]; then
    t_fail "TP-SRM-29 neither path installed a guard"
else
    t_pass "TP-SRM-29 neither path installed nothing"
fi

for _sd in "$REG_U" "$REG_B" "$BB_U" "$BB_B" "$EMPTY_U" "$EMPTY_B"; do
    case "$_sd" in
        /tmp/safe-rm-swap.*)
            scratch_rm -rf -- "$_sd"
            ;;
    esac
done
unset _sd REG_U REG_B BB_U BB_B EMPTY_U EMPTY_B reg_before bb_before

# TP-SRM-30 Termux. which rm is $PREFIX/bin/rm
# (/data/data/com.termux/files/usr/bin/rm). The fixture stands in for
# that prefix. Nothing in the fixture is executed. /usr/bin/rm stays.
usr_before=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
out=$(sh "$SAFE_RM" help 2>"$err")
assert_contains "TP-SRM-30 help names the Termux rm" "$out" "/data/data/com.termux/files/usr/bin/rm"
assert_contains "TP-SRM-30 help says no sudo" "$out" "No sudo"

out=$(SRM_TERMUX_PREFIX=/tmp/not-a-swap sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-30 foreign prefix exit" 1 "$ec"
assert_contains "TP-SRM-30 foreign prefix left the system rm" "$(cat "$err")" "/usr/bin/rm and /bin/rm were not moved."
assert_not_contains "TP-SRM-30 foreign prefix is not an admin-login error" "$(cat "$err")" "needs an admin login"
assert_eq "TP-SRM-30 foreign prefix left system rm" "$usr_before" "$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)"

TX=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
mkdir -p "$TX/bin"
out=$(SRM_TERMUX_PREFIX="$TX" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-30 empty prefix exit" 1 "$ec"
assert_contains "TP-SRM-30 empty prefix names the rm" "$(cat "$err")" "No original rm at ${TX}/bin/rm"
assert_contains "TP-SRM-30 empty prefix moved nothing" "$(cat "$err")" "Nothing was moved"
assert_not_contains "TP-SRM-30 empty prefix is not the admin error" "$(cat "$err")" "needs an admin login"
if [ -e "$TX/bin/safe-rm" ] || [ -e "$TX/bin/origin-rm" ]; then
    t_fail "TP-SRM-30 empty prefix wrote a guard"
else
    t_pass "TP-SRM-30 empty prefix wrote nothing"
fi

printf '#!/bin/sh\nexit 0\n' > "$TX/bin/rm"
chmod 0755 "$TX/bin/rm"
tx_before=$(stat -c '%d:%i' "$TX/bin/rm")
out=$(SRM_TERMUX_PREFIX="$TX" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-30 regular exit" 0 "$ec"
assert_contains "TP-SRM-30 moved prefix rm" "$out" "Moved ${TX}/bin/rm to ${TX}/bin/origin-rm"
assert_contains "TP-SRM-30 pointed prefix rm" "$out" "Pointed ${TX}/bin/rm at ${TX}/bin/safe-rm"
assert_not_contains "TP-SRM-30 regular is not the admin error" "$out$(cat "$err")" "needs an admin login"
if [ -L "$TX/bin/rm" ]; then
    t_pass "TP-SRM-30 prefix rm is a symlink"
else
    t_fail "TP-SRM-30 prefix rm is not a symlink"
fi
assert_contains "TP-SRM-30 prefix link target" "$(readlink "$TX/bin/rm")" "${TX}/bin/safe-rm"
assert_eq "TP-SRM-30 origin inode" "$tx_before" "$(stat -c '%d:%i' "$TX/bin/origin-rm" 2>/dev/null || true)"
assert_eq "TP-SRM-30 regular left system rm" "$usr_before" "$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)"
if [ -d "$TX/bin/origin-rm" ]; then
    t_fail "TP-SRM-30 origin-rm is a directory"
else
    t_pass "TP-SRM-30 origin-rm is not a directory"
fi
out=$(SRM_TERMUX_PREFIX="$TX" sh "$SAFE_RM" setup 2>"$err")
ec=$?
assert_eq "TP-SRM-30 second setup exit" 0 "$ec"
assert_contains "TP-SRM-30 second setup sees origin" "$out" "Already swapped"
assert_eq "TP-SRM-30 second setup did not move again" "$tx_before" "$(stat -c '%d:%i' "$TX/bin/origin-rm" 2>/dev/null || true)"
out=$(SRM_TERMUX_PREFIX="$TX" sh "$SAFE_RM" restore 2>"$err")
ec=$?
assert_eq "TP-SRM-30 restore exit" 0 "$ec"
assert_contains "TP-SRM-30 restored" "$out" "Restored ${TX}/bin/rm"
assert_eq "TP-SRM-30 restored inode" "$tx_before" "$(stat -c '%d:%i' "$TX/bin/rm" 2>/dev/null || true)"
if [ -e "$TX/bin/origin-rm" ]; then
    t_fail "TP-SRM-30 origin-rm still exists"
else
    t_pass "TP-SRM-30 origin-rm removed by restore"
fi
if [ -e "$TX/bin/safe-rm" ]; then
    t_fail "TP-SRM-30 safe-rm still exists"
else
    t_pass "TP-SRM-30 safe-rm removed by restore"
fi
if [ -f "$TX/bin/rm" ] && [ ! -L "$TX/bin/rm" ]; then
    t_pass "TP-SRM-30 restored rm is the original file"
else
    t_fail "TP-SRM-30 restored rm is not the original file"
fi

for _kind in toybox coreutils; do
    KD=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
    mkdir -p "$KD/bin"
    printf '#!/bin/sh\nexit 0\n' > "$KD/bin/${_kind}"
    chmod 0755 "$KD/bin/${_kind}"
    ln -s "${_kind}" "$KD/bin/rm"
    kd_before=$(stat -c '%d:%i' "$KD/bin/${_kind}")
    out=$(SRM_TERMUX_PREFIX="$KD" sh "$SAFE_RM" setup 2>"$err")
    ec=$?
    assert_eq "TP-SRM-30 ${_kind} exit" 0 "$ec"
    assert_contains "TP-SRM-30 ${_kind} keeps the applet" "$out" "Kept ${_kind} rm as ${KD}/bin/origin-rm"
    assert_contains "TP-SRM-30 ${_kind} link target" "$(readlink "$KD/bin/rm")" "${KD}/bin/safe-rm"
    assert_contains "TP-SRM-30 ${_kind} origin marker" "$(cat "$KD/bin/origin-rm")" "safe-rm applet-origin"
    assert_contains "TP-SRM-30 ${_kind} origin runs rm" "$(cat "$KD/bin/origin-rm")" "${KD}/bin/${_kind}"
    assert_eq "TP-SRM-30 ${_kind} inode unchanged" "$kd_before" "$(stat -c '%d:%i' "$KD/bin/${_kind}" 2>/dev/null || true)"
    assert_eq "TP-SRM-30 ${_kind} left system rm" "$usr_before" "$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)"
    out=$(SRM_TERMUX_PREFIX="$KD" sh "$SAFE_RM" restore 2>"$err")
    ec=$?
    assert_eq "TP-SRM-30 ${_kind} restore exit" 0 "$ec"
    assert_eq "TP-SRM-30 ${_kind} link restored" "${_kind}" "$(readlink "$KD/bin/rm" 2>/dev/null || true)"
    assert_eq "TP-SRM-30 ${_kind} still the same file" "$kd_before" "$(stat -c '%d:%i' "$KD/bin/${_kind}" 2>/dev/null || true)"
    if [ -e "$KD/bin/origin-rm" ]; then
        t_fail "TP-SRM-30 ${_kind} origin-rm still exists"
    else
        t_pass "TP-SRM-30 ${_kind} origin-rm removed"
    fi
    if [ -e "$KD/bin/safe-rm" ]; then
        t_fail "TP-SRM-30 ${_kind} safe-rm still exists"
    else
        t_pass "TP-SRM-30 ${_kind} safe-rm removed"
    fi
    case "$KD" in
        /tmp/safe-rm-swap.*)
            scratch_rm -rf -- "$KD"
            ;;
    esac
done

case "$TX" in
    /tmp/safe-rm-swap.*)
        scratch_rm -rf -- "$TX"
        ;;
esac
unset _kind KD kd_before TX tx_before usr_before
if [ -n "${_saved_home}" ]; then
    export HOME="${_saved_home}"
else
    unset HOME
fi
unset SRM_SUDO _saved_home
case "${LAYER_HOME}" in
    /tmp/safe-rm-place.*)
        scratch_rm -rf -- "${LAYER_HOME}"
        ;;
esac
unset LAYER_HOME

# TP-SRM-31 Termux blacklist. $PREFIX stands for /usr.
# $PREFIX/var stands for /var. The fixture is only /tmp/safe-rm-swap.*.
# Every remove check is a dry-run. The symlink named rm is this program.
BL=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
mkdir -p "$BL/bin" "$BL/etc" "$BL/var/log" "$BL/lib/inside" "$BL/lib64" \
    "$BL/opt" "$BL/sbin" "$BL/boot" "$BL/share" "$BL/tmp" "$BL/include" \
    "$BL/libexec"
printf 'tool\n' > "$BL/bin/tool"
printf 'extra\n' > "$BL/sbin/extra"
ln -s "$SAFE_RM" "$BL/bin/rm"

tx_refuse() {
    _label=$1
    _path=$2
    _expect=$3
    out=$(SRM_TERMUX_PREFIX="$BL" sh "$SAFE_RM" --dry-run rm --dry-run "$_path" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-31 ${_label} exit" 1 "$ec"
    assert_contains "TP-SRM-31 ${_label} refuses" "$(cat "$err")" "Refusing to remove"
    assert_contains "TP-SRM-31 ${_label} reason" "$(cat "$err")" "$_expect"
    if [ -e "$_path" ] || [ -L "$_path" ]; then
        t_pass "TP-SRM-31 ${_label} still exists"
    else
        t_fail "TP-SRM-31 ${_label} was removed"
    fi
}

tx_allow() {
    _label=$1
    _path=$2
    out=$(SRM_TERMUX_PREFIX="$BL" sh "$SAFE_RM" --dry-run rm --dry-run "$_path" 2>"$err")
    ec=$?
    assert_eq "TP-SRM-31 ${_label} exit" 0 "$ec"
    assert_contains "TP-SRM-31 ${_label} allowed" "$out" "Removal is allowed"
    if [ -e "$_path" ] || [ -L "$_path" ]; then
        t_pass "TP-SRM-31 ${_label} still exists"
    else
        t_fail "TP-SRM-31 ${_label} was removed"
    fi
}

tx_refuse "prefix" "$BL" "system directory"
tx_refuse "var" "$BL/var" "system directory"
tx_refuse "var slash" "$BL/var/" "system directory"
tx_refuse "etc" "$BL/etc" "system directory"
tx_refuse "lib" "$BL/lib" "system directory"
tx_refuse "lib64" "$BL/lib64" "system directory"
tx_refuse "opt" "$BL/opt" "system directory"
tx_refuse "sbin" "$BL/sbin" "system directory"
tx_refuse "boot" "$BL/boot" "system directory"
tx_refuse "bin" "$BL/bin" "${BL}/bin"
tx_refuse "bin tool" "$BL/bin/tool" "${BL}/bin"
tx_refuse "bin rm" "$BL/bin/rm" "${BL}/bin"

tx_allow "share" "$BL/share"
tx_allow "include" "$BL/include"
tx_allow "tmp" "$BL/tmp"
tx_allow "libexec" "$BL/libexec"
tx_allow "var log" "$BL/var/log"
tx_allow "lib inside" "$BL/lib/inside"
tx_allow "sbin extra" "$BL/sbin/extra"

# The tablet command: rm -rf $PREFIX/var --dry-run
out=$(SRM_TERMUX_PREFIX="$BL" "$BL/bin/rm" -rf "$BL/var" --dry-run 2>"$err")
ec=$?
assert_eq "TP-SRM-31 phone form exit" 1 "$ec"
assert_contains "TP-SRM-31 phone form refuses" "$(cat "$err")" "Refusing to remove ${BL}/var"
assert_contains "TP-SRM-31 phone form system" "$(cat "$err")" "system directory"
if [ -d "$BL/var" ]; then
    t_pass "TP-SRM-31 phone form var remains"
else
    t_fail "TP-SRM-31 phone form removed var"
fi

out=$(SRM_TERMUX_PREFIX="$BL" sh "$SAFE_RM" --dry-run rm --dry-run "$BL/share" "$BL/var" 2>"$err")
ec=$?
assert_eq "TP-SRM-31 mixed exit" 1 "$ec"
if [ -d "$BL/share" ] && [ -d "$BL/var" ]; then
    t_pass "TP-SRM-31 mixed paths remain"
else
    t_fail "TP-SRM-31 mixed removed a path"
fi

out=$(sh "$SAFE_RM" --dry-run rm --dry-run "$BL/var" 2>"$err")
ec=$?
assert_eq "TP-SRM-31 no prefix exit" 0 "$ec"
assert_contains "TP-SRM-31 no prefix allows scratch var" "$out" "Removal is allowed"
if [ -d "$BL/var" ]; then
    t_pass "TP-SRM-31 no prefix var remains"
else
    t_fail "TP-SRM-31 no prefix removed var"
fi

out=$(SRM_TERMUX_PREFIX=/tmp/not-a-swap sh "$SAFE_RM" --dry-run rm --dry-run "$BL/var" 2>"$err")
ec=$?
assert_eq "TP-SRM-31 foreign prefix exit" 0 "$ec"
assert_contains "TP-SRM-31 foreign prefix allows scratch var" "$out" "Removal is allowed"

out=$(sh "$SAFE_RM" --dry-run rm --dry-run /var 2>"$err")
ec=$?
assert_eq "TP-SRM-31 /var exit" 1 "$ec"
assert_contains "TP-SRM-31 /var refused" "$(cat "$err")" "system directory"
if [ -d /var ]; then
    t_pass "TP-SRM-31 /var still exists"
else
    t_fail "TP-SRM-31 /var missing"
fi

out=$(SRM_TERMUX_PREFIX="$BL" sh "$SAFE_RM" --dry-run rm --dry-run /var 2>"$err")
ec=$?
assert_eq "TP-SRM-31 /var with prefix exit" 1 "$ec"
assert_contains "TP-SRM-31 /var with prefix refused" "$(cat "$err")" "system directory"

out=$(SRM_TERMUX_PREFIX="$BL" sh "$SAFE_RM" --dry-run rm --dry-run /usr/bin 2>"$err")
ec=$?
assert_eq "TP-SRM-31 /usr/bin with prefix exit" 1 "$ec"
assert_contains "TP-SRM-31 /usr/bin sentence" "$(cat "$err")" "/usr/bin or something inside it"
if [ -d /usr/bin ]; then
    t_pass "TP-SRM-31 /usr/bin still exists"
else
    t_fail "TP-SRM-31 /usr/bin missing"
fi

out=$(SRM_TERMUX_PREFIX="$BL" sh "$SAFE_RM" --json --dry-run rm --dry-run "$BL/var" 2>"$err")
ec=$?
assert_eq "TP-SRM-31 json exit" 1 "$ec"
assert_contains "TP-SRM-31 json class" "$out" '"class":"DENY-HOST"'
assert_contains "TP-SRM-31 json verdict" "$out" '"verdict":"refuse"'

out=$(sh "$SAFE_RM" help 2>/dev/null)
assert_contains "TP-SRM-31 help names prefix var" "$out" "\$PREFIX/var"
out=$(sh "$SAFE_RM" about 2>/dev/null)
assert_contains "TP-SRM-31 about names prefix var" "$out" "\$PREFIX/var"

case "$BL" in
    /tmp/safe-rm-swap.*)
        scratch_rm -rf -- "$BL"
        ;;
esac
unset _label _path _expect BL

# TP-SRM-39. The success line names the caller and each path.
# origin-rm here exits 0 and does not unlink. The host remover is not used.
REPORT_SWAP=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
cat > "$REPORT_SWAP/origin-rm" << EOF
#!/bin/sh
printf '%s\n' "\$@" >> "${REPORT_SWAP}/stub.log"
exit 0
EOF
chmod 0755 "$REPORT_SWAP/origin-rm"
printf 'keep\n' > "$REPORT_SWAP/leaf"
printf 'keep\n' > "$REPORT_SWAP/leaf-b"
cat > "$REPORT_SWAP/caller.sh" << EOF
#!/bin/sh
sh "$SAFE_RM" "\$@"
EOF
chmod 0755 "$REPORT_SWAP/caller.sh"
cat > "$REPORT_SWAP/rc.sh" << EOF
sh "$SAFE_RM" rm --verbal -- "$REPORT_SWAP/leaf"
EOF
usr_before=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)

out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" rm -- "$REPORT_SWAP/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-41 default exit" 0 "$ec"
assert_eq "TP-SRM-41 default stdout empty" "" "$out"
assert_not_contains "TP-SRM-41 default hides the caller line" "$out" "Caller"
assert_not_contains "TP-SRM-41 default hides the OK mark" "$out" "[OK]"
if [ -f "$REPORT_SWAP/leaf" ]; then
    t_pass "TP-SRM-41 default leaf still exists"
else
    t_fail "TP-SRM-41 default leaf was removed"
fi
assert_contains "TP-SRM-41 fixture received the path" "$(cat "$REPORT_SWAP/stub.log" 2>/dev/null || true)" "$REPORT_SWAP/leaf"
assert_not_contains "TP-SRM-41 default did not forward --verbal" "$(cat "$REPORT_SWAP/stub.log" 2>/dev/null || true)" "--verbal"
assert_eq "TP-SRM-39 system rm unchanged" "$usr_before" "$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)"

: > "$REPORT_SWAP/stub.log"
out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" --verbal rm -- "$REPORT_SWAP/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-39 caller exit" 0 "$ec"
assert_contains "TP-SRM-39 names the caller and the path" "$out" "Caller ${REPORT_SWAP}/caller.sh removed ${REPORT_SWAP}/leaf."
assert_contains "TP-SRM-39 keeps the OK mark" "$out" "[OK]"
assert_not_contains "TP-SRM-39 plain line has no italic" "$out" "$(printf '\033[3m')"
assert_not_contains "TP-SRM-41 --verbal before rm is not forwarded" "$(cat "$REPORT_SWAP/stub.log" 2>/dev/null || true)" "--verbal"
if [ -f "$REPORT_SWAP/leaf" ]; then
    t_pass "TP-SRM-39 leaf still exists"
else
    t_fail "TP-SRM-39 leaf was removed"
fi
assert_contains "TP-SRM-39 fixture received the path" "$(cat "$REPORT_SWAP/stub.log" 2>/dev/null || true)" "$REPORT_SWAP/leaf"

out=$(TTY=1 SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" rm --verbal -- "$REPORT_SWAP/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-39 italic exit" 0 "$ec"
assert_contains "TP-SRM-39 italic caller" "$out" "$(printf '\033[3m')${REPORT_SWAP}/caller.sh$(printf '\033[0m')"
assert_contains "TP-SRM-39 italic path" "$out" "$(printf '\033[3m')${REPORT_SWAP}/leaf$(printf '\033[0m')"
if [ -f "$REPORT_SWAP/leaf" ]; then
    t_pass "TP-SRM-39 italic leaf still exists"
else
    t_fail "TP-SRM-39 italic leaf was removed"
fi

out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" rm --verbal -- "$REPORT_SWAP/leaf" "$REPORT_SWAP/leaf-b" 2>"$err")
ec=$?
assert_eq "TP-SRM-39 two paths exit" 0 "$ec"
assert_contains "TP-SRM-39 two paths" "$out" "Caller ${REPORT_SWAP}/caller.sh removed ${REPORT_SWAP}/leaf, ${REPORT_SWAP}/leaf-b."
if [ -f "$REPORT_SWAP/leaf-b" ]; then
    t_pass "TP-SRM-39 second leaf still exists"
else
    t_fail "TP-SRM-39 second leaf was removed"
fi

out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh -c 'sh "$1" rm --verbal -- "$2"' sh "$SAFE_RM" "$REPORT_SWAP/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-39 sh -c exit" 0 "$ec"
assert_contains "TP-SRM-39 sh -c names a script ancestor" "$out" "run_dry_run.sh"
assert_contains "TP-SRM-39 sh -c names the path" "$out" "removed ${REPORT_SWAP}/leaf."
assert_not_contains "TP-SRM-39 sh -c does not call the path the caller" "$out" "Caller ${REPORT_SWAP}/leaf removed"

out=$(SRM_SWAP_ROOT="$REPORT_SWAP" bash --noprofile --rcfile "$REPORT_SWAP/rc.sh" -ic true </dev/null 2>"$err")
ec=$?
assert_eq "TP-SRM-39 rcfile exit" 0 "$ec"
assert_contains "TP-SRM-39 rcfile names the startup script" "$out" "Caller ${REPORT_SWAP}/rc.sh removed ${REPORT_SWAP}/leaf."

out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" rm --json -- "$REPORT_SWAP/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-39 json exit" 0 "$ec"
assert_contains "TP-SRM-39 json removed" "$out" '"removed":"true"'
assert_contains "TP-SRM-39 json names the caller" "$out" "Caller ${REPORT_SWAP}/caller.sh removed ${REPORT_SWAP}/leaf."
assert_not_contains "TP-SRM-39 json has no italic" "$out" "$(printf '\033[3m')"
assert_not_contains "TP-SRM-41 json has no OK mark" "$out" "[OK]"
if [ -f "$REPORT_SWAP/leaf" ]; then
    t_pass "TP-SRM-39 json leaf still exists"
else
    t_fail "TP-SRM-39 json leaf was removed"
fi

: > "$REPORT_SWAP/stub.log"
out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" rm --quiet -- "$REPORT_SWAP/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-39 quiet exit" 0 "$ec"
assert_not_contains "TP-SRM-39 quiet hides the caller line" "$out" "Caller"
if [ -f "$REPORT_SWAP/leaf" ]; then
    t_pass "TP-SRM-39 quiet leaf still exists"
else
    t_fail "TP-SRM-39 quiet leaf was removed"
fi

: > "$REPORT_SWAP/stub.log"
out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" rm --verbal --quiet -- "$REPORT_SWAP/leaf" 2>"$err")
ec=$?
assert_eq "TP-SRM-41 verbal quiet exit" 0 "$ec"
assert_not_contains "TP-SRM-41 verbal quiet hides the caller line" "$out" "Caller"
assert_not_contains "TP-SRM-41 verbal quiet hides the OK mark" "$out" "[OK]"
assert_contains "TP-SRM-41 verbal quiet still removed" "$(cat "$REPORT_SWAP/stub.log" 2>/dev/null || true)" "$REPORT_SWAP/leaf"
if [ -f "$REPORT_SWAP/leaf" ]; then
    t_pass "TP-SRM-41 verbal quiet leaf still exists"
else
    t_fail "TP-SRM-41 verbal quiet leaf was removed"
fi

: > "$REPORT_SWAP/stub.log"
out=$(SRM_SWAP_ROOT="$REPORT_SWAP" sh "$REPORT_SWAP/caller.sh" rm -- / 2>"$err")
ec=$?
assert_eq "TP-SRM-39 refuse exit" 1 "$ec"
assert_contains "TP-SRM-39 refuse stops" "$(cat "$err")" "Nothing was removed"
assert_not_contains "TP-SRM-39 refuse has no caller line" "$out" "Caller"
if [ -s "$REPORT_SWAP/stub.log" ]; then
    t_fail "TP-SRM-39 refuse exec'd the fixture"
else
    t_pass "TP-SRM-39 refuse did not exec the fixture"
fi
if [ -d / ]; then
    t_pass "TP-SRM-39 root remains"
else
    t_fail "TP-SRM-39 root missing"
fi

out=$(sh "$SAFE_RM" help 2>/dev/null)
assert_contains "TP-SRM-39 help names the caller line" "$out" "names the caller and each path"
assert_contains "TP-SRM-41 help names --verbal" "$out" "--verbal"
assert_contains "TP-SRM-41 help says the line is hidden by default" "$out" "hidden by default"

assert_eq "TP-SRM-39 system rm still unchanged" "$usr_before" "$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)"

case "$REPORT_SWAP" in
    /tmp/safe-rm-swap.*)
        scratch_rm -rf -- "$REPORT_SWAP"
        ;;
esac
unset REPORT_SWAP usr_before

printf '\n== summary ==\n'
printf 'PASS=%s FAIL=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf 'RESULT: FAILED\n' >&2
    exit 1
fi
printf 'RESULT: OK\n'
exit 0
