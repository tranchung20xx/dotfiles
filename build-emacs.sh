#!/usr/bin/env bash
# Minimal Emacs build — optimized for speed
# Keeps: core Lisp, text editing, native compilation (AOT speed), threads

set -euo pipefail

PREFIX="${PREFIX:-/home/chung/.local}"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

CFLAGS="-O2 -pipe -march=native -mtune=native -fno-omit-frame-pointer -fno-plt -flto=auto"
LDFLAGS="-Wl,-O2 -Wl,-z,now -Wl,-z,relro -Wl,--sort-common -Wl,--as-needed -Wl,-z,pack-relative-relocs -flto=auto -O2"

# Detect if native-comp deps are present (libgccjit)
NATIVE_COMP="--with-native-compilation=aot"

./configure \
    --prefix="$PREFIX" \
    \
    `# --- Speed & size: link-time optimization ---` \
    --enable-link-time-optimization \
    --disable-gc-mark-trace \
    --disable-build-details \
    --disable-acl \
    --disable-ns-self-contained \
    --disable-xattr \
    \
    `# --- Core: keep wide integers for performance, threads for async ---` \
    --with-wide-int \
    --with-threads \
    --with-modules \
    "$NATIVE_COMP" \
    \
    `# --- GUI: pure GTK (Wayland + X via GTK, no legacy X11 libs) ---` \
    --with-pgtk \
    --without-x \
    --without-x-toolkit \
    --without-xft \
    --without-xim \
    --without-xaw3d \
    --without-xdbe \
    --without-xinput2 \
    --without-xwidgets \
    --with-xpm \
    --without-ns \
    --without-be-app \
    --without-be-cairo \
    --with-toolkit-scroll-bars \
    \
    `# --- Strip all image format support (keep PNG for GTK icons) ---` \
    --with-png \
    --with-cairo \
    --without-cairo-xcb \
    --with-gif \
    --with-jpeg \
    --with-tiff \
    --with-webp \
    --with-rsvg \
    --with-imagemagick \
    --without-native-image-api \
    \
    `# --- audio ---` \
    --with-sound \
    \
    `# --- Strip network / auth extras ---` \
    --without-pop \
    --without-hesiod \
    --without-kerberos \
    --without-kerberos5 \
    --with-mailutils \
    --without-gpm \
    --without-mail-unlink \
    \
    `# --- Strip desktop integration ---` \
    --without-gsettings \
    --without-dbus \
    --without-gconf \
    --without-libsystemd \
    --with-file-notification=inotify \
    \
    `# --- Strip font/text shaping extras (keep harfbuzz for correct rendering) ---` \
    --with-harfbuzz \
    --without-libotf \
    --without-m17n-flt \
    \
    `# --- Keep useful core libs, strip optional ones ---` \
    --with-gnutls \
    --with-xml2 \
    --with-zlib \
    --with-libgmp \
    --with-sqlite3 \
    --without-tree-sitter \
    --without-lcms2 \
    --without-selinux \
    --without-gameuser \
    --without-included-regex \
    `# --- Use pdumper (fastest startup method) ---` \
    --with-dumping=pdumper \
    \
    `# --- Skip compressed install (faster install step) ---` \
    --without-compress-install \
    \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

make -j"$JOBS" NATIVE_FULL_AOT=1 CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
