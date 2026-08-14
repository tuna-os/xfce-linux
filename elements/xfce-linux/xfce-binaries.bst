kind: import
description: >-
  Pre-built XFCE binaries from the hanthor/xfce-wayland monorepo.

  The binary tree was previously committed to git (issue #16) and is now
  fetched from the last commit that carried it. The extracted tree stays
  gitignored (files/xfce-binaries/) — do not re-commit it.

sources:
- kind: tar
  url: https://github.com/tuna-os/xfce-linux/archive/1351dffdda05b4ffab35d26a97b26c51d5841742.tar.gz
  ref: c74350827046803190430bfd07c414b016db8d5c96d18b847f94ed776cb4f944
  base-dir: xfce-linux-1351dffdda05b4ffab35d26a97b26c51d5841742/files/xfce-binaries/install
