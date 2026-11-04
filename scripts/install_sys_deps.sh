#!/usr/bin/env bash
# ==============================================================================
# System Dependencies Installer (Cross-Distro)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/os_detect.sh"

install_system_packages() {
    log_step "Checking & Installing System Dependencies"

    if [ "$HAS_SUDO" -eq 0 ]; then
        log_warn "No root or passwordless sudo privileges detected."
        log_warn "Skipping system-level package manager installation."
        log_info "The installer will proceed with 100% User-Space installation (Conda + ~/.local)."
        return 0
    fi

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    case "$PKG_MGR" in
        apt-get)
            log_info "Installing system packages via apt..."
            $SUDO_CMD apt-get update -y
            $SUDO_CMD apt-get install -y --no-install-recommends \
                curl wget git tar gzip bzip2 xz-utils make gcc g++ \
                pkg-config libx11-dev libxext-dev libxrender-dev \
                libgtk-3-dev libglib2.0-dev libcairo2-dev libpango1.0-dev \
                xterm vim-gtk3 iverilog
            ;;
        dnf|yum)
            log_info "Installing system packages via $PKG_MGR..."
            # Enable EPEL if not enabled on RHEL/Rocky/Alma
            if [ "$DISTRO_FAMILY" = "rhel" ] && [ "$DISTRO_ID" != "fedora" ]; then
                $SUDO_CMD "$PKG_MGR" install -y epel-release || true
            fi
            $SUDO_CMD "$PKG_MGR" install -y \
                curl wget git tar gzip bzip2 xz make gcc gcc-c++ \
                pkgconf-pkg-config libX11-devel libXext-devel libXrender-devel \
                gtk3-devel glib2-devel cairo-devel pango-devel \
                xterm vim-X11 iverilog || true
            ;;
        pacman)
            log_info "Installing system packages via pacman..."
            $SUDO_CMD pacman -Sy --noconfirm --needed \
                curl wget git tar gzip bzip2 xz make gcc \
                pkgconf libx11 libxext libxrender \
                gtk3 glib2 cairo pango \
                xterm gvim icarus-verilog
            ;;
        zypper)
            log_info "Installing system packages via zypper..."
            $SUDO_CMD zypper refresh
            $SUDO_CMD zypper install -y \
                curl wget git tar gzip bzip2 xz make gcc gcc-c++ \
                pkg-config libX11-devel libXext-devel \
                gtk3-devel glib2-devel cairo-devel pango-devel \
                xterm gvim
            ;;
        apk)
            log_info "Installing system packages via apk..."
            $SUDO_CMD apk update
            $SUDO_CMD apk add \
                curl wget git tar gzip bzip2 xz make gcc g++ \
                pkgconf libx11-dev libxext-dev \
                gtk+3.0-dev glib-dev cairo-dev pango-dev \
                xterm vim
            ;;
        *)
            log_warn "Unrecognized package manager: $PKG_MGR. Skipping system package installation."
            ;;
    esac

    log_ok "System package step completed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_system_packages
fi
