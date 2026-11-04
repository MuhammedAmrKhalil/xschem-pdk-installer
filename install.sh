#!/usr/bin/env bash
# ==============================================================================
# Xschem EDA Suite & Open Source PDKs - Universal Automated Installer
# Supported: Ubuntu, Debian, RHEL, Rocky, AlmaLinux, Fedora, Arch, openSUSE, Alpine
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/config.env"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/os_detect.sh"

print_banner() {
    echo -e "${BOLD}${CYAN}"
    echo "================================================================================"
    echo "     ____  __      __                   ____  ____  __ __   ______      _ __    "
    echo "    / __ \/ /_  __/ /_____  ____ _____ / __ \/ __ \/ //_/  / ____/_  __(_) /____ "
    echo "   / / / / __ \/ / __/ __ \/ __ \`/ __ \/ /_/ / / / / ,<    /___ \/ / / / / __/ _ \\"
    echo "  / /_/ / /_/ / / /_/ /_/ / /_/ / /_/ / ____/ /_/ / /| |  ____/ / /_/ / / /_/  __/"
    echo "  \____/_.___/_/\__/\____/\__,_/\__,_/_/   /_____/_/ |_| /_____/\__,_/_/\__/\___/ "
    echo "================================================================================"
    echo -e "${NC}"
    echo -e "${BOLD}Universal Automated Installer for Xschem, Ngspice, OpenVAF & Open PDKs${NC}"
    echo -e "Target Directory: ${GREEN}${PDK_ROOT}${NC} | Binaries: ${GREEN}${INSTALL_BIN_DIR}${NC}\n"
}

show_help() {
    cat << EOF
Usage: ./install.sh [OPTIONS]

Options:
  -a, --all         Perform complete installation (tools, all PDKs, launchers, verification)
  -t, --tools       Install EDA tools only (Xschem, Ngspice OSDI+KLU, OpenVAF, GTKWave, GVim, Gaw)
  -p, --pdks        Install all PDKs (IHP SG13G2, SkyWater 130nm, GlobalFoundries 180nm)
  --pdk <name>      Install specific PDK: 'ihp', 'sky130', or 'gf180'
  -u, --user        Force 100% user-space mode (skip system package manager even if sudo is present)
  -v, --verify      Run the automated verification suite
  -h, --help        Show this help message and exit

Examples:
  ./install.sh --all            # Install full suite unattended
  ./install.sh --tools          # Install only the toolchain
  ./install.sh --pdk sky130     # Install only SkyWater 130nm PDK
  ./install.sh --verify         # Run health check on existing installation
EOF
}

DO_SYS_DEPS=1
DO_TOOLS=0
DO_PDKS=0
SPECIFIC_PDK=""
DO_VERIFY=0

parse_args() {
    if [ $# -eq 0 ]; then
        # Default to interactive or full install
        DO_TOOLS=1
        DO_PDKS=1
        DO_VERIFY=1
        return 0
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            -a|--all)
                DO_TOOLS=1
                DO_PDKS=1
                DO_VERIFY=1
                shift
                ;;
            -t|--tools)
                DO_TOOLS=1
                shift
                ;;
            -p|--pdks)
                DO_PDKS=1
                shift
                ;;
            --pdk)
                DO_PDKS=1
                SPECIFIC_PDK="$2"
                shift 2
                ;;
            -u|--user)
                HAS_SUDO=0
                DO_SYS_DEPS=0
                shift
                ;;
            -v|--verify)
                DO_VERIFY=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

run_installation() {
    print_banner
    print_os_summary

    # Step 1: System Dependencies
    if [ "$DO_SYS_DEPS" -eq 1 ] && [ "$DO_TOOLS" -eq 1 ]; then
        bash "${SCRIPT_DIR}/scripts/install_sys_deps.sh"
    fi

    # Step 2: Conda / Toolchain
    if [ "$DO_TOOLS" -eq 1 ]; then
        bash "${SCRIPT_DIR}/scripts/setup_conda.sh"
        bash "${SCRIPT_DIR}/scripts/install_openvaf.sh"
        bash "${SCRIPT_DIR}/scripts/install_gvim.sh"
        bash "${SCRIPT_DIR}/scripts/install_gaw.sh"
        bash "${SCRIPT_DIR}/scripts/setup_launchers.sh"
    fi

    # Step 3: PDKs
    if [ "$DO_PDKS" -eq 1 ]; then
        if [ -n "$SPECIFIC_PDK" ]; then
            # Install single requested PDK
            source "${SCRIPT_DIR}/scripts/install_pdks.sh"
            setup_volare
            case "$SPECIFIC_PDK" in
                ihp|sg13g2)     install_ihp ;;
                sky130|sky)     install_sky130 ;;
                gf180|gf)       install_gf180 ;;
                *)
                    log_error "Unknown PDK: $SPECIFIC_PDK. Choose from: ihp, sky130, gf180"
                    exit 1
                    ;;
            esac
        else
            bash "${SCRIPT_DIR}/scripts/install_pdks.sh"
        fi
        bash "${SCRIPT_DIR}/scripts/setup_launchers.sh"
    fi

    # Step 4: Verification
    if [ "$DO_VERIFY" -eq 1 ]; then
        bash "${SCRIPT_DIR}/tests/verify_all.sh"
    fi

    echo -e "\n${BOLD}${GREEN}================================================================================"
    echo "           🎉  XSCHEM & OPEN PDK SUITE INSTALLATION COMPLETE!  🎉"
    echo "================================================================================${NC}"
    echo -e "You can now run your dedicated technology environments directly from terminal:\n"
    echo -e "  * IHP SG13G2 (0.13µm BiCMOS):        ${CYAN}xschem_ihp${NC}  (or xschem_sg13g2)"
    echo -e "  * SkyWater 130nm (sky130A):           ${CYAN}xschem_sky${NC}  (or xschem_sky130)"
    echo -e "  * GlobalFoundries 180nm (gf180mcuD):  ${CYAN}xschem_gf${NC}   (or xschem_gf180)"
    echo -e "  * Standard Xschem Launcher:           ${CYAN}xschem${NC}"
    echo -e "  * GTKWave Digital Waveform Viewer:    ${CYAN}gtkwave${NC}"
    echo -e "  * Gaw Analog Waveform Viewer:         ${CYAN}gaw${NC}"
    echo -e "  * GVim GUI Editor:                    ${CYAN}gvim${NC}"
    echo -e "  * Ngspice Simulator (OSDI+KLU):       ${CYAN}ngspice${NC}"
    echo -e "  * OpenVAF Verilog-A Compiler:         ${CYAN}openvaf${NC}"
    echo -e "\nPlease restart your terminal session or run: ${BOLD}source ~/.bashrc${NC}\n"
}

parse_args "$@"
run_installation
