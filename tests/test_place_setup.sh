#!/bin/sh
# TP-SRM-32. self-install and self-update run setup.
# HOME is a scratch directory in this file only. The fixture rm is never executed.
# Cleanup uses origin-rm, not the guard.
set -u

TESTS_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${TESTS_ROOT}/.." && pwd)
SAFE_RM="${REPO_ROOT}/src/safe-rm"
PASS=0
FAIL=0

HOST_RM_BEFORE=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)

scratch_rm() {
    if [ -x /usr/bin/origin-rm ]; then
        /usr/bin/origin-rm "$@"
    elif [ -x /bin/origin-rm ]; then
        /bin/origin-rm "$@"
    else
        /bin/rm "$@"
    fi
}

rm_tree() {
    _tree=${1-}
    case "${_tree}" in
        /tmp/safe-rm-swap.*|/tmp/safe-rm-place.*)
            if [ -n "${HOME-}" ] && [ "${_tree}" = "${HOME}" ]; then
                return 0
            fi
            scratch_rm -rf -- "${_tree}"
            ;;
    esac
}

CLEAN_SWAP=
CLEAN_HOME=
CLEAN_CHAN=
CLEAN_PLAIN=
CLEAN_TX=
cleanup() {
    rm_tree "${CLEAN_SWAP}"
    rm_tree "${CLEAN_HOME}"
    rm_tree "${CLEAN_CHAN}"
    rm_tree "${CLEAN_PLAIN}"
    rm_tree "${CLEAN_TX}"
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

host_rm_same() {
    _now=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
    assert_eq "$1" "$HOST_RM_BEFORE" "$_now"
}

printf 'safe-rm place runs setup\n'
printf 'script: %s\n' "$SAFE_RM"

CLEAN_SWAP=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
CLEAN_HOME=$(mktemp -d /tmp/safe-rm-place.XXXXXX) || exit 2
USER_BIN="${CLEAN_HOME}/.local/bin"
GLOBAL_BIN="${CLEAN_HOME}/global-bin"
mkdir -p "$USER_BIN" "$GLOBAL_BIN"
printf '#!/bin/sh\nexit 0\n' > "$CLEAN_SWAP/rm"
chmod 0755 "$CLEAN_SWAP/rm"
origin_before=$(stat -c '%d:%i' "$CLEAN_SWAP/rm")

out=$(HOME="$CLEAN_HOME" USER_BIN="$USER_BIN" GLOBAL_BIN="$GLOBAL_BIN" \
    SRM_SWAP_ROOT="$CLEAN_SWAP" \
    sh "$SAFE_RM" self-install 2>&1)
ec=$?
assert_eq "TP-SRM-32 self-install exit" 0 "$ec"
assert_contains "TP-SRM-32 self-install moved rm" "$out" "Moved ${CLEAN_SWAP}/rm to ${CLEAN_SWAP}/origin-rm"
assert_contains "TP-SRM-32 self-install pointed rm" "$out" "Pointed ${CLEAN_SWAP}/rm at ${CLEAN_SWAP}/safe-rm"
if [ -L "$CLEAN_SWAP/rm" ]; then
    t_pass "TP-SRM-32 rm is a symlink"
else
    t_fail "TP-SRM-32 rm is not a symlink"
fi
assert_eq "TP-SRM-32 link target" "${CLEAN_SWAP}/safe-rm" "$(readlink "$CLEAN_SWAP/rm" 2>/dev/null || true)"
assert_eq "TP-SRM-32 origin-rm is the original file" "$origin_before" "$(stat -c '%d:%i' "$CLEAN_SWAP/origin-rm" 2>/dev/null || true)"
if cmp -s "$USER_BIN/safe-rm" "$CLEAN_SWAP/safe-rm"; then
    t_pass "TP-SRM-32 guard is the placed file"
else
    t_fail "TP-SRM-32 guard is not the placed file"
fi
host_rm_same "TP-SRM-32 self-install left /usr/bin/rm"

origin_swapped=$(stat -c '%d:%i' "$CLEAN_SWAP/origin-rm" 2>/dev/null || true)
printf '#!/bin/sh\nprintf "STALE\\n"\nexit 9\n' > "$CLEAN_SWAP/safe-rm"
chmod 0755 "$CLEAN_SWAP/safe-rm"
out=$(HOME="$CLEAN_HOME" USER_BIN="$USER_BIN" GLOBAL_BIN="$GLOBAL_BIN" \
    SRM_SWAP_ROOT="$CLEAN_SWAP" \
    sh "$SAFE_RM" self-install 2>&1)
ec=$?
assert_eq "TP-SRM-32 second self-install exit" 0 "$ec"
assert_contains "TP-SRM-32 second self-install already there" "$out" "already installed"
assert_contains "TP-SRM-32 second self-install replaced the guard" "$out" "Replaced ${CLEAN_SWAP}/safe-rm"
assert_eq "TP-SRM-32 second self-install did not move origin-rm" "$origin_swapped" "$(stat -c '%d:%i' "$CLEAN_SWAP/origin-rm" 2>/dev/null || true)"
if cmp -s "$USER_BIN/safe-rm" "$CLEAN_SWAP/safe-rm"; then
    t_pass "TP-SRM-32 second guard is the placed file"
else
    t_fail "TP-SRM-32 second guard is not the placed file"
fi

printf '\n# place-setup-marker\n' >> "$USER_BIN/safe-rm"
chmod 0700 "$USER_BIN/safe-rm"
printf '#!/bin/sh\nprintf "STALE\\n"\nexit 9\n' > "$CLEAN_SWAP/safe-rm"
chmod 0755 "$CLEAN_SWAP/safe-rm"
out=$(HOME="$CLEAN_HOME" USER_BIN="$USER_BIN" GLOBAL_BIN="$GLOBAL_BIN" \
    SCRIPT_URL="file://${USER_BIN}/safe-rm" \
    SRM_SWAP_ROOT="$CLEAN_SWAP" \
    sh "$SAFE_RM" self-update 2>&1)
ec=$?
assert_eq "TP-SRM-32 already-current self-update exit" 0 "$ec"
assert_contains "TP-SRM-32 already-current says latest" "$out" "Already running the latest version"
assert_contains "TP-SRM-32 already-current replaced the guard" "$out" "Replaced ${CLEAN_SWAP}/safe-rm"
assert_eq "TP-SRM-32 already-current did not move origin-rm" "$origin_swapped" "$(stat -c '%d:%i' "$CLEAN_SWAP/origin-rm" 2>/dev/null || true)"
if grep -q 'place-setup-marker' "$CLEAN_SWAP/safe-rm"; then
    t_pass "TP-SRM-32 guard is the placed file, not the running checkout"
else
    t_fail "TP-SRM-32 guard missed the placed-file marker"
fi
host_rm_same "TP-SRM-32 already-current left /usr/bin/rm"

CLEAN_CHAN=$(mktemp -d /tmp/safe-rm-place.XXXXXX) || exit 2
sed -e 's/^VERSION="[^"]*"/VERSION="9.9.9"/' \
    -e 's/: "${VERSION:=[^"]*}"/: "${VERSION:=9.9.9}"/' \
    "$SAFE_RM" > "$CLEAN_CHAN/safe-rm"
chmod 0755 "$CLEAN_CHAN/safe-rm"
sha256sum "$CLEAN_CHAN/safe-rm" | awk '{print $1}' > "$CLEAN_CHAN/safe-rm.sha256"
out=$(HOME="$CLEAN_HOME" USER_BIN="$USER_BIN" GLOBAL_BIN="$GLOBAL_BIN" \
    SCRIPT_URL="file://${CLEAN_CHAN}/safe-rm" \
    SRM_SWAP_ROOT="$CLEAN_SWAP" \
    sh "$SAFE_RM" self-update 2>&1)
ec=$?
assert_eq "TP-SRM-32 newer self-update exit" 0 "$ec"
assert_contains "TP-SRM-32 newer self-update replaced the guard" "$out" "Replaced ${CLEAN_SWAP}/safe-rm"
assert_eq "TP-SRM-32 newer self-update did not move origin-rm" "$origin_swapped" "$(stat -c '%d:%i' "$CLEAN_SWAP/origin-rm" 2>/dev/null || true)"
guard_ver=$(grep '^VERSION="' "$CLEAN_SWAP/safe-rm" | head -n1 | cut -d'"' -f2)
assert_eq "TP-SRM-32 guard is the downloaded file" "9.9.9" "$guard_ver"
placed_ver=$(grep '^VERSION="' "$USER_BIN/safe-rm" | head -n1 | cut -d'"' -f2)
assert_eq "TP-SRM-32 user bin is the downloaded file" "9.9.9" "$placed_ver"
if grep -q '^VERSION="9.9.9"' "$SAFE_RM"; then
    t_fail "TP-SRM-32 checkout VERSION was rewritten"
else
    t_pass "TP-SRM-32 checkout VERSION stayed"
fi
host_rm_same "TP-SRM-32 newer self-update left /usr/bin/rm"

CLEAN_PLAIN=$(mktemp -d /tmp/safe-rm-place.XXXXXX) || exit 2
PLAIN_HOME="${CLEAN_PLAIN}/home"
PLAIN_USER="${PLAIN_HOME}/.local/bin"
PLAIN_GLOBAL="${CLEAN_PLAIN}/global-bin"
mkdir -p "$PLAIN_HOME" "$PLAIN_USER" "$PLAIN_GLOBAL"
out=$(HOME="$PLAIN_HOME" USER_BIN="$PLAIN_USER" GLOBAL_BIN="$PLAIN_GLOBAL" \
    sh "$SAFE_RM" self-install 2>&1)
ec=$?
assert_eq "TP-SRM-32 non-root place exit" 0 "$ec"
assert_not_contains "TP-SRM-32 non-root place is not an admin-login error" "$out" "admin login"
assert_not_contains "TP-SRM-32 non-root place did not move rm" "$out" "Moved "
if [ -f "$PLAIN_USER/safe-rm" ]; then
    t_pass "TP-SRM-32 non-root place wrote the user bin"
else
    t_fail "TP-SRM-32 non-root place missed the user bin"
fi
host_rm_same "TP-SRM-32 non-root place left /usr/bin/rm"

CLEAN_TX=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
# Cleaned with the swap tree helper. Record it beside CLEAN_SWAP after that tree is done.
mkdir -p "$CLEAN_TX/bin"
printf '#!/bin/sh\nexit 0\n' > "$CLEAN_TX/bin/rm"
chmod 0755 "$CLEAN_TX/bin/rm"
tx_before=$(stat -c '%d:%i' "$CLEAN_TX/bin/rm")
TX_HOME="${CLEAN_PLAIN}/tx-home"
TX_USER="${TX_HOME}/.local/bin"
TX_GLOBAL="${CLEAN_PLAIN}/tx-global"
mkdir -p "$TX_HOME" "$TX_USER" "$TX_GLOBAL"
out=$(HOME="$TX_HOME" USER_BIN="$TX_USER" GLOBAL_BIN="$TX_GLOBAL" \
    SRM_TERMUX_PREFIX="$CLEAN_TX" \
    sh "$SAFE_RM" self-install 2>&1)
ec=$?
assert_eq "TP-SRM-32 Termux self-install exit" 0 "$ec"
assert_contains "TP-SRM-32 Termux self-install moved rm" "$out" "Moved ${CLEAN_TX}/bin/rm to ${CLEAN_TX}/bin/origin-rm"
assert_contains "TP-SRM-32 Termux self-install pointed rm" "$out" "Pointed ${CLEAN_TX}/bin/rm at ${CLEAN_TX}/bin/safe-rm"
assert_not_contains "TP-SRM-32 Termux self-install is not an admin-login error" "$out" "admin login"
assert_eq "TP-SRM-32 Termux origin-rm is the original file" "$tx_before" "$(stat -c '%d:%i' "$CLEAN_TX/bin/origin-rm" 2>/dev/null || true)"
if cmp -s "$TX_USER/safe-rm" "$CLEAN_TX/bin/safe-rm"; then
    t_pass "TP-SRM-32 Termux guard is the placed file"
else
    t_fail "TP-SRM-32 Termux guard is not the placed file"
fi
host_rm_same "TP-SRM-32 Termux self-install left /usr/bin/rm"
rm_tree "$CLEAN_TX"

printf '\n== summary ==\n'
printf 'PASS=%s FAIL=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf 'RESULT: FAILED\n' >&2
    exit 1
fi
printf 'RESULT: OK\n'
exit 0
