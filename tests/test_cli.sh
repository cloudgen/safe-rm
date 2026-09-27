# =============================================================================
# tests/test_cli.sh — Type 0 CLI surface (no network install required)
# =============================================================================
# Covers: syntax, version, help, about, unknown command, quiet/json modes,
# help must not list CHECKSUM, self-uninstall --json fail-closed (INC-20260713-002
# contract shape when a binary is present under isolated USER_BIN),
# TP-SI-01..08 self-install copy / dest 0700 / empty argv / pipe download /
# no chmod +x / isolated GLOBAL_BIN 0755 (PP-A-28).
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_cli() {
    t_header "CLI surface"

    require_cmd sh
    require_cmd sha256sum
    require_cmd grep

    # --- syntax ---
    sh -n "${SCRIPT}"
    _syn=$?
    assert_eq "sh -n selfmanaged (syntax)" 0 "$_syn"

    # --- companion digest matches ship unit ---
    if [ -f "${REPO_ROOT}/src/selfmanaged.sha256" ]; then
        _expected=$(tr -d ' \n\r\t' < "${REPO_ROOT}/src/selfmanaged.sha256")
        _actual=$(sha256sum "${SCRIPT}" | awk '{print $1}')
        assert_eq "src/selfmanaged.sha256 matches src/selfmanaged" "$_expected" "$_actual"
    else
        t_fail "selfmanaged.sha256 missing beside src/selfmanaged"
    fi

    # --- version (human) ---
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "version exit 0" 0 "$_ec"
    assert_contains "version human mentions version" "$_out" "${PRODUCT_VERSION}"
    assert_contains "version human mentions app" "$_out" "selfmanaged"

    # --- version (json) ---
    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "version --json exit 0" 0 "$_ec"
    assert_contains "version --json type" "$_out" '"type":"version"'
    assert_contains "version --json app" "$_out" '"app":"selfmanaged"'
    assert_contains "version --json version field" "$_out" "\"version\":\"${PRODUCT_VERSION}\""
    # app_version is the live dispatcher target (M1); no dual inline path
    assert_contains "version human via app_version" "$(sh "${SCRIPT}" version 2>/dev/null)" "${PRODUCT_VERSION}"

    # --- help (human): commands present, CHECKSUM absent ---
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "help exit 0" 0 "$_ec"
    assert_contains "help lists self-install" "$_out" "self-install"
    assert_contains "help lists install" "$_out" "install"
    assert_contains "help lists version-check" "$_out" "version-check"
    assert_contains "help lists self-update" "$_out" "self-update"
    assert_contains "help lists self-uninstall" "$_out" "self-uninstall"
    assert_contains "help lists about" "$_out" "about"
    assert_contains "help lists --json" "$_out" "--json"
    assert_contains "help lists --force" "$_out" "--force"
    assert_contains "help lists REPO_USER" "$_out" "REPO_USER"
    assert_contains "help lists REPO_NAME" "$_out" "REPO_NAME"
    assert_contains "help lists SCRIPT_RELPATH" "$_out" "SCRIPT_RELPATH"
    assert_contains "help lists SCRIPT_URL" "$_out" "SCRIPT_URL"
    assert_not_contains "help must not list CHECKSUM" "$_out" "CHECKSUM"

    # --- help (json): short object, not full prose ---
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    _ec=$?
    assert_eq "help --json exit 0" 0 "$_ec"
    assert_contains "help --json type success" "$_out" '"type":"success"'
    assert_contains "help --json command help" "$_out" '"command":"help"'

    # --- about (json): no CHECKSUM field; storage resolve fields ---
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "about --json exit 0" 0 "$_ec"
    assert_contains "about --json type" "$_out" '"type":"about"'
    assert_contains "about --json app" "$_out" '"app":"selfmanaged"'
    assert_not_contains "about --json must not include CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "about --json effective_storage" "$_out" '"effective_storage"'
    assert_contains "about --json storage_dir" "$_out" '"storage_dir"'
    assert_contains "about --json storage includes app name" "$_out" "${APP_NAME:-selfmanaged}"

    # --- storage resolve isolation (EFFECTIVE_STORAGE_DIR via util_resolve_storage) ---
    ci_isolated_env 2>/dev/null || true
    if [ -n "${CI_HOME:-}" ]; then
        _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN:-${CI_HOME}/.local/bin}" GLOBAL_BIN="${CI_GLOBAL_BIN:-${CI_HOME}/global-bin}" \
            sh "${SCRIPT}" --json about 2>/dev/null)
        assert_contains "isolated about effective_storage has app" "$_out" "${APP_NAME:-selfmanaged}"
        case "$_out" in
            *'"effective_storage":"'*"${APP_NAME:-selfmanaged}"*) t_pass "effective_storage path contains ${APP_NAME:-selfmanaged}" ;;
            *) t_fail "effective_storage missing app isolation in: $_out" ;;
        esac
        assert_contains "storage_dir field present under isolation" "$_out" '"storage_dir"'
        _custom="${CI_HOME}/custom-storage-root"
        _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" STORAGE_DIR="${_custom}" \
            sh "${SCRIPT}" --json about 2>/dev/null)
        # STORAGE_DIR env appears on storage_dir config field (tier-3 / override field)
        assert_contains "storage_dir honors STORAGE_DIR env" "$_out" "custom-storage-root"
        _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        if [ -n "$_eff" ] && [ -d "$_eff" ]; then
            t_pass "effective_storage directory exists after resolve"
        else
            t_fail "effective_storage missing or not a directory: '${_eff:-empty}'"
        fi
        _who=$(id -un 2>/dev/null || echo "unknown")
        case "$_out" in
            *'"effective_storage":"'*"${_who}"*|*'"effective_storage":"'*"unknown"*) \
                t_pass "effective_storage includes user segment" ;;
            *) t_fail "effective_storage missing user segment for '${_who}': $_out" ;;
        esac
        ci_cleanup_env 2>/dev/null || true
    else
        # Fallback without full CI isolation helpers
        _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
        _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        if [ -n "$_eff" ] && [ -d "$_eff" ]; then
            t_pass "effective_storage directory exists after resolve"
        else
            t_fail "effective_storage missing or not a directory: '${_eff:-empty}'"
        fi
    fi

    # --- unknown command ---
    _err=$(sh "${SCRIPT}" no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "unknown command exit 1" 1 "$_ec"
    assert_contains "unknown command error text" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" --json no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "unknown command --json exit 1" 1 "$_ec"
    assert_contains "unknown command --json type error" "$_err" '"type":"out_error"'

    # --- quiet: version should not print info banners ---
    # Contract: --quiet suppresses non-error chatter; version uses out_info → suppressed.
    _out=$(sh "${SCRIPT}" --quiet version 2>/dev/null)
    _ec=$?
    assert_eq "version --quiet exit 0" 0 "$_ec"
    # out_info is suppressed under quiet → empty or near-empty stdout is correct
    if [ -z "$_out" ]; then
        t_pass "version --quiet suppresses human info"
    else
        _trim=$(printf '%s' "$_out" | tr -d ' \t\n\r')
        if [ -z "$_trim" ]; then
            t_pass "version --quiet suppresses human info"
        else
            t_fail "version --quiet expected empty stdout, got '$(_trunc "$_out")'"
        fi
    fi

    # --- HOME unset under set -u (INC-20260713-001) ---
    # Must not abort with "HOME: parameter not set"; defaults HOME then USER_BIN.
    _out=$(env -u HOME sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "env -u HOME version exit 0" 0 "$_ec"
    assert_contains "env -u HOME version still reports version" "$_out" "${PRODUCT_VERSION}"

    # --- zero-arg auto-install propagates failure (interpreter $0 / pipe; not exit 0 on download fail) ---
    # Script $0 copies offline; a dead SCRIPT_URL must be proven with interpreter $0.
    ci_isolated_env
    _errf="${CI_HOME}/zero-arg-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SCRIPT_URL="http://127.0.0.1:1/selfmanaged-unreachable" \
        sh -s < "${SCRIPT}" 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    if [ "$_ec" -ne 0 ]; then
        t_pass "zero-arg failed install exits non-zero"
    else
        t_fail "zero-arg failed install expected non-zero exit, got 0 (stdout='$(_trunc "$_out")' err='$(_trunc "$_err")')"
    fi
    assert_file_missing "zero-arg failed install left no binary" "${CI_USER_BIN}/selfmanaged"
    ci_cleanup_env

    # --- TP-SI-01 script $0 copies without download (dead SCRIPT_URL) ---
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME:-selfmanaged}" sh "${SCRIPT}" self-install 2>&1)
    _ec=$?
    assert_eq "TP-SI-01 self-install copy exit 0" 0 "$_ec"
    assert_file_exists "TP-SI-01 binary at USER_BIN" "${CI_USER_BIN}/${APP_NAME:-selfmanaged}"
    assert_contains "TP-SI-01 copy from local script" "$_out" "Installing from local script"
    assert_not_contains "TP-SI-01 no companion download" "$_out" "Companion link:"

    # --- TP-SI-02 local dest mode 0700 ---
    _mode=$(stat -c '%a' "${CI_USER_BIN}/${APP_NAME:-selfmanaged}" 2>/dev/null || stat -f '%OLp' "${CI_USER_BIN}/${APP_NAME:-selfmanaged}" 2>/dev/null || echo "")
    case "${_mode}" in
        700|0700) assert_eq "TP-SI-02 local dest mode 0700" "0700" "0700" ;;
        *) assert_eq "TP-SI-02 local dest mode 0700" "0700" "${_mode}" ;;
    esac

    # --- TP-SI-05 already-installed no-op ---
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" sh "${SCRIPT}" self-install 2>&1)
    _ec=$?
    assert_eq "TP-SI-05 second self-install exit 0" 0 "$_ec"
    assert_contains "TP-SI-05 already installed" "$_out" "already installed"
    ci_cleanup_env

    # --- TP-SI-03 NI empty argv is self-install (copy), not help ---
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME:-selfmanaged}" sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-SI-03 empty argv copy exit 0" 0 "$_ec"
    assert_file_exists "TP-SI-03 empty argv placed binary" "${CI_USER_BIN}/${APP_NAME:-selfmanaged}"
    assert_contains "TP-SI-03 empty argv self-install banner" "$_out" "Starting self-install"
    assert_not_contains "TP-SI-03 empty argv is not help" "$_out" "Global Options"
    ci_cleanup_env

    # --- TP-SI-04 interpreter $0 (stdin pipe) uses channel download ---
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="file://${SCRIPT}" sh -s < "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-SI-04 pipe self-install exit 0" 0 "$_ec"
    assert_file_exists "TP-SI-04 pipe placed binary" "${CI_USER_BIN}/${APP_NAME:-selfmanaged}"
    assert_contains "TP-SI-04 pipe uses companion download" "$_out" "Companion link:"
    ci_cleanup_env

    # --- TP-SI-06 help lists self-install ---
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    assert_contains "TP-SI-06 help lists self-install" "$_out" "self-install"

    # --- TP-SI-07 no chmod +x on place path (0711 trap; PP-A-28) ---
    # Live command only. Comments that say MUST NOT chmod +x are allowed.
    if grep -nE '^[[:space:]]*chmod[[:space:]]+\+x' "${SCRIPT}" >/dev/null 2>&1; then
        t_fail "TP-SI-07 ship unit must not chmod +x (mints 0711; other users cannot open shebang)"
    else
        t_pass "TP-SI-07 no chmod +x command"
    fi
    if grep -q 'inst_cli_dest_mode()' "${SCRIPT}"; then
        t_pass "TP-SI-07 inst_cli_dest_mode present"
    else
        t_fail "TP-SI-07 inst_cli_dest_mode missing"
    fi
    assert_contains "TP-SI-07 dest helper names 0755" "$(sed -n '/^inst_cli_dest_mode()/,/^}/p' "${SCRIPT}")" "0755"
    assert_contains "TP-SI-07 dest helper names 0700" "$(sed -n '/^inst_cli_dest_mode()/,/^}/p' "${SCRIPT}")" "0700"

    # --- TP-SI-08 isolated GLOBAL_BIN dest 0755 (heals leftover 0711) ---
    # Non-root CI cannot id -u 0; the copy helper is what root passes 0755 into.
    ci_isolated_env
    ci_source_ship_unit
    JSON=0
    : "${APP_NAME:=selfmanaged}"
    INSTALL_PATH="${CI_GLOBAL_BIN}/${APP_NAME}"
    mkdir -p "${CI_GLOBAL_BIN}"
    cp "${SCRIPT}" "${INSTALL_PATH}"
    chmod 0711 "${INSTALL_PATH}" 2>/dev/null || chmod 711 "${INSTALL_PATH}"
    inst_self_install_copy_from_script "${SCRIPT}" "0755"
    _ec=$?
    assert_eq "TP-SI-08 copy 0755 onto GLOBAL_BIN exit 0" 0 "$_ec"
    assert_file_exists "TP-SI-08 global dest exists" "${INSTALL_PATH}"
    _mode=$(stat -c '%a' "${INSTALL_PATH}" 2>/dev/null || stat -f '%OLp' "${INSTALL_PATH}" 2>/dev/null || echo "")
    case "${_mode}" in
        755|0755) assert_eq "TP-SI-08 global dest mode 0755 (not 0711)" "0755" "0755" ;;
        *) assert_eq "TP-SI-08 global dest mode 0755 (not 0711)" "0755" "${_mode}" ;;
    esac
    if [ -r "${INSTALL_PATH}" ] && [ -x "${INSTALL_PATH}" ]; then
        t_pass "TP-SI-08 global dest readable+executable (other-read shebang)"
    else
        t_fail "TP-SI-08 global dest must be readable+executable (0711 fails unprivileged /bin/sh open)"
    fi
    JSON=0
    ci_cleanup_env

    # --- self-uninstall --json without force when binary present (isolated) ---
    # Fail-closed confirm_required (INC-20260713-002 contract).
    ci_isolated_env
    mkdir -p "${CI_USER_BIN}"
    # Place a stub install so uninstall path runs without network
    cp "${SCRIPT}" "${CI_USER_BIN}/selfmanaged"
    chmod +x "${CI_USER_BIN}/selfmanaged"
    _errf="${CI_HOME}/un-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        sh "${SCRIPT}" --json self-uninstall 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    assert_eq "self-uninstall --json without --force exit 1" 1 "$_ec"
    assert_contains "self-uninstall --json confirm_required code" "$_err" '"code":"confirm_required"'
    assert_contains "self-uninstall --json out_error type" "$_err" '"type":"out_error"'
    assert_not_contains "self-uninstall --json must not fake success cancel" "$_out$_err" "cancelled by user"
    assert_file_exists "binary remains without --force" "${CI_USER_BIN}/selfmanaged"
    ci_cleanup_env

    # --- TP-JSON-RAW-01 / TP-CLI-12: out_json @key inserts raw nested JSON ---
    ci_isolated_env
    ci_source_ship_unit
    JSON=1
    _out=$(out_json "success" "" "count" "2" "@items" '["a","b"]')
    _ec=$?
    assert_eq "TP-JSON-RAW-01 out_json @key exit 0" 0 "$_ec"
    assert_contains "TP-JSON-RAW-01 type success" "$_out" '"type":"success"'
    assert_contains "TP-JSON-RAW-01 string count stays quoted" "$_out" '"count":"2"'
    assert_contains "TP-JSON-RAW-01 raw nested array unquoted" "$_out" '"items":["a","b"]'
    assert_not_contains "TP-JSON-RAW-01 must not stringify the array" "$_out" '"items":"[\"a\",\"b\"]"'
    _out=$(out_json "success" "" "@meta" '{"n":1}')
    assert_contains "TP-JSON-RAW-01 raw nested object unquoted" "$_out" '"meta":{"n":1}'
    JSON=0
    _silent=$(out_json "success" "" "@items" '["x"]')
    if [ -z "$_silent" ]; then
        t_pass "TP-JSON-RAW-01 out_json no-ops when JSON=0"
    else
        t_fail "TP-JSON-RAW-01 expected empty when JSON=0, got '$(_trunc "$_silent")'"
    fi
    ci_cleanup_env

    # --- TP-CS-01: bootstrap ship unit has no in-tool sudo wrap ---
    if grep -q 'util_sudo()' "${SCRIPT}"; then
        t_fail "TP-CS-01 ship unit must not define util_sudo"
    else
        t_pass "TP-CS-01 no util_sudo function"
    fi
    if grep -E '^[[:space:]]*sudo[[:space:]]' "${SCRIPT}" >/dev/null 2>&1; then
        t_fail "TP-CS-01 ship unit must not invoke sudo as a command"
    else
        t_pass "TP-CS-01 no command-position sudo"
    fi
}
