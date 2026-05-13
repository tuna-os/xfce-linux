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
  url: https://github.com/hanthor/xfce-wayland.git
  track: main
  ref: 0155e26bdd91ef43d5d42954a2967233fda8f942
  directory: xfce-wayland

config:
  build-commands:
    - |
      cd xfce-wayland/xfwl4
      
      # Use the staged headers and libraries from xfce-binaries
      export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
      export LIBRARY_PATH="/usr/lib64:/usr/lib"
      
      # Fix Rust linking issues
      export RUSTFLAGS="-L /usr/lib64 -L /usr/lib -C link-arg=-Wl,-rpath-link,/usr/lib64"
      
      cargo build --release --no-default-features --features udev,egl,xwayland,smithay/renderer_pixman,smithay/renderer_gl

  install-commands:
    - |
      mkdir -p "%{install-root}/usr/bin"
      cp xfce-wayland/xfwl4/target/release/xfwl4 "%{install-root}/usr/bin/"
