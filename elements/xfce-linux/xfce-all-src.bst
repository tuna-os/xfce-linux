kind: manual
description: Build all XFCE Wayland components from source.

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
  - freedesktop-sdk.bst:components/systemd-libs.bst
  - freedesktop-sdk.bst:components/libdrm.bst
  - freedesktop-sdk.bst:components/libinput.bst
  - freedesktop-sdk.bst:components/libseat.bst
  - freedesktop-sdk.bst:components/libxkbcommon.bst
  - freedesktop-sdk.bst:components/pixman.bst
  - freedesktop-sdk.bst:components/wayland.bst
  - freedesktop-sdk.bst:components/wayland-protocols.bst
  - freedesktop-sdk.bst:components/rust.bst
  - freedesktop-sdk.bst:components/git.bst
  - freedesktop-sdk.bst:components/pkg-config.bst
  - freedesktop-sdk.bst:components/gtk3.bst
  - freedesktop-sdk.bst:components/libxslt.bst
  - freedesktop-sdk.bst:components/meson.bst
  - freedesktop-sdk.bst:components/cmake.bst
  - freedesktop-sdk.bst:components/gettext.bst
  - freedesktop-sdk.bst:components/gobject-introspection.bst
  - freedesktop-sdk.bst:components/vala.bst
  - freedesktop-sdk.bst:components/python3.bst
  - gnome-build-meta.bst:core-deps/intltool.bst
  - freedesktop-sdk.bst:components/gtk-doc.bst
  - freedesktop-sdk.bst:components/dummy-gbm.bst
  - freedesktop-sdk.bst:components/libdisplay-info.bst

sources:
- kind: local
  path: xfce-wayland-src
  directory: xfce-wayland

config:
  build-commands:
    - |
      cd xfce-wayland
      # Build order: xfce4-dev-tools -> libxfce4util -> xfconf -> libxfce4ui -> xfwl4
      
      export PREFIX=/usr
      export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig"
      
      echo "=== Building xfce4-dev-tools ==="
      cd xfce4-dev-tools
      NOCONFIGURE=1 ./autogen.sh
      ./configure --prefix=$PREFIX
      make -j$(nproc)
      make install
      cd ..
      
      echo "=== Building libxfce4util ==="
      cd xfce4-libs/libxfce4util
      NOCONFIGURE=1 ./autogen.sh
      ./configure --prefix=$PREFIX --disable-gtk-doc
      make -j$(nproc)
      make install
      cd ../..
      
      echo "=== Building xfconf ==="
      cd xfce4-libs/xfconf
      NOCONFIGURE=1 ./autogen.sh
      ./configure --prefix=$PREFIX --disable-gtk-doc
      make -j$(nproc)
      make install
      cd ../..
      
      echo "=== Building libxfce4ui ==="
      cd xfce4-libs/libxfce4ui
      NOCONFIGURE=1 ./autogen.sh
      ./configure --prefix=$PREFIX --disable-gtk-doc
      make -j$(nproc)
      make install
      cd ../..
      
      echo "=== Building xfwl4 ==="
      cd xfwl4
      cargo build --release --no-default-features --features udev,egl,xwayland,smithay/renderer_pixman,smithay/renderer_gl
      cd ..

  install-commands:
    - |
      mkdir -p "%{install-root}/usr/bin"
      cp xfce-wayland/xfwl4/target/release/xfwl4 "%{install-root}/usr/bin/"
      # Also install the libs we built
      # ... (omitted for now, just xfwl4 is enough to fix the crash)
