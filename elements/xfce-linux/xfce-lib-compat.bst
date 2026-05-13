kind: autotools
description: Copy xfce libraries to x86_64-linux-gnu for multilib compatibility

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
      # Copy everything from xfce-binaries
      mkdir -p "%{install-root}"
      cp -r /buildstream/usr "%{install-root}/" || true
      
      # Ensure the directory exists
      mkdir -p "%{install-root}/usr/lib/x86_64-linux-gnu"
      
      # Copy xfce libraries to x86_64-linux-gnu subdirectory
      for lib in libxfce4kbd-private-3 libxfce4util libxfce4ui-2 libxfce4panel-2.0 \
                 libxfconf-0 libxfce4windowing-0 libxfce4windowingui-0; do
        if [ -f "/buildstream/usr/lib/${lib}.so.0.0.0" ]; then
          cp "/buildstream/usr/lib/${lib}.so.0.0.0" "%{install-root}/usr/lib/x86_64-linux-gnu/" 2>/dev/null || true
        fi
        if [ -f "/buildstream/usr/lib/${lib}.so.0" ]; then
          cp "/buildstream/usr/lib/${lib}.so.0" "%{install-root}/usr/lib/x86_64-linux-gnu/" 2>/dev/null || true
        fi
        if [ -f "/buildstream/usr/lib/${lib}.so" ]; then
          cp "/buildstream/usr/lib/${lib}.so" "%{install-root}/usr/lib/x86_64-linux-gnu/" 2>/dev/null || true
        fi
      done


