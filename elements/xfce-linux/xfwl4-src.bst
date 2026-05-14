kind: manual
description: Build xfwl4 compositor from source with TTY support.

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
  - freedesktop-sdk.bst:components/gtk3.bst
  - freedesktop-sdk.bst:components/gdk-pixbuf.bst
  - freedesktop-sdk.bst:components/xorg-lib-sm.bst
  - gnome-build-meta.bst:core-deps/startup-notification.bst
  - freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
  - freedesktop-sdk.bst:components/rust.bst
  - freedesktop-sdk.bst:components/gettext.bst
  - freedesktop-sdk.bst:components/dummy-gbm.bst
  - freedesktop-sdk.bst:components/libdisplay-info.bst
  - xfce-linux/xfce-binaries.bst

sources:
- kind: git_repo
  url: https://github.com/hanthor/xfwl4.git
  track: main
  ref: 152be7f8cf62823dc7b51855ee33c87c302e26f
  directory: xfwl4
- kind: git_repo
  url: https://gitlab.xfce.org/kelnos/xfce-wayland-protocols.git
  ref: 4299072022d5fc9be0505f293cbe0f7f5ab6da00
  directory: xfwl4/resources/xfce-wayland-protocols

config:
  build-commands:
    - |
      cd xfwl4
      export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
      export RUSTFLAGS="-C relocation-model=pic"
      export GETTEXT_SYSTEM=1
      cargo build --release --offline --frozen --no-default-features --features udev,egl,xwayland,smithay/renderer_pixman,smithay/renderer_gl

  install-commands:
    - |
      mkdir -p "%{install-root}/usr/bin"
      cp xfwl4/target/release/xfwl4 "%{install-root}/usr/bin/"

