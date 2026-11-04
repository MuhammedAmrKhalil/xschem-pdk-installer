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

setup_launchers() {
    log_step "Generating Dedicated Xschem Launchers & Binaries"

    mkdir -p "$INSTALL_BIN_DIR" "${HOME}/bin"

    # Find xschem binary
    XSCHEM_BIN=""
    if [ -x "${HOME}/miniforge3/envs/${CONDA_ENV_NAME}/bin/xschem" ]; then
        XSCHEM_BIN="${HOME}/miniforge3/envs/${CONDA_ENV_NAME}/bin/xschem"
    elif [ -x "${HOME}/miniconda3/envs/${CONDA_ENV_NAME}/bin/xschem" ]; then
        XSCHEM_BIN="${HOME}/miniconda3/envs/${CONDA_ENV_NAME}/bin/xschem"
    elif command -v xschem >/dev/null 2>&1; then
        XSCHEM_BIN="$(command -v xschem)"
    else
        XSCHEM_BIN="${INSTALL_BIN_DIR}/xschem"
    fi

    # 1. Launcher: xschem_ihp
    cat << EOF > "${INSTALL_BIN_DIR}/xschem_ihp"
#!/usr/bin/env bash
# Dedicated Xschem Launcher for IHP SG13G2 (0.13um BiCMOS)
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="ihp-sg13g2"
RCFILE="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/xschemrc"
DEFAULT_SCH="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/start_page.sch"

if [ \$# -eq 0 ] && [ -f "\$DEFAULT_SCH" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$DEFAULT_SCH"
else
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$@"
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
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="sky130A"
RCFILE="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/xschemrc"
DEFAULT_SCH="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/sky130_tests/top.sch"

if [ \$# -eq 0 ] && [ -f "\$DEFAULT_SCH" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$DEFAULT_SCH"
else
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$@"
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
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="gf180mcuD"
RCFILE="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/xschemrc"
DEFAULT_SCH="\${PDK_ROOT}/\${PDK}/libs.tech/xschem/tests/0_top.sch"

if [ \$# -eq 0 ] && [ -f "\$DEFAULT_SCH" ]; then
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$DEFAULT_SCH"
else
    exec "${XSCHEM_BIN}" --rcfile "\$RCFILE" "\$@"
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
export PDK_ROOT="\${PDK_ROOT:-${PDK_ROOT}}"
export PDK="\${PDK:-ihp-sg13g2}"
exec "${XSCHEM_BIN}" "\$@"
EOF
    chmod +x "${INSTALL_BIN_DIR}/xschem"
    ln -sf "${INSTALL_BIN_DIR}/xschem" "${HOME}/bin/xschem"

    # 5. GTKWave wrapper
    GTKWAVE_BIN="$(dirname "$XSCHEM_BIN")/gtkwave"
    if [ -x "$GTKWAVE_BIN" ]; then
        cat << EOF > "${INSTALL_BIN_DIR}/gtkwave"
#!/usr/bin/env bash
export PATH="$(dirname "$XSCHEM_BIN"):\$PATH"
exec "${GTKWAVE_BIN}" "\$@"
EOF
        chmod +x "${INSTALL_BIN_DIR}/gtkwave"
        ln -sf "${INSTALL_BIN_DIR}/gtkwave" "${HOME}/bin/gtkwave"
    fi

    # 6. Ngspice wrapper
    NGSPICE_BIN="$(dirname "$XSCHEM_BIN")/ngspice"
    if [ -x "$NGSPICE_BIN" ]; then
        cat << EOF > "${INSTALL_BIN_DIR}/ngspice"
#!/usr/bin/env bash
export PATH="$(dirname "$XSCHEM_BIN"):\$PATH"
exec "${NGSPICE_BIN}" "\$@"
EOF
        chmod +x "${INSTALL_BIN_DIR}/ngspice"
        ln -sf "${INSTALL_BIN_DIR}/ngspice" "${HOME}/bin/ngspice"
    fi

    log_ok "Launchers generated in ${INSTALL_BIN_DIR} and ${HOME}/bin"
}

setup_shell_rc() {
    log_step "Updating Shell Configuration Files"

    EXPORT_BLOCK='
# >>> Xschem & EDA Environment Initialization >>>
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PDK_ROOT="${PDK_ROOT:-'$PDK_ROOT'}"
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
