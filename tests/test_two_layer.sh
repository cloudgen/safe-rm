#!/bin/sh
# TP-SRM-33 profile-ensure and path-ensure. TP-SRM-34 measure 2 delegation.
# HOME stays under /tmp. Nothing in a fixture is executed. No real sudo.
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

CLEAN_A=
CLEAN_B=
CLEAN_L=
CLEAN_D=
CLEAN_BB=
cleanup() {
    rm_tree "${CLEAN_A}"
    rm_tree "${CLEAN_B}"
    rm_tree "${CLEAN_L}"
    rm_tree "${CLEAN_D}"
    rm_tree "${CLEAN_BB}"
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

host_rm_same() {
    _now=$(stat -c '%d:%i' /usr/bin/rm 2>/dev/null || true)
    assert_eq "$1" "$HOST_RM_BEFORE" "$_now"
}

count_line() {
    _file=$1
    _line=$2
    if [ ! -f "${_file}" ]; then
        printf '0\n'
        return 0
    fi
    grep -Fx -- "${_line}" "${_file}" 2>/dev/null | wc -l | awk '{ print $1 }'
}

printf 'safe-rm two-layer setup\n'

if grep -q 'util_sudo()' "${SAFE_RM}"; then
    t_fail "TP-SRM-34 ship unit must not define util_sudo"
else
    t_pass "TP-SRM-34 no util_sudo"
fi
if grep -E '^[[:space:]]*sudo[[:space:]]' "${SAFE_RM}" >/dev/null 2>&1; then
    t_fail "TP-SRM-34 sudo is not a bare command"
else
    t_pass "TP-SRM-34 sudo is only the measure-2 default"
fi
if grep -q 'SRM_SUDO:-sudo' "${SAFE_RM}"; then
    t_pass "TP-SRM-34 measure 2 names sudo"
else
    t_fail "TP-SRM-34 missing the sudo default"
fi

# TP-SRM-33. Darwin skips measure 2, so the stand-in is not called.
CLEAN_A=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
LOG_A="${CLEAN_A}/sudo.log"
: > "${LOG_A}"
cat > "${CLEAN_A}/sudo-stand-in" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$SRM_SUDO_LOG"
exit 1
EOF
chmod 0755 "${CLEAN_A}/sudo-stand-in"
HOME_A="${CLEAN_A}/home"
mkdir -p "${HOME_A}"
out=$(HOME="${HOME_A}" SRM_UNAME=Darwin SRM_SUDO="${CLEAN_A}/sudo-stand-in" SRM_SUDO_LOG="${LOG_A}" \
    sh "${SAFE_RM}" setup 2>"${CLEAN_A}/err")
ec=$?
assert_eq "TP-SRM-33 setup exit" 0 "$ec"
if [ -s "${LOG_A}" ]; then
    t_fail "TP-SRM-33 sudo was called"
else
    t_pass "TP-SRM-33 sudo was not called"
fi
prof="${HOME_A}/.profile"
brc="${HOME_A}/.bashrc"
assert_contains "TP-SRM-33 profile sources bashrc" "$(cat "${prof}" 2>/dev/null || true)" '. "${HOME}/.bashrc"'
if grep -q 'export PATH=' "${prof}" 2>/dev/null; then
    t_fail "TP-SRM-33 profile contains a PATH line"
else
    t_pass "TP-SRM-33 profile has no PATH line"
fi
mode=$(stat -c '%a' "${prof}" 2>/dev/null || true)
assert_eq "TP-SRM-33 profile mode" "644" "${mode}"
line='export PATH="${HOME}/.local/bin:$PATH"'
assert_eq "TP-SRM-33 bashrc has the line once" "1" "$(count_line "${brc}" "${line}")"
if [ -L "${HOME_A}/.local/bin/rm" ] && [ "$(readlink "${HOME_A}/.local/bin/rm")" = "safe-rm" ]; then
    t_pass "TP-SRM-33 home rm points at safe-rm"
else
    t_fail "TP-SRM-33 home rm is not the safe-rm link"
fi
guard_mode=$(stat -c '%a' "${HOME_A}/.local/bin/safe-rm" 2>/dev/null || true)
assert_eq "TP-SRM-33 home safe-rm mode" "700" "${guard_mode}"
assert_contains "TP-SRM-33 darwin origin execs /bin/rm" "$(cat "${HOME_A}/.local/bin/origin-rm" 2>/dev/null || true)" 'exec /bin/rm'
host_rm_same "TP-SRM-33 left /usr/bin/rm"

out=$(HOME="${HOME_A}" SRM_UNAME=Darwin SRM_SUDO="${CLEAN_A}/sudo-stand-in" SRM_SUDO_LOG="${LOG_A}" \
    sh "${SAFE_RM}" setup 2>"${CLEAN_A}/err")
ec=$?
assert_eq "TP-SRM-33 second setup exit" 0 "$ec"
assert_eq "TP-SRM-33 second setup still one PATH line" "1" "$(count_line "${brc}" "${line}")"
begin_n=$(grep -c 'BEGIN safe-rm profile source-bashrc' "${prof}" 2>/dev/null || true)
assert_eq "TP-SRM-33 second setup still one profile sample" "1" "${begin_n}"

CLEAN_B=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
HOME_B="${CLEAN_B}/home"
mkdir -p "${HOME_B}"
printf 'KEEP-ME marker\n' > "${HOME_B}/.profile"
out=$(HOME="${HOME_B}" SRM_UNAME=Darwin SRM_SUDO=false \
    sh "${SAFE_RM}" setup 2>"${CLEAN_B}/err")
ec=$?
assert_eq "TP-SRM-33 existing profile exit" 0 "$ec"
assert_eq "TP-SRM-33 existing profile body" "KEEP-ME marker" "$(cat "${HOME_B}/.profile")"
if grep -q 'BEGIN safe-rm profile source-bashrc' "${HOME_B}/.profile"; then
    t_fail "TP-SRM-33 existing profile was rewritten"
else
    t_pass "TP-SRM-33 existing profile was kept"
fi
host_rm_same "TP-SRM-33 existing profile left /usr/bin/rm"

# TP-SRM-34 Linux delegates measure 2. The stand-in re-execs the child.
CLEAN_L=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
LOG_L="${CLEAN_L}/sudo.log"
: > "${LOG_L}"
cat > "${CLEAN_L}/sudo-stand-in" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$SRM_SUDO_LOG"
exec "$@"
EOF
chmod 0755 "${CLEAN_L}/sudo-stand-in"
printf '#!/bin/sh\nexit 0\n' > "${CLEAN_L}/rm"
chmod 0755 "${CLEAN_L}/rm"
origin_before=$(stat -c '%d:%i' "${CLEAN_L}/rm")
HOME_L="${CLEAN_L}/home"
mkdir -p "${HOME_L}"
out=$(HOME="${HOME_L}" SRM_UNAME=Linux SRM_DELEGATE_MEASURE2=1 \
    SRM_SWAP_ROOT="${CLEAN_L}" \
    SRM_SUDO="${CLEAN_L}/sudo-stand-in" SRM_SUDO_LOG="${LOG_L}" \
    sh "${SAFE_RM}" setup 2>"${CLEAN_L}/err")
ec=$?
assert_eq "TP-SRM-34 linux setup exit" 0 "$ec"
if [ -s "${LOG_L}" ]; then
    t_pass "TP-SRM-34 linux called the stand-in"
else
    t_fail "TP-SRM-34 linux did not call the stand-in"
fi
assert_contains "TP-SRM-34 linux stand-in is measure 2" "$(cat "${LOG_L}")" "SRM_SETUP_MEASURE=2"
assert_eq "TP-SRM-34 linux origin inode" "${origin_before}" "$(stat -c '%d:%i' "${CLEAN_L}/origin-rm" 2>/dev/null || true)"
assert_contains "TP-SRM-34 linux rm target" "$(readlink "${CLEAN_L}/rm" 2>/dev/null || true)" "${CLEAN_L}/safe-rm"
if [ -f "${HOME_L}/.local/bin/safe-rm" ]; then
    t_pass "TP-SRM-34 linux measure 1 wrote the home guard"
else
    t_fail "TP-SRM-34 linux measure 1 missed the home guard"
fi
host_rm_same "TP-SRM-34 linux left /usr/bin/rm"

# BusyBox symlink is not renamed. origin-rm runs busybox rm.
CLEAN_BB=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
LOG_BB="${CLEAN_BB}/sudo.log"
: > "${LOG_BB}"
cp "${CLEAN_L}/sudo-stand-in" "${CLEAN_BB}/sudo-stand-in"
chmod 0755 "${CLEAN_BB}/sudo-stand-in"
printf '#!/bin/sh\nexit 0\n' > "${CLEAN_BB}/busybox"
chmod 0755 "${CLEAN_BB}/busybox"
ln -s busybox "${CLEAN_BB}/rm"
bb_before=$(stat -c '%d:%i' "${CLEAN_BB}/busybox")
HOME_BB="${CLEAN_BB}/home"
mkdir -p "${HOME_BB}"
out=$(HOME="${HOME_BB}" SRM_UNAME=Linux SRM_DELEGATE_MEASURE2=1 \
    SRM_SWAP_ROOT="${CLEAN_BB}" \
    SRM_SUDO="${CLEAN_BB}/sudo-stand-in" SRM_SUDO_LOG="${LOG_BB}" \
    sh "${SAFE_RM}" setup 2>"${CLEAN_BB}/err")
ec=$?
assert_eq "TP-SRM-34 busybox exit" 0 "$ec"
assert_eq "TP-SRM-34 busybox inode" "${bb_before}" "$(stat -c '%d:%i' "${CLEAN_BB}/busybox" 2>/dev/null || true)"
assert_contains "TP-SRM-34 busybox origin marker" "$(cat "${CLEAN_BB}/origin-rm" 2>/dev/null || true)" "safe-rm busybox-origin"
assert_contains "TP-SRM-34 busybox rm target" "$(readlink "${CLEAN_BB}/rm" 2>/dev/null || true)" "${CLEAN_BB}/safe-rm"
host_rm_same "TP-SRM-34 busybox left /usr/bin/rm"

# Darwin does not call the stand-in. The fixture rm stays.
CLEAN_D=$(mktemp -d /tmp/safe-rm-swap.XXXXXX) || exit 2
LOG_D="${CLEAN_D}/sudo.log"
: > "${LOG_D}"
cp "${CLEAN_L}/sudo-stand-in" "${CLEAN_D}/sudo-stand-in"
chmod 0755 "${CLEAN_D}/sudo-stand-in"
printf '#!/bin/sh\nexit 0\n' > "${CLEAN_D}/rm"
chmod 0755 "${CLEAN_D}/rm"
d_before=$(stat -c '%d:%i' "${CLEAN_D}/rm")
HOME_D="${CLEAN_D}/home"
mkdir -p "${HOME_D}"
out=$(HOME="${HOME_D}" SRM_UNAME=Darwin SRM_DELEGATE_MEASURE2=1 \
    SRM_SWAP_ROOT="${CLEAN_D}" \
    SRM_SUDO="${CLEAN_D}/sudo-stand-in" SRM_SUDO_LOG="${LOG_D}" \
    sh "${SAFE_RM}" setup 2>"${CLEAN_D}/err")
ec=$?
assert_eq "TP-SRM-34 darwin setup exit" 0 "$ec"
if [ -s "${LOG_D}" ]; then
    t_fail "TP-SRM-34 darwin called the stand-in"
else
    t_pass "TP-SRM-34 darwin did not call the stand-in"
fi
assert_eq "TP-SRM-34 darwin fixture rm stayed" "${d_before}" "$(stat -c '%d:%i' "${CLEAN_D}/rm" 2>/dev/null || true)"
if [ -L "${CLEAN_D}/rm" ]; then
    t_fail "TP-SRM-34 darwin fixture rm was replaced"
else
    t_pass "TP-SRM-34 darwin fixture rm is still the original file"
fi
host_rm_same "TP-SRM-34 darwin left /usr/bin/rm"

printf '\n== summary ==\n'
printf 'PASS=%s FAIL=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf 'RESULT: FAILED\n' >&2
    exit 1
fi
printf 'RESULT: OK\n'
exit 0
