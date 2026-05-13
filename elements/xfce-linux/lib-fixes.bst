kind: manual
description: Fix library path issues for xfce-binaries

depends:
  - xfce-linux/xfce-binaries.bst

config:
  install-commands:
    - |
      # Copy xfce libraries from /usr/lib to /usr/lib64 for proper loading
      mkdir -p "%{install-root}/usr/lib64"
      
      # Copy xfce4-specific libraries that are missing from standard paths
      for lib in libxfce4kbd-private libxfce4util libxfce4ui libxfconf; do
        if [ -d "%{install-root}/usr/lib" ]; then
          find "%{install-root}/usr/lib" -name "${lib}*" -type f -o -name "${lib}*" -type l | while read f; do
            if [ -f "$f" ] || [ -L "$f" ]; then
              # Preserve relative paths
              rel_path="${f#%{install-root}/usr/lib/}"
              target_dir="%{install-root}/usr/lib64/$(dirname "$rel_path")"
              mkdir -p "$target_dir"
              cp -P "$f" "$target_dir/"
            fi
          done
        fi
      done
      
      # Ensure /usr/lib64 exists and is in the binary's search path
      mkdir -p "%{install-root}/usr/lib64"
