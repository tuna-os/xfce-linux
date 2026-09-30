# ── bootc helper ─────────────────────────────────────────────────────
[group('dev')]
bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v "{{base_dir}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:{{image_tag}}" bootc {{ARGS}}

# ── Generate bootable disk image ─────────────────────────────────────
[group('test')]
generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! sudo podman image exists "{{image_name}}:{{image_tag}}"; then
        echo "ERROR: Image '{{image_name}}:{{image_tag}}' not found in podman." >&2
        echo "Run 'just build' first to build and export the OCI image." >&2
        exit 1
    fi

    if [ ! -e "${base_dir}/bootable.raw" ] ; then
        echo "==> Creating 30G sparse disk image..."
        fallocate -l 30G "${base_dir}/bootable.raw"
    fi

    echo "==> Installing OS to disk image via bootc..."
    BUILD_IMAGE_NAME="{{image_name}}" just bootc install to-disk \
        --via-loopback /data/bootable.raw \
        --filesystem "${filesystem}" \
        --wipe \
        --composefs-backend \
        --bootloader systemd \
        --karg systemd.firstboot=no \
        --karg splash \
        --karg quiet \
        --karg console=tty0 \
        --karg console=ttyS0 \
        --karg systemd.debug_shell=ttyS1

    echo "==> Bootable disk image ready: ${base_dir}/bootable.raw"
    sync

    # Remove stale qcow2 so boot-vm uses the fresh raw image
    rm -f "${base_dir}/bootable.qcow2"

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
