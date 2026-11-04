#!/usr/bin/env bash
# ==============================================================================
# OS & Distribution Detection Utility
# ==============================================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()  { echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}"; }

detect_os() {
    OS_TYPE="$(uname -s)"
    ARCH="$(uname -m)"

    if [ "$OS_TYPE" != "Linux" ]; then
        log_error "Unsupported Operating System: $OS_TYPE. This installer currently targets Linux."
        exit 1
    fi

    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
        log_error "Unsupported Architecture: $ARCH. Only x86_64 and aarch64 are supported."
        exit 1
    fi

    DISTRO_ID="unknown"
    DISTRO_FAMILY="unknown"
    DISTRO_VERSION="unknown"
    PKG_MGR="unknown"

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
        
        case "${ID:-}" in
            ubuntu|debian|linuxmint|pop|elementary|raspbian)
                DISTRO_FAMILY="debian"
                PKG_MGR="apt-get"
                ;;
            fedora|rhel|centos|rocky|almalinux|ol)
                DISTRO_FAMILY="rhel"
                if command -v dnf >/dev/null 2>&1; then
                    PKG_MGR="dnf"
                else
                    PKG_MGR="yum"
                fi
                ;;
            arch|manjaro|endeavouros|artix)
                DISTRO_FAMILY="arch"
                PKG_MGR="pacman"
                ;;
            opensuse*|sles)
                DISTRO_FAMILY="suse"
                PKG_MGR="zypper"
                ;;
            alpine)
                DISTRO_FAMILY="alpine"
                PKG_MGR="apk"
                ;;
            *)
                if [ -n "${ID_LIKE:-}" ]; then
                    case "$ID_LIKE" in
                        *debian*|*ubuntu*)
                            DISTRO_FAMILY="debian"
                            PKG_MGR="apt-get"
                            ;;
                        *rhel*|*fedora*|*centos*)
                            DISTRO_FAMILY="rhel"
                            PKG_MGR="dnf"
                            ;;
                        *arch*)
                            DISTRO_FAMILY="arch"
                            PKG_MGR="pacman"
                            ;;
                        *suse*)
                            DISTRO_FAMILY="suse"
                            PKG_MGR="zypper"
                            ;;
                    esac
                fi
                ;;
        esac
    fi

    # Check sudo capability
    HAS_SUDO=0
    if [ "$(id -u)" -eq 0 ]; then
        HAS_SUDO=1
    elif command -v sudo >/dev/null 2>&1; then
        if sudo -n true 2>/dev/null; then
            HAS_SUDO=1
        fi
    fi

    export OS_TYPE ARCH DISTRO_ID DISTRO_FAMILY DISTRO_VERSION PKG_MGR HAS_SUDO
}

print_os_summary() {
    log_info "Detected OS:           ${BOLD}${OS_TYPE} (${ARCH})${NC}"
    log_info "Distribution:          ${BOLD}${DISTRO_ID} ${DISTRO_VERSION} (${DISTRO_FAMILY})${NC}"
    log_info "System Package Manager: ${BOLD}${PKG_MGR}${NC}"
    if [ "$HAS_SUDO" -eq 1 ]; then
        log_info "Privilege Level:       ${GREEN}Passwordless Sudo / Root Available${NC}"
    else
        log_info "Privilege Level:       ${YELLOW}User-Space Mode (No Sudo Required)${NC}"
    fi
}

detect_os
