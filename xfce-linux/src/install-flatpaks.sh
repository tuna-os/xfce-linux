#!/usr/bin/bash
# Pre-install flatpaks into the live squashfs.
#
# Uses --mount=type=cache,target=/var/cache/flatpak-dl to persist the flatpak
# ostree repo across builds.  On each run the script:
#   1. Seeds /var/lib/flatpak/repo from the build cache (warm start)
#   2. Reconciles to match /tmp/flatpaks-list (only deltas downloaded)
#   3. Saves the repo back to the cache for next build
#
# /tmp/flatpaks-list is COPYd by the Containerfile so it's always current.
# Requires network at build time; CAP_SYS_ADMIN for dbus.

set -exo pipefail

FLATPAK_CACHE="/var/cache/flatpak-dl"

# overlayfs inside Podman builds doesn't support O_TMPFILE.  /dev/shm would
# work but is only ~3.5 GB on GHA 7-GB runners — too small for GNOME Platform.
# The --mount=type=cache volume is a bind-mount from btrfs (supports O_TMPFILE)
# and has ~60 GB free, so use a subdirectory of it as TMPDIR instead.
mkdir -p "${FLATPAK_CACHE}/tmp"
export TMPDIR="${FLATPAK_CACHE}/tmp"
# The image leaves /etc/machine-id empty or "uninitialized"; systemd fills it
# on first boot.
# Without a valid ID, dbus and flatpak's GDBus refuse to start a bus
# ("Cannot spawn a message bus without a machine-id"), and the installer
# install fails. Use a throwaway ID for this build step only, then put the
# file back exactly as it was so every installed system still gets its own.
MACHINE_ID_STATE=absent
if [ -e /etc/machine-id ]; then
    MACHINE_ID_STATE=present
    cp -a /etc/machine-id /tmp/machine-id.orig
fi
restore_machine_id() {
    if [ "$MACHINE_ID_STATE" = present ]; then
        cp -a /tmp/machine-id.orig /etc/machine-id || true
    else
        rm -f /etc/machine-id || true
    fi
    rm -f /tmp/machine-id.orig || true
}
trap restore_machine_id EXIT
if ! grep -qxE '[0-9a-f]{32}' /etc/machine-id 2>/dev/null; then
    rm -f /etc/machine-id
    tr -d '-' < /proc/sys/kernel/random/uuid > /etc/machine-id
fi

mkdir -p /run/dbus
dbus-daemon --system --fork --nopidfile
# Flatpak pulls from the tuna-os OCI remote through flatpak-oci-authenticator,
# a D-Bus service on the session bus. With no session bus, GDBus tries X11
# autolaunch and fails: "Cannot autolaunch D-Bus without X11 $DISPLAY".
# The address goes through a file, not $(...): the forked daemon keeps the
# command substitution's pipe open, so $(...) would never return.
dbus-daemon --session --fork --nopidfile --print-address=3 3>/tmp/session-bus-address
DBUS_SESSION_BUS_ADDRESS="$(head -n1 /tmp/session-bus-address)"
export DBUS_SESSION_BUS_ADDRESS
rm -f /tmp/session-bus-address
sleep 1

# ── Seed flatpak repo from build cache (warm start) ──────────────────────────
if [ -d "${FLATPAK_CACHE}/repo/refs" ]; then
    echo "Seeding flatpak repo from build cache..."
    rsync -a --ignore-existing "${FLATPAK_CACHE}/repo/" /var/lib/flatpak/repo/ || true
    echo "Cache seed complete"
fi

flatpak remote-add --system --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

# TunaOS XFCE installer frontend (fisherman backend bundled at /app/bin/fisherman).
# Published on the tuna-os OCI flatpak remote; see INSTALLER-FRONTENDS.md.
# INSTALLER_CHANNEL is accepted for CLI compat but both channels currently
# resolve to the single master branch on the tuna-os remote.
flatpak remote-add --system --if-not-exists tuna-os \
    https://tunaos.org/flatpak/tuna-os.flatpakrepo

INSTALLER_APP_ID="org.tunaos.InstallerXfce"
flatpak install --system --noninteractive tuna-os "${INSTALLER_APP_ID}" || \
    flatpak update --system --noninteractive "${INSTALLER_APP_ID}"

flatpak override --system --filesystem=/etc:ro "${INSTALLER_APP_ID}"

# ── Reconcile Flathub apps against the wanted list ───────────────────────────
# In debug mode, skip the full Flathub app list to keep builds fast.
# NOTE: Disabled to allow debug ISOs with full flatpak suite + SSH access
# if [[ "${DEBUG:-0}" == "1" ]]; then
#     echo "DEBUG mode: skipping Flathub app list (installer-only ISO)"
#     # Still save cache for the installer runtime
#     echo "Saving flatpak repo to build cache..."
#     mkdir -p "${FLATPAK_CACHE}"
#     rsync -a --delete /var/lib/flatpak/repo/ "${FLATPAK_CACHE}/repo/"
#     exit 0
# fi

readarray -t WANTED < <(grep -v '^[[:space:]]*#' /tmp/flatpaks-list | grep -v '^[[:space:]]*$')

# Install or update everything in the list (--or-update = skip if current)
# --no-related skips locale packs and debug symbols (~3 GB uncompressed)
if [[ ${#WANTED[@]} -gt 0 ]]; then
    flatpak install --system --noninteractive --no-related --or-update flathub "${WANTED[@]}"
fi

# Remove any system app that is no longer in the wanted list
readarray -t INSTALLED < <(flatpak list --app --system --columns=application 2>/dev/null || true)
for app in "${INSTALLED[@]}"; do
    # Keep the installer regardless
    [[ "$app" == "org.tunaos.InstallerXfce" ]] && continue
    if [[ ! " ${WANTED[*]} " =~ ${app} ]]; then
        echo "Removing dropped flatpak: $app"
        flatpak uninstall --system --noninteractive "$app" || true
    fi
done

# Prune unused runtimes left behind by removals
flatpak uninstall --system --noninteractive --unused || true

# ── Save flatpak repo to build cache for next build ──────────────────────────
echo "Saving flatpak repo to build cache..."
mkdir -p "${FLATPAK_CACHE}"
rsync -a --delete /var/lib/flatpak/repo/ "${FLATPAK_CACHE}/repo/"
echo "Cache updated"
