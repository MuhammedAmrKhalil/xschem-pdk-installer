#!/usr/bin/env bash
# ==============================================================================
# Conda / Mamba EDA Environment Setup
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/os_detect.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/config.env"

setup_conda_base() {
    log_step "Locating or Installing Conda / Miniforge"

    CONDA_EXE=""
    if command -v conda >/dev/null 2>&1; then
        CONDA_EXE="$(command -v conda)"
        log_ok "Found existing conda in PATH: $CONDA_EXE"
    elif [ -x "${HOME}/miniforge3/bin/conda" ]; then
        CONDA_EXE="${HOME}/miniforge3/bin/conda"
        log_ok "Found conda at ~/miniforge3/bin/conda"
    elif [ -x "${HOME}/miniconda3/bin/conda" ]; then
        CONDA_EXE="${HOME}/miniconda3/bin/conda"
        log_ok "Found conda at ~/miniconda3/bin/conda"
    elif [ -x "/usr/share/miniconda/bin/conda" ]; then
        CONDA_EXE="/usr/share/miniconda/bin/conda"
        log_ok "Found conda at /usr/share/miniconda/bin/conda"
    elif [ -x "/opt/conda/bin/conda" ]; then
        CONDA_EXE="/opt/conda/bin/conda"
        log_ok "Found conda at /opt/conda/bin/conda"
    fi

    if [ -z "$CONDA_EXE" ]; then
        log_info "No Conda installation detected. Installing standalone Miniforge into: $CONDA_DIR"
        MINIFORGE_ARCH="x86_64"
        if [ "$ARCH" = "aarch64" ]; then
            MINIFORGE_ARCH="aarch64"
        fi
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${MINIFORGE_ARCH}.sh"
        
        INSTALLER_TMP="/tmp/miniforge_installer.sh"
        curl -fsSL "$MINIFORGE_URL" -o "$INSTALLER_TMP"
        bash "$INSTALLER_TMP" -b -p "$CONDA_DIR"
        rm -f "$INSTALLER_TMP"
        CONDA_EXE="${CONDA_DIR}/bin/conda"
        log_ok "Miniforge successfully installed at: $CONDA_DIR"
    fi

    export CONDA_EXE
}

setup_eda_env() {
    log_step "Configuring EDA Conda Environment: '${CONDA_ENV_NAME}'"

    # Ensure libmamba solver is available if not present
    if ! "$CONDA_EXE" list -n base conda-libmamba-solver 2>/dev/null | grep -q conda-libmamba-solver; then
        "$CONDA_EXE" install -y -n base conda-libmamba-solver --override-channels -c conda-forge 2>/dev/null || true
    fi

    # Check if target environment exists
    if "$CONDA_EXE" env list 2>/dev/null | grep -qE "^${CONDA_ENV_NAME}[[:space:]]"; then
        log_info "Conda environment '${CONDA_ENV_NAME}' already exists. Updating packages..."
    else
        log_info "Creating conda environment '${CONDA_ENV_NAME}'..."
        "$CONDA_EXE" create -y -n "${CONDA_ENV_NAME}" python=3.11 --override-channels -c conda-forge
    fi

    # Install core EDA packages
    # Note: unic-cass provides ngspice with --enable-osdi and --enable-klu
    log_info "Installing Xschem, Ngspice (OSDI+KLU), GTKWave, and dependencies..."
    if ! "$CONDA_EXE" install -y -n "${CONDA_ENV_NAME}" \
        --solver=libmamba \
        --override-channels \
        -c conda-forge \
        -c litex-hub \
        -c unic-cass \
        xschem \
        ngspice \
        gtkwave \
        iverilog \
        git \
        curl \
        pip \
        setuptools \
        wheel; then
        log_warn "Libmamba solve returned an issue. Retrying with default solver..."
        "$CONDA_EXE" install -y -n "${CONDA_ENV_NAME}" \
            --override-channels \
            -c conda-forge \
            -c litex-hub \
            -c unic-cass \
            xschem \
            ngspice \
            gtkwave \
            iverilog \
            git \
            curl \
            pip \
            setuptools \
            wheel
    fi

    # Resolve environment prefix path
    ENV_PREFIX="$("$CONDA_EXE" env list | grep -E "^${CONDA_ENV_NAME}[[:space:]]" | awk '{print $NF}')"
    log_ok "EDA Environment Ready at: ${ENV_PREFIX}"
    export ENV_PREFIX
}

main() {
    setup_conda_base
    setup_eda_env
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
