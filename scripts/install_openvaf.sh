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

    mkdir -p "$INSTALL_BIN_DIR" "${HOME}/bin"

    if command -v openvaf >/dev/null 2>&1; then
        CURRENT_VER="$(openvaf --version 2>&1 || true)"
        log_ok "OpenVAF already installed: ${CURRENT_VER}"
        # Ensure it exists in INSTALL_BIN_DIR too
        if [ ! -f "${INSTALL_BIN_DIR}/openvaf" ]; then
            ln -sf "$(command -v openvaf)" "${INSTALL_BIN_DIR}/openvaf"
        fi
        return 0
    fi

    if [ -x "${INSTALL_BIN_DIR}/openvaf" ]; then
        CURRENT_VER="$("${INSTALL_BIN_DIR}/openvaf" --version 2>&1 || true)"
        log_ok "OpenVAF found in ${INSTALL_BIN_DIR}: ${CURRENT_VER}"
        return 0
    fi

    TMP_DIR="$(mktemp -d /tmp/openvaf_install_XXXXXX)"
    
    URL_CANDIDATES=(
        "${OPENVAF_URL}"
        "https://openva.fra1.cdn.digitaloceanspaces.com/openvaf_${OPENVAF_VERSION//./_}_linux_amd64.tar.gz"
        "https://fides.fe.uni-lj.si/openvaf/download/openvaf-reloaded-osdi_0.4-linux_x64.tar.gz"
    )

    DOWNLOAD_OK=0
    for url in "${URL_CANDIDATES[@]}"; do
        log_info "Attempting download from: ${url}"
        if curl -fSL "$url" -o "${TMP_DIR}/openvaf.tar.gz"; then
            DOWNLOAD_OK=1
            log_ok "Successfully downloaded from: ${url}"
            break
        else
            log_warn "Download failed from: ${url}"
        fi
    done

    if [ "$DOWNLOAD_OK" -eq 1 ]; then
        tar -xzf "${TMP_DIR}/openvaf.tar.gz" -C "${TMP_DIR}"
        BIN_FOUND="$(find "${TMP_DIR}" -type f -name "openvaf" | head -n 1)"
        if [ -n "$BIN_FOUND" ]; then
            chmod +x "$BIN_FOUND"
            cp -f "$BIN_FOUND" "${INSTALL_BIN_DIR}/openvaf"
            ln -sf "${INSTALL_BIN_DIR}/openvaf" "${HOME}/bin/openvaf" 2>/dev/null || true
            log_ok "OpenVAF installed to: ${INSTALL_BIN_DIR}/openvaf"
        else
            log_error "Could not find openvaf executable inside downloaded archive."
            rm -rf "$TMP_DIR"
            exit 1
        fi
    else
        log_error "Failed to download OpenVAF from all available mirror URLs."
        rm -rf "$TMP_DIR"
        exit 1
    fi

    rm -rf "$TMP_DIR"
    "${INSTALL_BIN_DIR}/openvaf" --version
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_openvaf
fi
