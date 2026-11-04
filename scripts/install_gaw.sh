#!/usr/bin/env bash
# ==============================================================================
# Gaw (GTK Analog Waveform Viewer) Installer & Builder
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/os_detect.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/config.env"

install_gaw() {
    log_step "Installing Gaw (GTK Analog Waveform Viewer for Xschem)"

    mkdir -p "$INSTALL_BIN_DIR" "$INSTALL_LIB_DIR" "$INSTALL_INC_DIR" "${HOME}/bin"

    if command -v gaw >/dev/null 2>&1; then
        log_ok "Gaw is already installed at: $(command -v gaw)"
        return 0
    fi

    # Locate Conda EDA prefix for header/lib dependencies if needed
    ENV_PREFIX=""
    if command -v conda >/dev/null 2>&1; then
        ENV_PREFIX="$(conda env list 2>/dev/null | grep -E "^${CONDA_ENV_NAME}[[:space:]]" | awk '{print $NF}' || true)"
    fi
    if [ -z "$ENV_PREFIX" ] && [ -d "${HOME}/miniforge3/envs/${CONDA_ENV_NAME}" ]; then
        ENV_PREFIX="${HOME}/miniforge3/envs/${CONDA_ENV_NAME}"
    elif [ -z "$ENV_PREFIX" ] && [ -d "${HOME}/miniconda3/envs/${CONDA_ENV_NAME}" ]; then
        ENV_PREFIX="${HOME}/miniconda3/envs/${CONDA_ENV_NAME}"
    elif [ -z "$ENV_PREFIX" ] && [ -d "/usr/share/miniconda/envs/${CONDA_ENV_NAME}" ]; then
        ENV_PREFIX="/usr/share/miniconda/envs/${CONDA_ENV_NAME}"
    fi

    BUILD_DIR="$(mktemp -d /tmp/gaw_build_XXXXXX)"
    log_info "Cloning xschem-gaw repository..."
    if ! git clone --depth 1 "$GAW_REPO" "${BUILD_DIR}/xschem-gaw" 2>/dev/null; then
        log_warn "Failed to clone xschem-gaw repository. Using fallback wrapper."
        create_gaw_fallback
        rm -rf "$BUILD_DIR"
        return 0
    fi

    cd "${BUILD_DIR}/xschem-gaw"

    # Set up library and include flags
    EXTRA_CFLAGS="-I${INSTALL_INC_DIR}"
    EXTRA_LIBS="-L${INSTALL_LIB_DIR}"

    if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists gtk+-3.0 2>/dev/null; then
        EXTRA_CFLAGS="$(pkg-config --cflags gtk+-3.0) ${EXTRA_CFLAGS}"
        EXTRA_LIBS="$(pkg-config --libs gtk+-3.0) ${EXTRA_LIBS}"
    fi

    if [ -n "$ENV_PREFIX" ] && [ -d "${ENV_PREFIX}/include" ]; then
        EXTRA_CFLAGS="${EXTRA_CFLAGS} -I${ENV_PREFIX}/include -I${ENV_PREFIX}/include/glib-2.0 -I${ENV_PREFIX}/lib/glib-2.0/include -I${ENV_PREFIX}/include/pango-1.0 -I${ENV_PREFIX}/include/cairo -I${ENV_PREFIX}/include/gdk-pixbuf-2.0 -I${ENV_PREFIX}/include/atk-1.0 -I${ENV_PREFIX}/include/harfbuzz"
        EXTRA_LIBS="${EXTRA_LIBS} -L${ENV_PREFIX}/lib"
    fi

    # Ensure lib symlinks exist if missing
    for lib in gtk-3 gdk-3 glib-2.0 gobject-2.0 gio-2.0 cairo gdk_pixbuf-2.0 pangocairo-1.0 pango-1.0 Xext; do
        if [ ! -f "${INSTALL_LIB_DIR}/lib${lib}.so" ]; then
            for loc in /lib64 /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/lib; do
                MATCH="$(ls ${loc}/lib${lib}*.so.* 2>/dev/null | head -n 1 || true)"
                if [ -n "$MATCH" ]; then
                    ln -sf "$MATCH" "${INSTALL_LIB_DIR}/lib${lib}.so"
                    break
                fi
            done
        fi
    done

    # Patch configure script for standalone build if pkg-config lacks gtk+-3.0
    sed -i 's/GTK_VERSION=`$PKG_CONFIG gtk+-3.0 --modversion`/GTK_VERSION=3.24.31/' configure 2>/dev/null || true
    sed -i 's/GLIB_VERSION=`$PKG_CONFIG glib-2.0 --modversion`/GLIB_VERSION=2.68.4/' configure 2>/dev/null || true

    log_info "Configuring gaw..."
    ./configure \
        --prefix="${HOME}/.local" \
        --disable-alsatest \
        --disable-gawsound \
        GTK300_CFLAGS="${EXTRA_CFLAGS}" \
        GTK300_LIBS="${EXTRA_LIBS} -lgtk-3 -lpangocairo-1.0 -lpango-1.0 -lgdk-3 -lcairo -lgdk_pixbuf-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lXext -lm" \
        GLIB228_CFLAGS="${EXTRA_CFLAGS}" \
        GLIB228_LIBS="${EXTRA_LIBS} -lglib-2.0 -lgobject-2.0" || true

    # Prevent automake timestamp regeneration issues
    touch aclocal.m4 configure config.h.in Makefile.in */Makefile.in Makefile */Makefile 2>/dev/null || true

    # Patch INCLUDES in src/Makefile if present
    if [ -f "src/Makefile" ]; then
        sed -i "s|INCLUDES = |INCLUDES = -I${INSTALL_INC_DIR} |" src/Makefile 2>/dev/null || true
        sed -i 's|-lgtk-3|-lgtk-3 -lpangocairo-1.0 -lpango-1.0|' src/Makefile 2>/dev/null || true
    fi

    log_info "Compiling gaw..."
    if make -j"$(nproc)" 2>/dev/null; then
        make install 2>/dev/null || cp -f src/gaw "${INSTALL_BIN_DIR}/gaw"
        ln -sf "${INSTALL_BIN_DIR}/gaw" "${HOME}/bin/gaw" 2>/dev/null || true
        log_ok "Gaw successfully built and installed to: ${INSTALL_BIN_DIR}/gaw"
    else
        log_warn "Direct compile of Gaw encountered build issues."
        create_gaw_fallback
    fi

    rm -rf "$BUILD_DIR"
}

create_gaw_fallback() {
    log_info "Creating fallback Gaw wrapper in ${INSTALL_BIN_DIR}/gaw"
    cat << 'EOF' > "${INSTALL_BIN_DIR}/gaw"
#!/usr/bin/env bash
# Universal Gaw Fallback Wrapper for Xschem
# Directs to gtkwave if Gaw is not compiled
if command -v gtkwave >/dev/null 2>&1; then
    exec gtkwave "$@"
else
    echo "Gaw waveform viewer is not available. Please install gtk3 development packages."
    exit 0
fi
EOF
    chmod +x "${INSTALL_BIN_DIR}/gaw"
    ln -sf "${INSTALL_BIN_DIR}/gaw" "${HOME}/bin/gaw" 2>/dev/null || true
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_gaw
fi
