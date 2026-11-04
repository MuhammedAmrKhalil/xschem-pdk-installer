#!/usr/bin/env bash
# ==============================================================================
# Xschem Dedicated PDK Launchers & Shell Environment Generator
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/os_detect.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/config.env"

find_eda_env() {
    # 1. Active conda environment
    if [ "${CONDA_DEFAULT_ENV:-}" = "${CONDA_ENV_NAME}" ] && [ -d "${CONDA_PREFIX:-}" ]; then
        echo "$CONDA_PREFIX"
        return 0
    fi

    # 2. Query conda command
    local conda_cmd=""
    if command -v conda >/dev/null 2>&1; then
        conda_cmd="conda"
    elif [ -x "${HOME}/miniforge3/bin/conda" ]; then
        conda_cmd="${HOME}/miniforge3/bin/conda"
    elif [ -x "${HOME}/miniconda3/bin/conda" ]; then
        conda_cmd="${HOME}/miniconda3/bin/conda"
    elif [ -x "/usr/share/miniconda/bin/conda" ]; then
        conda_cmd="/usr/share/miniconda/bin/conda"
    elif [ -x "/opt/conda/bin/conda" ]; then
        conda_cmd="/opt/conda/bin/conda"
    fi

    if [ -n "$conda_cmd" ]; then
        local p
        p="$("$conda_cmd" env list 2>/dev/null | grep -E "^${CONDA_ENV_NAME}[[:space:]]" | awk '{print $NF}' || true)"
        if [ -n "$p" ] && [ -d "$p" ]; then
            echo "$p"
            return 0
        fi
    fi

    # 3. Known directory locations
    for d in \
        "${HOME}/miniforge3/envs/${CONDA_ENV_NAME}" \
        "${HOME}/miniconda3/envs/${CONDA_ENV_NAME}" \
        "/usr/share/miniconda/envs/${CONDA_ENV_NAME}" \
        "/opt/conda/envs/${CONDA_ENV_NAME}"; do
        if [ -d "$d" ]; then
            echo "$d"
            return 0
        fi
    done

    echo ""
}

setup_launchers() {
    log_step "Generating Dedicated Xschem Launchers & Binaries"

    mkdir -p "$INSTALL_BIN_DIR" "${HOME}/bin"

    ENV_PREFIX="$(find_eda_env)"
    log_info "Resolved EDA environment prefix: ${ENV_PREFIX:-None (using system paths)}"

    # Locate xschem binary
    XSCHEM_BIN=""
    if [ -n "$ENV_PREFIX" ] && [ -x "${ENV_PREFIX}/bin/xschem" ]; then
        XSCHEM_BIN="${ENV_PREFIX}/bin/xschem"
    elif command -v xschem >/dev/null 2>&1 && [ "$(command -v xschem)" != "${INSTALL_BIN_DIR}/xschem" ]; then
        XSCHEM_BIN="$(command -v xschem)"
    elif [ -x "/usr/bin/xschem" ]; then
        XSCHEM_BIN="/usr/bin/xschem"
    elif [ -x "/usr/local/bin/xschem" ]; then
        XSCHEM_BIN="/usr/local/bin/xschem"
    fi

    # Fallback placeholder if xschem is not yet installed
    if [ -z "$XSCHEM_BIN" ]; then
        XSCHEM_BIN="${ENV_PREFIX:+${ENV_PREFIX}/bin/}xschem"
    fi

    # Environment export preamble for wrappers
    ENV_EXPORTS=""
    if [ -n "$ENV_PREFIX" ]; then
        ENV_EXPORTS="export PATH=\"${ENV_PREFIX}/bin:\$PATH\"
export LD_LIBRARY_PATH=\"${ENV_PREFIX}/lib:${INSTALL_LIB_DIR}:\${LD_LIBRARY_PATH:-}\""
    else
        ENV_EXPORTS="export LD_LIBRARY_PATH=\"${INSTALL_LIB_DIR}:\${LD_LIBRARY_PATH:-}\""
    fi

    # 1. Launcher: xschem_ihp
    cat << EOF > "${INSTALL_BIN_DIR}/xschem_ihp"
#!/usr/bin/env bash
# Dedicated Xschem Launcher for IHP SG13G2 (0.13um BiCMOS)
${ENV_EXPORTS}
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="ihp-sg13g2"
RCFILE="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/xschemrc"
DEFAULT_SCH="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/start_page.sch"

if [ \$# -eq 0 ] && [ -f "\$DEFAULT_SCH" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$DEFAULT_SCH"
elif [ -f "\$RCFILE" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$@"
else
    exec "${XSCHEM_BIN}" "\$@"
fi
EOF
    chmod +x "${INSTALL_BIN_DIR}/xschem_ihp"
    ln -sf "${INSTALL_BIN_DIR}/xschem_ihp" "${INSTALL_BIN_DIR}/xschem_sg13g2"
    ln -sf "${INSTALL_BIN_DIR}/xschem_ihp" "${HOME}/bin/xschem_ihp"
    ln -sf "${INSTALL_BIN_DIR}/xschem_ihp" "${HOME}/bin/xschem_sg13g2"

    # 2. Launcher: xschem_sky
    cat << EOF > "${INSTALL_BIN_DIR}/xschem_sky"
#!/usr/bin/env bash
# Dedicated Xschem Launcher for SkyWater 130nm (sky130A)
${ENV_EXPORTS}
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="sky130A"
RCFILE="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/xschemrc"
DEFAULT_SCH="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/sky130_tests/top.sch"

if [ \$# -eq 0 ] && [ -f "\$DEFAULT_SCH" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$DEFAULT_SCH"
elif [ -f "\$RCFILE" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$@"
else
    exec "${XSCHEM_BIN}" "\$@"
fi
EOF
    chmod +x "${INSTALL_BIN_DIR}/xschem_sky"
    ln -sf "${INSTALL_BIN_DIR}/xschem_sky" "${INSTALL_BIN_DIR}/xschem_sky130"
    ln -sf "${INSTALL_BIN_DIR}/xschem_sky" "${HOME}/bin/xschem_sky"
    ln -sf "${INSTALL_BIN_DIR}/xschem_sky" "${HOME}/bin/xschem_sky130"

    # 3. Launcher: xschem_gf
    cat << EOF > "${INSTALL_BIN_DIR}/xschem_gf"
#!/usr/bin/env bash
# Dedicated Xschem Launcher for GlobalFoundries 180nm MCU (gf180mcuD)
${ENV_EXPORTS}
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="gf180mcuD"
RCFILE="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/xschemrc"
DEFAULT_SCH="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/tests/0_top.sch"

if [ \$# -eq 0 ] && [ -f "\$DEFAULT_SCH" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$DEFAULT_SCH"
elif [ -f "\$RCFILE" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$@"
else
    exec "${XSCHEM_BIN}" "\$@"
fi
EOF
    chmod +x "${INSTALL_BIN_DIR}/xschem_gf"
    ln -sf "${INSTALL_BIN_DIR}/xschem_gf" "${INSTALL_BIN_DIR}/xschem_gf180"
    ln -sf "${INSTALL_BIN_DIR}/xschem_gf" "${INSTALL_BIN_DIR}/xschem_gf180mcu"
    ln -sf "${INSTALL_BIN_DIR}/xschem_gf" "${HOME}/bin/xschem_gf"
    ln -sf "${INSTALL_BIN_DIR}/xschem_gf" "${HOME}/bin/xschem_gf180"

    # 4. Standard Launcher: xschem
    cat << EOF > "${INSTALL_BIN_DIR}/xschem"
#!/usr/bin/env bash
# Standard Xschem Launcher with automatic fallback
${ENV_EXPORTS}
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="\${PDK:-ihp-sg13g2}"
exec "${XSCHEM_BIN}" "\$@"
EOF
    chmod +x "${INSTALL_BIN_DIR}/xschem"
    ln -sf "${INSTALL_BIN_DIR}/xschem" "${HOME}/bin/xschem"

    # 5. GTKWave wrapper
    GTKWAVE_BIN=""
    if [ -n "$ENV_PREFIX" ] && [ -x "${ENV_PREFIX}/bin/gtkwave" ]; then
        GTKWAVE_BIN="${ENV_PREFIX}/bin/gtkwave"
    elif command -v gtkwave >/dev/null 2>&1 && [ "$(command -v gtkwave)" != "${INSTALL_BIN_DIR}/gtkwave" ]; then
        GTKWAVE_BIN="$(command -v gtkwave)"
    fi
    if [ -n "$GTKWAVE_BIN" ]; then
        cat << EOF > "${INSTALL_BIN_DIR}/gtkwave"
#!/usr/bin/env bash
${ENV_EXPORTS}
exec "${GTKWAVE_BIN}" "\$@"
EOF
        chmod +x "${INSTALL_BIN_DIR}/gtkwave"
        ln -sf "${INSTALL_BIN_DIR}/gtkwave" "${HOME}/bin/gtkwave"
    fi

    # 6. Ngspice wrapper
    NGSPICE_BIN=""
    if [ -n "$ENV_PREFIX" ] && [ -x "${ENV_PREFIX}/bin/ngspice" ]; then
        NGSPICE_BIN="${ENV_PREFIX}/bin/ngspice"
    elif command -v ngspice >/dev/null 2>&1 && [ "$(command -v ngspice)" != "${INSTALL_BIN_DIR}/ngspice" ]; then
        NGSPICE_BIN="$(command -v ngspice)"
    fi
    if [ -n "$NGSPICE_BIN" ]; then
        cat << EOF > "${INSTALL_BIN_DIR}/ngspice"
#!/usr/bin/env bash
${ENV_EXPORTS}
exec "${NGSPICE_BIN}" "\$@"
EOF
        chmod +x "${INSTALL_BIN_DIR}/ngspice"
        ln -sf "${INSTALL_BIN_DIR}/ngspice" "${HOME}/bin/ngspice"
    fi

    # 7. Icarus Verilog wrappers (iverilog & vvp)
    for iv_tool in iverilog vvp; do
        IV_BIN=""
        if [ -n "$ENV_PREFIX" ] && [ -x "${ENV_PREFIX}/bin/${iv_tool}" ]; then
            IV_BIN="${ENV_PREFIX}/bin/${iv_tool}"
        elif command -v "${iv_tool}" >/dev/null 2>&1 && [ "$(command -v "${iv_tool}")" != "${INSTALL_BIN_DIR}/${iv_tool}" ]; then
            IV_BIN="$(command -v "${iv_tool}")"
        fi
        if [ -n "$IV_BIN" ] && [ ! -x "${INSTALL_BIN_DIR}/${iv_tool}" ]; then
            cat << EOF > "${INSTALL_BIN_DIR}/${iv_tool}"
#!/usr/bin/env bash
${ENV_EXPORTS}
exec "${IV_BIN}" "\$@"
EOF
            chmod +x "${INSTALL_BIN_DIR}/${iv_tool}"
            ln -sf "${INSTALL_BIN_DIR}/${iv_tool}" "${HOME}/bin/${iv_tool}"
        fi
    done

    log_ok "Launchers generated in ${INSTALL_BIN_DIR} and ${HOME}/bin"
}

setup_shell_rc() {
    log_step "Updating Shell Configuration Files"

    EXPORT_BLOCK='
# >>> Xschem & EDA Environment Initialization >>>
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PDK_ROOT="${PDK_ROOT:-'"$PDK_ROOT"'}"
# <<< Xschem & EDA Environment Initialization <<<
'

    for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        if [ -f "$rc" ]; then
            if ! grep -q "Xschem & EDA Environment Initialization" "$rc"; then
                echo "$EXPORT_BLOCK" >> "$rc"
                log_ok "Updated ${rc}"
            else
                log_info "${rc} already contains EDA environment settings."
            fi
        fi
    done
}

main() {
    setup_launchers
    setup_shell_rc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
