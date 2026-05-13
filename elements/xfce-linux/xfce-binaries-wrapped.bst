kind: autotools
description: Wrap xfce-binaries and ensure lib64 symlinks are staged

depends:
  - xfce-linux/xfce-binaries.bst
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  configure-commands:
    - "true"
  
  build-commands:
    - "true"
  
  install-commands:
    - |
      # Copy everything from the build directory (xfce-binaries)
      cp -r /buildstream/* "%{install-root}/" 2>/dev/null || true
      
      # Ensure lib64 symlinks are in place
      mkdir -p "%{install-root}/usr/lib64"
      ln -sf /usr/lib/libxfce4kbd-private-3.so "%{install-root}/usr/lib64/libxfce4kbd-private-3.so"
      ln -sf /usr/lib/libxfce4kbd-private-3.so.0 "%{install-root}/usr/lib64/libxfce4kbd-private-3.so.0"
      ln -sf /usr/lib/libxfce4kbd-private-3.so.0.0.0 "%{install-root}/usr/lib64/libxfce4kbd-private-3.so.0.0.0"
      ln -sf /usr/lib/libxfce4ui-2.so "%{install-root}/usr/lib64/libxfce4ui-2.so"
      ln -sf /usr/lib/libxfce4ui-2.so.0 "%{install-root}/usr/lib64/libxfce4ui-2.so.0"
      ln -sf /usr/lib/libxfce4ui-2.so.0.0.0 "%{install-root}/usr/lib64/libxfce4ui-2.so.0.0.0"
      ln -sf /usr/lib/libxfce4util.so "%{install-root}/usr/lib64/libxfce4util.so"
      ln -sf /usr/lib/libxfce4util.so.7 "%{install-root}/usr/lib64/libxfce4util.so.7"
      ln -sf /usr/lib/libxfce4util.so.7.0.0 "%{install-root}/usr/lib64/libxfce4util.so.7.0.0"
      ln -sf /usr/lib/libxfce4panel-2.0.so "%{install-root}/usr/lib64/libxfce4panel-2.0.so"
      ln -sf /usr/lib/libxfce4panel-2.0.so.4 "%{install-root}/usr/lib64/libxfce4panel-2.0.so.4"
      ln -sf /usr/lib/libxfce4panel-2.0.so.4.0.0 "%{install-root}/usr/lib64/libxfce4panel-2.0.so.4.0.0"
      ln -sf /usr/lib/libxfce4windowing-0.so "%{install-root}/usr/lib64/libxfce4windowing-0.so"
      ln -sf /usr/lib/libxfce4windowing-0.so.0 "%{install-root}/usr/lib64/libxfce4windowing-0.so.0"
      ln -sf /usr/lib/libxfce4windowing-0.so.0.0.0 "%{install-root}/usr/lib64/libxfce4windowing-0.so.0.0.0"
      ln -sf /usr/lib/libxfce4windowingui-0.so "%{install-root}/usr/lib64/libxfce4windowingui-0.so"
      ln -sf /usr/lib/libxfce4windowingui-0.so.0 "%{install-root}/usr/lib64/libxfce4windowingui-0.so.0"
      ln -sf /usr/lib/libxfce4windowingui-0.so.0.0.0 "%{install-root}/usr/lib64/libxfce4windowingui-0.so.0.0.0"
