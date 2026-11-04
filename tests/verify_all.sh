#!/usr/bin/env bash
# ==============================================================================
# Comprehensive Health & Verification Suite
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../scripts/os_detect.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/config.env"

# Ensure PATH includes local bin
export PATH="${INSTALL_BIN_DIR}:${HOME}/bin:${PATH}"

PASS_COUNT=0
FAIL_COUNT=0

test_item() {
    local desc="$1"
    shift
    echo -n "Checking: ${desc}... "
    if "$@" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

log_step "Running Automated Toolchain & PDK Verification"

# 1. Binary availability tests
test_item "Xschem schematic capture" command -v xschem
test_item "IHP SG13G2 launcher (xschem_ihp)" command -v xschem_ihp
test_item "SkyWater 130nm launcher (xschem_sky)" command -v xschem_sky
test_item "GlobalFoundries 180nm launcher (xschem_gf)" command -v xschem_gf
test_item "GTKWave waveform viewer" command -v gtkwave
test_item "Gaw analog waveform viewer" command -v gaw
test_item "GVim text editor" command -v gvim
test_item "Ngspice circuit simulator" command -v ngspice
test_item "OpenVAF Verilog-A compiler" command -v openvaf
test_item "Icarus Verilog compiler" command -v iverilog
test_item "Icarus Verilog vvp engine" command -v vvp

# 2. Xschem PDK configuration checks (executed if PDKs are installed)
if [ -f "${PDK_ROOT}/ihp-sg13g2/libs.tech/xschem/xschemrc" ]; then
    test_item "Xschem IHP SG13G2 rcfile execution" bash -c "xschem_ihp -r -x -q 2>&1 | grep -iq 'models.*ihp'"
fi
if [ -f "${PDK_ROOT}/sky130A/libs.tech/xschem/xschemrc" ]; then
    test_item "Xschem SkyWater 130nm rcfile execution" bash -c "xschem_sky -r -x -q 2>&1 | grep -iq 'SKYWATER_MODELS'"
fi
if [ -f "${PDK_ROOT}/gf180mcuD/libs.tech/xschem/xschemrc" ]; then
    test_item "Xschem GF180MCU rcfile execution" bash -c "xschem_gf -r -x -q 2>&1 | grep -iq '180MCU_MODELS'"
fi

# 3. Verilog simulation & VCD dump test
TMP_VCD="$(mktemp /tmp/test_vcd_XXXXXX.v)"
cat << 'EOF' > "$TMP_VCD"
module test_sim;
  reg clk;
  initial begin
    $dumpfile("/tmp/verify_test.vcd");
    $dumpvars(0, test_sim);
    clk = 0;
    #5 clk = 1;
    #5 clk = 0;
    #5 $finish;
  end
endmodule
EOF
test_item "Icarus Verilog compile & simulation" bash -c "iverilog -o /tmp/verify_test.vvp $TMP_VCD && vvp /tmp/verify_test.vvp && [ -s /tmp/verify_test.vcd ]"
rm -f "$TMP_VCD" /tmp/verify_test.vvp /tmp/verify_test.vcd

# 4. Ngspice simulation & OSDI capability test
TMP_CIR="$(mktemp /tmp/test_cir_XXXXXX.cir)"
cat << 'EOF' > "$TMP_CIR"
* Minimal test simulation
V1 in 0 1
R1 in 0 1k
.op
.print op v(in)
.end
EOF
test_item "Ngspice simulation execution" bash -c "ngspice -b $TMP_CIR | grep -q 'v(in)'"
rm -f "$TMP_CIR"

if [ -f "${PDK_ROOT}/ihp-sg13g2/libs.tech/ngspice/osdi/psp103.osdi" ]; then
    TMP_OSDI="$(mktemp /tmp/test_osdi_XXXXXX.cir)"
    cat << EOF > "$TMP_OSDI"
* OSDI loading test
.control
osdi ${PDK_ROOT}/ihp-sg13g2/libs.tech/ngspice/osdi/psp103.osdi
echo OSDI_LOAD_OK
quit
.endc
.end
EOF
    test_item "Ngspice OSDI model loading (psp103.osdi)" bash -c "ngspice -b $TMP_OSDI | grep -q 'OSDI_LOAD_OK'"
    rm -f "$TMP_OSDI"
fi

echo -e "\n${BOLD}================================================================================${NC}"
echo -e "Verification Results: ${GREEN}${PASS_COUNT} Passed${NC}, ${RED}${FAIL_COUNT} Failed${NC}"
echo -e "${BOLD}================================================================================${NC}"

if [ "$FAIL_COUNT" -gt 0 ]; then
    log_warn "Some verification checks failed. Review logs above."
    exit 1
else
    log_ok "All checks passed successfully!"
    exit 0
fi
