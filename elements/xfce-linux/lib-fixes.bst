kind: script
description: Copy xfce libraries to lib64 for dynamic linker compatibility

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  build-commands: []
  install-commands:
    - |
      # Copy xfce4 libraries to both lib and lib64
      # This ensures they're found by the dynamic linker on 64-bit systems
      mkdir -p "%{install-root}/usr/lib64"
      
      # Create symlinks for xfce libraries in lib64
      for libname in libxfce4kbd-private-3 libxfce4util libxfce4ui-2 libxfconf-0; do
        # Point to /usr/lib versions
        ln -sf /usr/lib/${libname}.so "%{install-root}/usr/lib64/${libname}.so" 2>/dev/null || true
        ln -sf /usr/lib/${libname}.so.0 "%{install-root}/usr/lib64/${libname}.so.0" 2>/dev/null || true
        ln -sf /usr/lib/${libname}.so.0.0.0 "%{install-root}/usr/lib64/${libname}.so.0.0.0" 2>/dev/null || true
      done


