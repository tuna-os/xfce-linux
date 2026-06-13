# Output directory for built ISOs and intermediate artifacts.
# Override with: just output_dir=/your/path iso-sd-boot xfce-linux
output_dir := "output"

# Set to 1 to enable SSH in the live session for debugging.
# Example: just debug=1 output_dir=/tmp/out iso-sd-boot xfce-linux
# Never use debug=1 for production/release ISOs.
debug := "0"

# Set to "dev" to pull the tuna-installer dev build (continuous-dev release).
# Example: just installer_channel=dev iso-sd-boot xfce-linux
installer_channel := "stable"

# LUKS passphrase used by luks-install for testing.
luks-passphrase := "testpassphrase"

# Squashfs compression preset:
#   fast    (default) — zstd level 3,  128K blocks — quick local builds/CI
#   release           — zstd level 15, 1M blocks   — ~20% smaller, ~5× slower
# Example: just compression=release iso-sd-boot xfce-linux
compression := "fast"

# Build the ISO in the background, detached from the terminal session.
# Logs are written to {{output_dir}}/build.log and tailed live.
# Usage: just build-bg xfce-linux
build-bg target:
    #!/usr/bin/bash
    set -euo pipefail
    mkdir -p {{output_dir}}
    LOG=$(realpath {{output_dir}})/build.log
    echo "Starting background build → ${LOG}"
    setsid sudo just \
        debug={{debug}} \
        installer_channel={{installer_channel}} \
        output_dir={{output_dir}} \
        compression={{compression}} \
        iso-sd-boot {{target}} \
        > "${LOG}" 2>&1 &
    disown $!
    echo "Build PID $! — tailing log (Ctrl-C is safe, build continues)"
    tail -f "${LOG}"

container target:
    #!/usr/bin/bash
    set -euo pipefail
    # Pre-squash base image to avoid disk explosion during multi-layer pulls
    BASE_IMAGE=$(grep '^ARG BASE_IMAGE=' ./{{target}}/Containerfile | cut -d= -f2)
    echo "Squashing base image: ${BASE_IMAGE}"
    SQUASH_CTR=$(sudo buildah from --pull-never "${BASE_IMAGE}" 2>/dev/null || sudo buildah from "${BASE_IMAGE}")
    sudo buildah commit --squash "${SQUASH_CTR}" oci-archive:/tmp/squashed-base.oci:"${BASE_IMAGE}"
    sudo podman load -i /tmp/squashed-base.oci
    rm -f /tmp/squashed-base.oci

    sudo podman build --cap-add sys_admin --security-opt label=disable \
        --layers \
        --build-arg BASE_IMAGE="${BASE_IMAGE}" \
        --build-arg DEBUG={{debug}} \
        --build-arg INSTALLER_CHANNEL={{installer_channel}} \
        -t {{target}}-installer ./{{target}}

# Build the Debian-based ISO assembly container for the given target.
iso-builder target:
    podman build --security-opt label=disable -t {{target}}-iso-builder \
        -f ./{{target}}/Containerfile.builder ./{{target}}

# Build a systemd-boot UEFI live ISO for the given target.
#
# Uses a two-container approach:
#   1. localhost/<target>-installer — the live environment (3-stage Containerfile)
#   2. localhost/<target>-iso-builder — Debian ISO assembly tools (Containerfile.builder)
#
# Output: output/<target>-live.iso
iso-sd-boot target:
    #!/usr/bin/bash
    set -euo pipefail

    # Read payload ref from file (defaults to localhost/<target>:latest if missing)
    PAYLOAD_REF="$(cat '{{target}}/payload_ref' 2>/dev/null | tr -d '[:space:]' || echo "localhost/{{target}}:latest")"

    just debug={{debug}} installer_channel={{installer_channel}} container {{target}}
    mkdir -p {{output_dir}}
    OUTPUT_DIR=$(realpath "{{output_dir}}")

    if [[ $(id -u) -eq 0 ]]; then
        _ns()    { bash -c "$1"; }
        _ns_rm() { rm -rf "$@"; }
    else
        _ns()    { podman unshare bash -c "$1"; }
        _ns_rm() { podman unshare rm -rf "$@"; }
    fi

    SQUASHFS="${OUTPUT_DIR}/{{target}}-rootfs.sfs"
    BOOT_TAR="${OUTPUT_DIR}/{{target}}-boot-files.tar"
    CS_STAGING="${OUTPUT_DIR}/{{target}}-cs-staging"
    SQUASHFS_ROOT="${OUTPUT_DIR}/{{target}}-sfs-root"
    trap "rm -f '${SQUASHFS}' '${BOOT_TAR}' '${OUTPUT_DIR}/{{target}}-payload.oci.tar'; _ns_rm '${CS_STAGING}' '${SQUASHFS_ROOT}' 2>/dev/null || true" EXIT
    echo "Building squashfs and boot tar from localhost/{{target}}-installer..."
    _ns "
        set -euo pipefail
        MOUNT=\$(podman image mount localhost/{{target}}-installer)
        PATH=/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:\$PATH

        PAYLOAD_OCI='${OUTPUT_DIR}/{{target}}-payload.oci.tar'
        CS_STAGING='${CS_STAGING}'
        SQUASHFS_ROOT='${SQUASHFS_ROOT}'
        SQUASHFS_STORAGE=\"\${CS_STAGING}/var/lib/containers/storage\"
        STORAGE_CONF=\"\$(mktemp '${OUTPUT_DIR}'/live-storage-XXXXXX.conf)\"
        mkdir -p \"\${SQUASHFS_STORAGE}\"
        printf '[storage]\ndriver = \"vfs\"\nrunroot = \"/tmp/cs-runroot\"\ngraphroot = \"/vfs-storage\"\n' \
            > \"\${STORAGE_CONF}\"

        echo 'Squashing xfce-linux image layers to reduce disk footprint...'
        SQUASH_CTR=\$(buildah from --pull-never \"${PAYLOAD_REF}\")
        buildah commit --squash \"\${SQUASH_CTR}\" oci-archive:\${PAYLOAD_OCI}:${PAYLOAD_REF}

        echo 'Importing xfce-linux OCI image into squashfs containers-storage...'
        podman run --rm \
            --privileged \
            -v \"\${PAYLOAD_OCI}:/payload.oci.tar:ro\" \
            -v \"\${SQUASHFS_STORAGE}:/vfs-storage\" \
            -v \"\${STORAGE_CONF}:/tmp/st.conf:ro\" \
            localhost/{{target}}-installer \
            sh -c 'mkdir -p /tmp/cs-runroot /var/tmp && CONTAINERS_STORAGE_CONF=/tmp/st.conf skopeo copy oci-archive:/payload.oci.tar:${PAYLOAD_REF} containers-storage:${PAYLOAD_REF}'

        rm -f \"\${PAYLOAD_OCI}\" \"\${STORAGE_CONF}\"

        echo 'Building unified squashfs source tree...'
        mkdir -p \"\${SQUASHFS_ROOT}\"
        cp -a --reflink=auto \"\${MOUNT}/.\" \"\${SQUASHFS_ROOT}/\" 2>/dev/null || \
            cp -a \"\${MOUNT}/.\" \"\${SQUASHFS_ROOT}/\"
        mkdir -p \"\${SQUASHFS_ROOT}/var/lib/containers/storage\"
        cp -a \"\${CS_STAGING}/var/lib/containers/storage/.\" \
            \"\${SQUASHFS_ROOT}/var/lib/containers/storage/\"
        rm -rf \"\${CS_STAGING}\"

        SFS_LEVEL=3; SFS_BLOCK=131072
        [[ '{{compression}}' == 'release' ]] && { SFS_LEVEL=15; SFS_BLOCK=1048576; }
        mksquashfs \"\${SQUASHFS_ROOT}\" '${SQUASHFS}' \
            -noappend -comp zstd -Xcompression-level \${SFS_LEVEL} -b \${SFS_BLOCK} \
            -processors 4 \
            -e proc -e sys -e dev -e run -e tmp

        rm -rf \"\${SQUASHFS_ROOT}\"

        tar -C \"\$MOUNT\" \
            -cf '${BOOT_TAR}' \
            ./usr/lib/modules \
            ./usr/lib/systemd/boot/efi
        podman image umount localhost/{{target}}-installer
    "

    TMPDIR="${OUTPUT_DIR}" \
    PATH="/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:${PATH}" \
        bash "{{target}}/src/build-iso.sh" "${BOOT_TAR}" "${SQUASHFS}" "${OUTPUT_DIR}/{{target}}-live.iso"

    echo "ISO ready: ${OUTPUT_DIR}/{{target}}-live.iso"

# Boot a built ISO in QEMU via UEFI (OVMF) with serial console output on stdout.
# Exit: Ctrl-A then X
boot-iso-serial target:
    #!/usr/bin/bash
    set -euo pipefail
    QEMU=$(command -v /usr/libexec/qemu-kvm /usr/bin/qemu-kvm \
               /usr/bin/qemu-system-x86_64 2>/dev/null | head -1)
    [[ -z "$QEMU" ]] && { echo "qemu-kvm / qemu-system-x86_64 not found" >&2; exit 1; }
    ISO=$(ls \
        {{output_dir}}/{{target}}-live.iso \
        2>/dev/null | head -1 || true)
    if [[ -z "$ISO" ]]; then
        echo "No ISO found for '{{target}}' — run: just iso-sd-boot {{target}}" >&2
        exit 1
    fi

    OVMF_CODE=""
    for f in \
        /usr/share/OVMF/OVMF_CODE.fd \
        /usr/share/edk2/ovmf/OVMF_CODE.fd \
        /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
        /usr/share/ovmf/OVMF.fd; do
        [[ -f "$f" ]] && { OVMF_CODE="$f"; break; }
    done
    OVMF_VARS_SRC=""
    for f in \
        /usr/share/OVMF/OVMF_VARS.fd \
        /usr/share/edk2/ovmf/OVMF_VARS.fd \
        /usr/share/edk2-ovmf/x64/OVMF_VARS.fd; do
        [[ -f "$f" ]] && { OVMF_VARS_SRC="$f"; break; }
    done
    if [[ -z "$OVMF_CODE" ]]; then
        echo "OVMF firmware not found — install edk2-ovmf or ovmf" >&2
        exit 1
    fi

    OVMF_VARS=$(mktemp /tmp/OVMF_VARS.XXXXXX.fd)
    [[ -n "$OVMF_VARS_SRC" ]] && cp "${OVMF_VARS_SRC}" "${OVMF_VARS}"
    trap "rm -f ${OVMF_VARS}" EXIT

    echo "Booting ${ISO} via UEFI — serial console below (Ctrl-A X to quit)"
    echo "SSH available on localhost:2222 (user: liveuser, password: live) if built with debug=1"
    sudo "$QEMU" \
        -machine q35 \
        -m 4096 \
        -accel kvm \
        -cpu host \
        -smp 4 \
        -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,format=raw,file="${OVMF_VARS}" \
        -drive if=none,id=live-disk,file="${ISO}",media=cdrom,format=raw,readonly=on \
        -device virtio-scsi-pci,id=scsi \
        -device scsi-cd,drive=live-disk \
        -net nic,model=virtio -net user,hostfwd=tcp::2222-:22 \
        -serial mon:stdio \
        -display none \
        -no-reboot

# Boot ISO with VNC display (for seeing the XFCE desktop)
boot-iso-vnc target:
    #!/usr/bin/bash
    set -euo pipefail
    QEMU=$(command -v /usr/libexec/qemu-kvm /usr/bin/qemu-kvm \
               /usr/bin/qemu-system-x86_64 2>/dev/null | head -1)
    [[ -z "$QEMU" ]] && { echo "qemu-kvm / qemu-system-x86_64 not found" >&2; exit 1; }
    ISO=$(ls {{output_dir}}/{{target}}-live.iso 2>/dev/null | head -1 || true)
    if [[ -z "$ISO" ]]; then
        echo "No ISO found — run: just iso-sd-boot {{target}}" >&2; exit 1
    fi

    OVMF_CODE=""
    for f in /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd \
              /usr/share/edk2-ovmf/x64/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd; do
        [[ -f "$f" ]] && { OVMF_CODE="$f"; break; }
    done
    OVMF_VARS=$(mktemp /tmp/OVMF_VARS.XXXXXX.fd)
    for f in /usr/share/OVMF/OVMF_VARS.fd /usr/share/edk2/ovmf/OVMF_VARS.fd \
              /usr/share/edk2-ovmf/x64/OVMF_VARS.fd; do
        [[ -f "$f" ]] && { cp "$f" "${OVMF_VARS}"; break; }
    done
    [[ -z "$OVMF_CODE" ]] && { echo "OVMF firmware not found" >&2; exit 1; }
    trap "rm -f ${OVMF_VARS}" EXIT

    echo "Booting ${ISO}"
    echo "  VNC:    vncviewer 127.0.0.1:5910  (display :10)"
    echo "  Serial: telnet 127.0.0.1 4445"
    echo "  SSH:    ssh -p 2222 liveuser@127.0.0.1  (debug=1 only)"
    sudo "$QEMU" \
        -machine q35 -cpu host -m 4096 -smp 4 -accel kvm \
        -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,format=raw,file="${OVMF_VARS}" \
        -drive if=none,id=live-disk,file="${ISO}",media=cdrom,format=raw,readonly=on \
        -device virtio-scsi-pci,id=scsi \
        -device scsi-cd,drive=live-disk \
        -device virtio-vga \
        -display vnc=127.0.0.1:10 \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
        -serial telnet:127.0.0.1:4445,server,nowait \
        -no-reboot
