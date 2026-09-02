# ── Boot VM ──────────────────────────────────────────────────────────
# Boot the raw disk image.
# If qemu-system-x86_64 is installed, runs natively (UEFI/OVMF).
# Otherwise, falls back to running via docker.io/qemux/qemu-docker.
[group('test')]
boot-vm $base_dir=base_dir:
    #!/usr/bin/env bash
    set -euo pipefail

    # Resolve absolute path for Docker volume mount
    DISK=$(realpath "{{base_dir}}/bootable.raw")
    if [ ! -e "$DISK" ]; then
        echo "ERROR: ${DISK} not found. Run 'just generate-bootable-image' first." >&2
        exit 1
    fi

    # Check for native QEMU
    if command -v qemu-system-x86_64 &>/dev/null; then
        echo "==> Using native qemu-system-x86_64..."

        # Auto-detect OVMF firmware paths
        OVMF_CODE=""
        for candidate in \
            /usr/share/edk2/ovmf/OVMF_CODE.fd \
            /usr/share/OVMF/OVMF_CODE.fd \
            /usr/share/OVMF/OVMF_CODE_4M.fd \
            /usr/share/edk2/x64/OVMF_CODE.4m.fd \
            /usr/share/qemu/OVMF_CODE.fd; do
            if [ -f "$candidate" ]; then
                OVMF_CODE="$candidate"
                break
            fi
        done
        if [ -z "$OVMF_CODE" ]; then
            echo "ERROR: OVMF firmware not found. Install edk2-ovmf (Fedora) or ovmf (Debian/Ubuntu)." >&2
            exit 1
        fi

        # OVMF_VARS must be writable -- use a local copy
        OVMF_VARS="{{base_dir}}/.ovmf-vars.fd"
        if [ ! -e "$OVMF_VARS" ]; then
            OVMF_VARS_SRC=""
            for candidate in \
                /usr/share/edk2/ovmf/OVMF_VARS.fd \
                /usr/share/OVMF/OVMF_VARS.fd \
                /usr/share/OVMF/OVMF_VARS_4M.fd \
                /usr/share/edk2/x64/OVMF_VARS.4m.fd \
                /usr/share/qemu/OVMF_VARS.fd; do
                if [ -f "$candidate" ]; then
                    OVMF_VARS_SRC="$candidate"
                    break
                fi
            done
            if [ -z "$OVMF_VARS_SRC" ]; then
                echo "ERROR: OVMF_VARS not found alongside OVMF_CODE." >&2
                exit 1
            fi
            cp "$OVMF_VARS_SRC" "$OVMF_VARS"
        fi

        echo "==> Booting ${DISK} in QEMU (UEFI, KVM)..."
        echo "    Firmware: ${OVMF_CODE}"
        echo "    RAM: {{vm_ram}}M, CPUs: {{vm_cpus}}"
        echo "    Serial debug shell on ttyS1 available via QEMU monitor"
        echo ""

        qemu-system-x86_64 \
            -enable-kvm \
            -m "{{vm_ram}}" \
            -cpu host \
            -smp "{{vm_cpus}}" \
            -drive file="${DISK}",format=raw,if=virtio \
            -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
            -drive if=pflash,format=raw,file="${OVMF_VARS}" \
            -device virtio-gpu-pci \
            -display egl-headless,rendernode=/dev/dri/renderD128 \
            -vnc 127.0.0.1:1 \
            -device virtio-keyboard \
            -device virtio-mouse \
            -device virtio-net-pci,netdev=net0 \
            -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2223-:22 \
            -serial telnet:127.0.0.1:4445,server,nowait \
            -serial telnet:127.0.0.1:4447,server,nowait \
            -monitor unix:./qemu-monitor.sock,server,nowait \
            -daemonize -pidfile /tmp/xfce-linux-vm.pid






    else
        echo "==> qemu-system-x86_64 not found, falling back to docker.io/qemux/qemu-docker..."

        # Check for qcow2 image, prefer it if exists
        BOOT_MOUNT="/boot.img"
        if [ -e "{{base_dir}}/bootable.qcow2" ]; then
            DISK=$(realpath "{{base_dir}}/bootable.qcow2")
            BOOT_MOUNT="/boot.qcow2"
        fi

        # Determine which port to use
        port=8006
        while grep -q :${port} <<< $(ss -tunalp); do
            port=$(( port + 1 ))
        done
        echo "==> Web/VNC accessible at http://localhost:${port}"

        # Try to open browser
        xdg-open "http://localhost:${port}" &>/dev/null || true

        # Run via podman
        podman run \
            --rm --privileged \
            --device /dev/kvm \
            --pull=always \
            --publish "127.0.0.1:${port}:8006" \
            --publish "127.0.0.1:2222:22" \
            --env "USER_PORTS=22" \
            --env "NETWORK=user" \
            --env "CPU_CORES={{vm_cpus}}" \
            --env "RAM_SIZE={{vm_ram}}" \
            --env "TPM=y" \
            --env "BOOT_MODE=${BOOT_MODE:-uefi}" \
            --env "ARGUMENTS=-snapshot" \
            --volume "${DISK}:${BOOT_MOUNT}" \
            ghcr.io/qemus/qemu:latest
    fi

# ── Boot in libvirt ──────────────────────────────────────────────────
[group('test')]
boot-libvirt name="xfce-linux" ram="8192" cpus="4":
    #!/usr/bin/env bash
    set -euo pipefail

    DISK=$(realpath "{{base_dir}}/bootable.qcow2")
    FORMAT="qcow2"
    if [ ! -e "$DISK" ]; then
        DISK=$(realpath "{{base_dir}}/bootable.raw")
        FORMAT="raw"
    fi

    if [ ! -e "$DISK" ]; then
        echo "Error: Disk image not found. Run 'just generate-bootable-image' first."
        exit 1
    fi

    # Destroy and undefine existing VM if it exists
    sudo virsh destroy "{{name}}" 2>/dev/null || true
    sudo virsh undefine "{{name}}" --nvram 2>/dev/null || true

    NVRAM_DST="/var/lib/libvirt/qemu/nvram/{{name}}_VARS.fd"
    sudo cp /usr/share/edk2/ovmf/OVMF_VARS.fd "${NVRAM_DST}"

    echo "==> Creating libvirt domain '{{name}}' (format: ${FORMAT})..."
    TMPL="{{justfile_directory()}}/files/vm/domain-template.xml"
    XML=$(mktemp --suffix=.xml)
    sed \
        -e "s|VM_NAME|{{name}}|g" \
        -e "s|VM_RAM|{{ram}}|g" \
        -e "s|VM_CPUS|{{cpus}}|g" \
        -e "s|VM_FORMAT|${FORMAT}|g" \
        -e "s|VM_DISK|${DISK}|g" \
        -e "s|NVRAM_DST|${NVRAM_DST}|g" \
        "${TMPL}" > "${XML}"
    sudo virsh define "${XML}"
    rm -f "${XML}"
    sudo virsh start "{{name}}"

    echo "==> VM '{{name}}' started (qemu:///system)."
    echo "==> Connect with: virt-viewer {{name}}"
    echo "==> or open Virtual Machine Manager (virt-manager)."
    echo "==> VNC: $(sudo virsh vncdisplay {{name}} 2>/dev/null || echo 'check virt-manager')"

# ── Get VM IP address ─────────────────────────────────────────────────
[group('test')]
vm-ip name="xfce-linux":
    sudo virsh -c qemu:///system domifaddr "{{name}}" \
        | awk '/ipv4/{gsub(/\/[0-9]+/,"",$4); print $4; exit}'

# ── SSH into the VM ───────────────────────────────────────────────────
[group('test')]
ssh name="xfce-linux":
    #!/usr/bin/env bash
    set -euo pipefail
    IP=$(just vm-ip "{{name}}")
    if [ -z "$IP" ]; then
        echo "ERROR: could not get IP for '{{name}}'. Is the VM running?" >&2
        exit 1
    fi
    echo "==> SSH to root@${IP}"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@${IP}"

# ── Collect crash logs from VM console ───────────────────────────────
[group('test')]
logs name="xfce-linux":
    /home/linuxbrew/.linuxbrew/bin/python3 {{justfile_directory()}}/scripts/vm-logs "{{name}}"

# ── Boot VM and collect logs in one shot ─────────────────────────────
[group('test')]
test name="xfce-linux":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Starting VM '{{name}}'..."
    sudo virsh -c qemu:///system start "{{name}}" 2>/dev/null || true
    echo "==> Waiting 45s for boot..."
    sleep 45
    just logs "{{name}}"

# ── Convert to qcow2 ──────────────────────────────────────────────────
[group('test')]
convert-to-qcow2 $base_dir=base_dir:
    #!/usr/bin/env bash
    set -euo pipefail

    RAW="{{base_dir}}/bootable.raw"
    QCOW2="{{base_dir}}/bootable.qcow2"

    if [ ! -e "$RAW" ]; then
        echo "ERROR: ${RAW} not found. Run 'just generate-bootable-image' first." >&2
        exit 1
    fi

    echo "==> Converting ${RAW} to ${QCOW2}..."

    if command -v qemu-img &>/dev/null; then
        qemu-img convert -f raw -O qcow2 "$RAW" "$QCOW2"
    else
        echo "    Using containerized qemu-img..."
        podman run --rm \
            -v "{{base_dir}}:/data" \
            --entrypoint qemu-img \
            ghcr.io/qemus/qemu:latest \
            convert -f raw -O qcow2 "/data/bootable.raw" "/data/bootable.qcow2"
    fi
    echo "==> Conversion complete: ${QCOW2}"
