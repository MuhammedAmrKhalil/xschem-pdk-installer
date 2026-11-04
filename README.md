# Xschem EDA Suite & Open Source PDKs Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20(x86__64%20%7C%20aarch64)-orange.svg)](#supported-distributions)
[![PDK: IHP SG13G2](https://img.shields.io/badge/PDK-IHP%20SG13G2%20(0.13µm)-purple.svg)](#supported-pdks)
[![PDK: Sky130](https://img.shields.io/badge/PDK-SkyWater%20130nm-blue.svg)](#supported-pdks)
[![PDK: GF180MCU](https://img.shields.io/badge/PDK-GlobalFoundries%20180nm-red.svg)](#supported-pdks)
[![Simulator: Ngspice](https://img.shields.io/badge/Simulator-Ngspice%20v46%20(OSDI%2BKLU)-green.svg)](#included-eda-tools)

An automated, cross-distribution installer that provisions a complete, production-ready **Xschem** analog, mixed-signal, and RF integrated circuit design environment with unified open-source PDKs, simulation engines, Verilog-A compilation, and waveform viewers.

---

## Highlights

- **Universal Distro Support**: Works out-of-the-box on Debian, Ubuntu, Rocky Linux, RHEL, AlmaLinux, Fedora, Arch Linux, and openSUSE.
- **Zero-Sudo User-Space Mode**: Can install 100% into `$HOME` (`~/.local` and Miniforge/Conda) without requiring root privileges.
- **Dedicated Technology Launchers**: Independent, isolated entry points (`xschem_ihp`, `xschem_sky`, `xschem_gf`) pre-configured with respective technology libraries, symbols, and simulation models.
- **Verilog-A & OSDI Acceleration**: Integrates **OpenVAF** compiler and **Ngspice v46** built with OSDI and KLU direct linear solvers. Automatically builds IHP SG13G2 OSDI compact models (`psp103`, `r3_cmc`, `mosvar`, etc.).
- **Complete Waveform & Editor Suite**:
  - **GTKWave**: Digital and mixed-signal waveform analyzer (VCD, FST).
  - **Gaw**: Stefan Schippers' dedicated analog waveform viewer with real-time `Alt-G` schematic net cross-probing.
  - **GVim**: GUI-enabled text/netlist editor with fallback terminal safety wrappers.
  - **Icarus Verilog**: `iverilog` and `vvp` for digital testbenches.

---

## Supported Distributions

| Distribution Family | Tested Distributions | Package Manager Mode | User-Space Mode (No Root) |
| :--- | :--- | :--- | :--- |
| **Debian / Ubuntu** | Ubuntu 20.04/22.04/24.04, Debian 11/12 | `apt` | Supported |
| **RHEL / Fedora** | Rocky Linux 8/9, RHEL 8/9, AlmaLinux, Fedora 39/40 | `dnf` / `yum` | Supported |
| **Arch Linux** | Arch Linux, Manjaro, EndeavourOS | `pacman` | Supported |
| **openSUSE** | Leap 15.x, Tumbleweed | `zypper` | Supported |
| **Alpine Linux** | Alpine v3.18+ | `apk` | Supported |

---

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/MuhammedAmrKhalil/xschem-pdk-installer.git
cd xschem-pdk-installer
```

### 2. Run the Automated Installer

To install everything (tools, PDKs, and launchers):
```bash
./install.sh --all
```

To install in **100% User-Space mode** (without invoking `sudo`):
```bash
./install.sh --all --user
```

To install only specific PDKs:
```bash
./install.sh --pdk sky130   # SkyWater 130nm only
./install.sh --pdk ihp      # IHP SG13G2 only
./install.sh --pdk gf180    # GlobalFoundries 180nm only
```

### 3. Reload Shell Environment
```bash
source ~/.bashrc
# or restart your terminal session
```

---

## Dedicated PDK Launchers

Each launcher sets up the isolated environment, exports `PDK_ROOT` and `PDK`, and loads the correct technology `xschemrc` configuration:

| Command | Technology | PDK Directory | Startup Schematic |
| :--- | :--- | :--- | :--- |
| `xschem_ihp` | **IHP SG13G2** (0.13µm SiGe:C BiCMOS) | `~/pdk/ihp-sg13g2` | `start_page.sch` |
| `xschem_sky` | **SkyWater 130nm** (sky130A) | `~/pdk/sky130A` | `sky130_tests/top.sch` |
| `xschem_gf` | **GlobalFoundries 180nm** (gf180mcuD) | `~/pdk/gf180mcuD` | `tests/0_top.sch` |
| `xschem` | Standard Xschem launcher | User default | Blank / Custom |

Aliases provided:
- `xschem_sg13g2` $\rightarrow$ `xschem_ihp`
- `xschem_sky130` $\rightarrow$ `xschem_sky`
- `xschem_gf180` $\rightarrow$ `xschem_gf`

---

## Included EDA Tools

All tools are linked directly into `~/.local/bin` and `~/bin`:

- **`xschem`** (v3.4.5): Schematic editor for VLSI circuit design.
- **`ngspice`** (v46): SPICE circuit simulation engine with **KLU direct sparse solver** and **OSDI (Open Model Interface)** compiled in.
- **`openvaf`** (v23.5.0): High-performance Verilog-A compiler that compiles `.va` device descriptions into `.osdi` binary shared libraries for Ngspice.
- **`gtkwave`** (v3.3.121): GTK wave analyzer for viewing digital logic and mixed-signal simulations.
- **`gaw`** (v20250128): GTK analog waveform viewer designed for Xschem raw SPICE simulation files with socket cross-probing.
- **`gvim`**: GTK3 GUI text editor pre-configured as Xschem's code and symbol property editor.
- **`iverilog` & `vvp`** (v12.0): Icarus Verilog compiler and simulation runtime for digital testbench execution.

---

## Directory Architecture

```
$HOME/
├── .local/
│   ├── bin/                    # Standalone executable wrappers (in PATH)
│   │   ├── xschem_ihp
│   │   ├── xschem_sky
│   │   ├── xschem_gf
│   │   ├── xschem
│   │   ├── gtkwave
│   │   ├── gaw
│   │   ├── gvim
│   │   ├── ngspice
│   │   ├── openvaf
│   │   ├── iverilog
│   │   └── vvp
│   └── lib/                    # Shared library fallbacks
├── pdk/                        # Unified PDK root (PDK_ROOT)
│   ├── ihp-sg13g2/             # IHP 130nm BiCMOS Open PDK
│   ├── sky130A/                # SkyWater 130nm Open PDK
│   └── gf180mcuD/              # GlobalFoundries 180nm MCU Open PDK
└── miniforge3/
    └── envs/
        └── eda/                # Self-contained Conda EDA runtime
```

---

## Verification & Health Check

The repository includes a comprehensive 17-point test suite:

```bash
./tests/verify_all.sh
```

Example Output:
```text
==> Running Automated Toolchain & PDK Verification
Checking: Xschem schematic capture... PASS
Checking: IHP SG13G2 launcher (xschem_ihp)... PASS
Checking: SkyWater 130nm launcher (xschem_sky)... PASS
Checking: GlobalFoundries 180nm launcher (xschem_gf)... PASS
Checking: GTKWave waveform viewer... PASS
Checking: Gaw analog waveform viewer... PASS
Checking: GVim text editor... PASS
Checking: Ngspice circuit simulator... PASS
Checking: OpenVAF Verilog-A compiler... PASS
Checking: Icarus Verilog compiler... PASS
Checking: Icarus Verilog vvp engine... PASS
Checking: Xschem IHP SG13G2 rcfile execution... PASS
Checking: Xschem SkyWater 130nm rcfile execution... PASS
Checking: Xschem GF180MCU rcfile execution... PASS
Checking: Icarus Verilog compile & simulation... PASS
Checking: Ngspice simulation execution... PASS
Checking: Ngspice OSDI model loading (psp103.osdi)... PASS

================================================================================
Verification Results: 17 Passed, 0 Failed
================================================================================
[OK] All checks passed successfully!
```

---

## Interactive Analog Simulation Cross-Probing

To use interactive cross-probing between Xschem and Gaw:
1. Launch your schematic (e.g. `xschem_ihp`).
2. Press **Netlist** $\rightarrow$ **Simulate**.
3. In Xschem, select any net or terminal and press **`Alt-G`**.
4. The analog trace will appear immediately in the **Gaw** waveform window via internal TCP socket communication!

---

## Troubleshooting

### `can't read "PDK_ROOT": no such variable`
Make sure you have sourced your `~/.bashrc`:
```bash
source ~/.bashrc
```
Or export it explicitly:
```bash
export PDK_ROOT="$HOME/pdk"
```

### Slow Conda package resolution
The installer automatically forces `--solver=libmamba` and restricts search channels to `--override-channels -c conda-forge -c litex-hub -c unic-cass`. Never remove the libmamba solver flag to ensure package solves complete within seconds.

---

## Contributing & License

Contributions, issues, and PRs are welcome!
Distributed under the [MIT License](LICENSE).
Built with components from [Stefan Schippers (Xschem)](https://github.com/StefanSchippers/xschem), [IHP Microelectronics](https://github.com/IHP-GmbH), [SkyWater](https://github.com/google/skywater-pdk), [GlobalFoundries](https://github.com/google/gf180mcu-pdk), and [OpenVAF](https://openvaf.semimod.de/).
