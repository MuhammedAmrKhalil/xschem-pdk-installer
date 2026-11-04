#!/usr/bin/env bash
# ==============================================================================
# Open Source PDKs Installer (IHP SG13G2, Sky130, GF180MCU)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/os_detect.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/config.env"

setup_volare() {
    log_step "Configuring Volare PDK Manager"

    # Ensure pip is available
    PIP_EXE=""
    if command -v pip >/dev/null 2>&1; then
        PIP_EXE="$(command -v pip)"
    elif [ -x "${HOME}/miniforge3/envs/${CONDA_ENV_NAME}/bin/pip" ]; then
        PIP_EXE="${HOME}/miniforge3/envs/${CONDA_ENV_NAME}/bin/pip"
    elif [ -x "${HOME}/miniconda3/envs/${CONDA_ENV_NAME}/bin/pip" ]; then
        PIP_EXE="${HOME}/miniconda3/envs/${CONDA_ENV_NAME}/bin/pip"
    fi

    if [ -z "$PIP_EXE" ]; then
        log_error "Could not find pip in PATH or Conda environment '${CONDA_ENV_NAME}'."
        exit 1
    fi

    log_info "Installing / Updating volare..."
    "$PIP_EXE" install --upgrade volare

    # Find volare executable
    VOLARE_EXE="$(dirname "$PIP_EXE")/volare"
    if [ ! -x "$VOLARE_EXE" ]; then
        VOLARE_EXE="$(command -v volare || true)"
    fi

    # Apply patches for Volare stringification & timeout bugs if present
    SITE_PACKAGES="$("$PIP_EXE" show volare | grep -i "Location:" | awk '{print $2}')"
    if [ -n "$SITE_PACKAGES" ]; then
        # 1. Fix self.pdk string conversion in common.py
        COMMON_PY="${SITE_PACKAGES}/volare/common.py"
        if [ -f "$COMMON_PY" ]; then
            sed -i 's/pdk_name = self.pdk/pdk_name = self.pdk.name if hasattr(self.pdk, "name") else str(self.pdk)/' "$COMMON_PY" 2>/dev/null || true
        fi
        # 2. Fix HTTP timeout in github.py
        GITHUB_PY="${SITE_PACKAGES}/volare/github.py"
        if [ -f "$GITHUB_PY" ]; then
            sed -i 's/timeout=.*)/timeout=httpx.Timeout(120.0, connect=60.0))/' "$GITHUB_PY" 2>/dev/null || true
        fi
    fi

    export VOLARE_EXE
}

install_sky130() {
    log_step "Installing SkyWater 130nm PDK (sky130A)"
    mkdir -p "$PDK_ROOT"

    if [ -d "${PDK_ROOT}/sky130A/libs.tech/xschem" ]; then
        log_ok "SkyWater 130nm PDK already installed at: ${PDK_ROOT}/sky130A"
        return 0
    fi

    log_info "Downloading SkyWater 130nm via Volare into: ${PDK_ROOT}..."
    "$VOLARE_EXE" enable --pdk-root "$PDK_ROOT" sky130
    log_ok "SkyWater 130nm PDK ready."
}

install_gf180() {
    log_step "Installing GlobalFoundries 180nm MCU PDK (gf180mcuD)"
    mkdir -p "$PDK_ROOT"

    if [ -d "${PDK_ROOT}/gf180mcuD/libs.tech/xschem" ]; then
        log_ok "GlobalFoundries 180nm PDK already installed at: ${PDK_ROOT}/gf180mcuD"
        return 0
    fi

    log_info "Downloading GlobalFoundries 180nm via Volare into: ${PDK_ROOT}..."
    "$VOLARE_EXE" enable --pdk-root "$PDK_ROOT" gf180mcu
    log_ok "GlobalFoundries 180nm PDK ready."
}

install_ihp() {
    log_step "Installing IHP SG13G2 PDK & Compiling OSDI Models"
    mkdir -p "$PDK_ROOT"

    IHP_DIR="${HOME}/IHP-Open-PDK"
    if [ ! -d "$IHP_DIR" ]; then
        log_info "Cloning IHP-Open-PDK repository..."
        git clone --depth 1 "$IHP_PDK_REPO" "$IHP_DIR"
    else
        log_ok "IHP-Open-PDK repository already cloned at: ${IHP_DIR}"
    fi

    # Compile Verilog-A models using OpenVAF
    OPENVAF_BIN="$(command -v openvaf || echo "${INSTALL_BIN_DIR}/openvaf")"
    if [ -x "$OPENVAF_BIN" ]; then
        VA_DIR="${IHP_DIR}/ihp-sg13g2/libs.tech/ngspice/openvaf"
        if [ -d "$VA_DIR" ]; then
            log_info "Compiling Verilog-A models (.va -> .osdi) with OpenVAF..."
            cd "$VA_DIR"
            for va_file in *.va; do
                if [ -f "$va_file" ]; then
                    osdi_file="${va_file%.va}.osdi"
                    if [ ! -f "$osdi_file" ]; then
                        log_info "Compiling: $va_file -> $osdi_file"
                        "$OPENVAF_BIN" "$va_file" || log_warn "Failed to compile $va_file"
                    fi
                fi
            done
        fi
    else
        log_warn "OpenVAF binary not found; skipping Verilog-A model compilation."
    fi

    # Symlink to unified PDK_ROOT
    if [ ! -e "${PDK_ROOT}/ihp-sg13g2" ]; then
        ln -sf "${IHP_DIR}/ihp-sg13g2" "${PDK_ROOT}/ihp-sg13g2"
        log_ok "Symlinked ${PDK_ROOT}/ihp-sg13g2 -> ${IHP_DIR}/ihp-sg13g2"
    else
        log_ok "IHP SG13G2 already available in ${PDK_ROOT}/ihp-sg13g2"
    fi
}

main() {
    setup_volare
    install_sky130
    install_gf180
    install_ihp
    log_ok "All requested PDKs installed successfully in: $PDK_ROOT"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
