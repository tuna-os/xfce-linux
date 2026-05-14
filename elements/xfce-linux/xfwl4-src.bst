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
  - freedesktop-sdk.bst:components/rust.bst
  - freedesktop-sdk.bst:components/git.bst
  - freedesktop-sdk.bst:components/pkg-config.bst
  - freedesktop-sdk.bst:components/dummy-gbm.bst
  - freedesktop-sdk.bst:components/libdisplay-info.bst
  - xfce-linux/xfce-binaries.bst

sources:
- kind: git_repo
  url: https://github.com/hanthor/xfwl4.git
  track: main
  ref: 0a3a9d2f97d02d4e64a53d468d3cb2f500caf1f5
  directory: xfwl4

config:
  build-commands:
    - |
      cd xfwl4
      export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
      # Build with position-independent code to fix relocation issues
      export RUSTFLAGS="-C relocation-model=pic"
      cargo build --release --no-default-features --features udev,egl,xwayland,smithay/renderer_pixman,smithay/renderer_gl

  install-commands:
    - |
      mkdir -p "%{install-root}/usr/bin"
      cp xfwl4/target/release/xfwl4 "%{install-root}/usr/bin/"

