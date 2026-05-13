kind: autotools
description: Create symlinks for xfce libraries in lib64

depends:
  - xfce-linux/xfce-binaries.bst
  - freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

config:
  configure-commands:
    - "true"
  
  build-commands:
    - "true"
  
  install-commands:
    - |
      # Create symlinks for xfce libraries in lib64
      mkdir -p "%{install-root}/usr/lib64"
      
      for libname in libxfce4kbd-private-3 libxfce4util libxfce4ui-2 libxfconf-0; do
        # Create symlinks to /usr/lib versions
        ln -sf /usr/lib/${libname}.so "%{install-root}/usr/lib64/${libname}.so" 2>/dev/null || true
        ln -sf /usr/lib/${libname}.so.0 "%{install-root}/usr/lib64/${libname}.so.0" 2>/dev/null || true  
        ln -sf /usr/lib/${libname}.so.0.0.0 "%{install-root}/usr/lib64/${libname}.so.0.0.0" 2>/dev/null || true
      done





