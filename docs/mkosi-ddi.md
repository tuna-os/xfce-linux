# Local Mkosi DDI (experimental)

XFCE Linux has an additional, experimental raw-GPT disk image built by Mkosi. It
is independent of the existing bootc `install to-disk` image and live ISO: those
paths and their release workflows remain unchanged. The DDI is assembled from
BuildStream's GNOME OS base and XFCE runtime stack through the single compose
target `elements/mkosi/xfce-linux-ddi.bst`; Mkosi's `Distribution=buildstream`
backend consumes that root tree and uses systemd-repart for the GPT layout.

The image ID and registry identity remain `xfce-linux`, and the staged
`/usr/lib/os-release` carries `ID=xfce-linux` and
`VERSION_CODENAME=brussels`. Brussels is a product codename, not a repository or
image rename. Both output paths consume `files/etc/os-release`: the OCI target
checks out `oci/os-release.bst` as a build input, and Mkosi overlays the same
file at `/usr/lib/os-release` through `ExtraTrees=`.

## Build locally

Install Mkosi 28~devel or newer, BuildStream (`bst`), systemd-repart, and the
normal BuildStream project dependencies. From the repository root run:

```sh
just mkosi-ddi
```

The raw image is written under `mkosi/ddi/mkosi.output/` as
`xfce-linux-ddi.raw`. To remove Mkosi's local outputs and caches, run
`just mkosi-ddi-clean`. This recipe only builds locally; it does not push,
sign, publish, or make a release.

The repart layout declares an EFI System Partition and an ext4 root partition.
The existing bootc `bootable.raw` is still generated separately by
`just generate-bootable-image` using `bootc install to-disk`; do not treat this
Mkosi DDI as having bootc deployment or update semantics.

## Validation status and limits

This DDI is experimental and local-only. It has not been built or booted as part
of this change. In particular, bootability depends on the GNOME OS/XFCE
BuildStream root tree providing a kernel and boot artifacts compatible with the
Mkosi systemd-boot and repart layout; EFI boot, device discovery, and desktop
startup remain to be validated on real output. The mkosi BuildStream backend
also requires a working `bst` executable and project/cache access in Mkosi's
build sandbox. The DDI must not be considered a supported installation or
upgrade path until those checks pass.
