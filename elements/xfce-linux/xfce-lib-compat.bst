kind: autotools
description: Copy xfce libraries to x86_64-linux-gnu for multilib compatibility

depends:
  - xfce-linux/xfce-binaries.bst

config:
  configure-commands:
    - "true"
  
  build-commands:
    - |
      # Copy xfce binaries and libs from build
      cp -r /buildstream/usr /* /usr/ 2>/dev/null || true
  
  install-commands:
    - |
      # Copy everything to install root
      cp -r /buildstream/usr "%{install-root}/"
      
      # Copy xfce libraries to x86_64-linux-gnu subdirectory
      mkdir -p "%{install-root}/usr/lib/x86_64-linux-gnu"
      
      for lib in libxfce4kbd-private-3 libxfce4util libxfce4ui-2 libxfce4panel-2.0 \
                 libxfconf-0 libxfce4windowing-0 libxfce4windowingui-0; do
        # Copy all .so* files
        find "%{install-root}/usr/lib" -maxdepth 1 -name "${lib}.so*" | while read src; do
          basename=$(basename "$src")
          cp -P "$src" "%{install-root}/usr/lib/x86_64-linux-gnu/$basename" || true
        done
      done

