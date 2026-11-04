#!/usr/bin/env bash
# ==============================================================================
# OpenVAF Verilog-A Compiler Installer
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/os_detect.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/config.env"

install_openvaf() {
    log_step "Installing OpenVAF (Verilog-A Compiler for OSDI)"

    mkdir -p "$INSTALL_BIN_DIR"

    if command -v openvaf >/dev/null 2>&1; then
        CURRENT_VER="$(openvaf --version 2>&1 || true)"
        log_ok "OpenVAF already installed: ${CURRENT_VER}"
        return 0
    fi

    if [ -x "${INSTALL_BIN_DIR}/openvaf" ]; then
        CURRENT_VER="$("${INSTALL_BIN_DIR}/openvaf" --version 2>&1 || true)"
        log_ok "OpenVAF found in ${INSTALL_BIN_DIR}: ${CURRENT_VER}"
        return 0
    fi

    log_info "Downloading OpenVAF v${OPENVAF_VERSION} from: ${OPENVAF_URL}"
    TMP_DIR="$(mktemp -d /tmp/openvaf_install_XXXXXX)"
    
    if curl -fSL "$OPENVAF_URL" -o "${TMP_DIR}/openvaf.tar.gz"; then
        tar -xzf "${TMP_DIR}/openvaf.tar.gz" -C "${TMP_DIR}"
        # Binary could be directly in root or subdir
        BIN_FOUND="$(find "${TMP_DIR}" -type f -name "openvaf" | head -n 1)"
        if [ -n "$BIN_FOUND" ]; then
            chmod +x "$BIN_FOUND"
            cp -f "$BIN_FOUND" "${INSTALL_BIN_DIR}/openvaf"
            log_ok "OpenVAF installed to: ${INSTALL_BIN_DIR}/openvaf"
        else
            log_error "Could not find openvaf executable inside tarball."
            rm -rf "$TMP_DIR"
            exit 1
        fi
    else
        log_error "Failed to download OpenVAF from ${OPENVAF_URL}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    rm -rf "$TMP_DIR"
    "${INSTALL_BIN_DIR}/openvaf" --version
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_openvaf
fi
