#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/home/chung/.local}"
JOBS="${JOBS:-$(nproc)}"

CFLAGS="-O2 -pipe -march=native -mtune=native -fomit-frame-pointer -fno-plt -flto=auto -fno-semantic-interposition"
LDFLAGS="-flto=auto -O2 -Wl,-O2 -Wl,-z,now -Wl,-z,relro -Wl,--sort-common -Wl,--as-needed -Wl,-z,pack-relative-relocs"

./configure \
    --prefix="$PREFIX" \
    --enable-link-time-optimization \
    --disable-gc-mark-trace \
    --disable-build-details \
    --with-wide-int \
    --with-threads \
    --with-modules \
    --with-native-compilation=aot \
    --with-pgtk \
    --without-x \
    --without-x-toolkit \
    --without-xft \
    --without-xim \
    --without-xaw3d \
    --without-xdbe \
    --without-xinput2 \
    --without-xwidgets \
    --with-toolkit-scroll-bars \
    --with-cairo \
    --with-xpm \
    --with-png \
    --with-jpeg \
    --with-gif \
    --with-tiff \
    --with-webp \
    --with-rsvg \
    --with-imagemagick \
    --with-lcms2 \
    --with-sound \
    --with-harfbuzz \
    --with-libotf \
    --with-m17n-flt \
    --with-dbus \
    --with-gsettings \
    --with-libsystemd \
    --with-file-notification=inotify \
    --with-gnutls \
    --with-xml2 \
    --with-zlib \
    --with-libgmp \
    --with-sqlite3 \
    --with-tree-sitter \
    --with-mailutils \
    --without-pop \
    --without-kerberos \
    --without-kerberos5 \
    --without-hesiod \
    --without-gpm \
    --without-selinux \
    --without-compress-install \
    --with-dumping=pdumper \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

make -j"$JOBS" NATIVE_FULL_AOT=1
