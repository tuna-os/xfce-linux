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
  - freedesktop-sdk.bst:components/gtk.bst
  - xfce-linux/xfce-binaries.bst

sources:
- kind: git_repo
  url: https://github.com/hanthor/xfce-wayland.git
  track: main
  ref: ef6789065952620b9d1e638fcd606b9bf14e5cf9
  directory: xfce-wayland

config:
  build-commands:
    - |
      cd xfce-wayland/xfwl4
      export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
      # Build with position-independent code to fix relocation issues
      export RUSTFLAGS="-C relocation-model=pic"
      cargo build --release --no-default-features --features udev,egl,xwayland,smithay/renderer_pixman,smithay/renderer_gl

  install-commands:
    - |
      mkdir -p "%{install-root}/usr/bin"
      cp xfce-wayland/xfwl4/target/release/xfwl4 "%{install-root}/usr/bin/"
