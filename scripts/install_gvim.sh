#!/usr/bin/env bash
# ==============================================================================
# GVim (GUI Text Editor) Installer & Fallback Wrapper
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/os_detect.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/config.env"

install_gvim() {
    log_step "Installing & Configuring GVim (GUI Editor for Xschem)"

    mkdir -p "$INSTALL_BIN_DIR"

    # Check if a native GUI gvim is already available
    if command -v gvim >/dev/null 2>&1 && [ ! -L "$(command -v gvim)" ]; then
        log_ok "Native gvim already available at: $(command -v gvim)"
        return 0
    fi

    # Distro-specific user-space installation if root is not available
    if [ "$DISTRO_FAMILY" = "rhel" ] && ! command -v gvim >/dev/null 2>&1; then
        log_info "Attempting user-space extraction of vim-X11 RPM..."
        TMP_DIR="$(mktemp -d /tmp/gvim_rpm_XXXXXX)"
        if command -v dnf >/dev/null 2>&1; then
            RPM_URL="$(dnf download --urls vim-X11 2>/dev/null | grep -E '^http.*\.rpm$' | head -n 1 || true)"
            if [ -n "$RPM_URL" ] && command -v rpm2cpio >/dev/null 2>&1; then
                log_info "Downloading RPM: $RPM_URL"
                curl -fsSL "$RPM_URL" -o "${TMP_DIR}/vim-X11.rpm"
                (cd "$TMP_DIR" && rpm2cpio vim-X11.rpm | cpio -idmv >/dev/null 2>&1)
                if [ -f "${TMP_DIR}/usr/bin/gvim" ]; then
                    cp -f "${TMP_DIR}/usr/bin/gvim" "${INSTALL_BIN_DIR}/gvim.real"
                    chmod +x "${INSTALL_BIN_DIR}/gvim.real"
                    log_ok "Extracted gvim.real to ${INSTALL_BIN_DIR}"
                fi
            fi
        fi
        rm -rf "$TMP_DIR"
    fi

    # Create universal gvim wrapper script
    log_info "Generating universal gvim wrapper in ${INSTALL_BIN_DIR}/gvim"
    cat << 'EOF' > "${INSTALL_BIN_DIR}/gvim"
#!/usr/bin/env bash
# Universal GVim Wrapper for Xschem
# Prioritizes GTK GUI when DISPLAY is set, with graceful terminal fallback

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Check for standalone extracted binary
if [ -x "${DIR}/gvim.real" ] && [ -n "${DISPLAY:-}" ]; then
    exec "${DIR}/gvim.real" "$@"
fi

# 2. Check for system gvim
if [ -x "/usr/bin/gvim" ] && [ -n "${DISPLAY:-}" ]; then
    exec /usr/bin/gvim "$@"
fi

# 3. Check for vim with GUI support
if command -v vim >/dev/null 2>&1; then
    if [ -n "${DISPLAY:-}" ] && command -v xterm >/dev/null 2>&1; then
        exec xterm -geometry 90x28 -T "Xschem Editor" -e vim "$@"
    else
        exec vim "$@"
    fi
fi

# 4. Final fallback to nano / vi
if command -v nano >/dev/null 2>&1; then
    exec nano "$@"
fi

exec vi "$@"
EOF
    chmod +x "${INSTALL_BIN_DIR}/gvim"
    log_ok "GVim wrapper installed: ${INSTALL_BIN_DIR}/gvim"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_gvim
fi
