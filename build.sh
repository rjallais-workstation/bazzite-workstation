#!/usr/bin/env bash
# build.sh — Main image build script for bazzite-workstation
set -euo pipefail

###############################################################################
# 1. Install system files (sysusers, tmpfiles, etc.)
###############################################################################
echo "=== Installing system files ==="
install -Dm644 /ctx/system_files/usr/lib/sysusers.d/docker.conf /usr/lib/sysusers.d/docker.conf
install -Dm644 /ctx/system_files/usr/lib/tmpfiles.d/bazzite-workstation.conf /usr/lib/tmpfiles.d/bazzite-workstation.conf

###############################################################################
# 2. Add extra repositories & install workstation packages
###############################################################################
echo "=== Configuring repositories & packages ==="
# Enable psygreg/linuxtoys COPR
FEDORA_VERSION=$(rpm -E %fedora)
curl -fsSL "https://copr.fedorainfracloud.org/coprs/psygreg/linuxtoys/repo/fedora-${FEDORA_VERSION}/psygreg-linuxtoys-fedora-${FEDORA_VERSION}.repo" -o /etc/yum.repos.d/psygreg-linuxtoys.repo

# Define workstation packages (excluding C/C++ developer tools like gcc, cmake, meson, ninja, valgrind etc.)
PACKAGES=(
    # Bluefin packages
    adcli bcache-tools cryfs davfs2 foo2zjs fuse-encfs
    git-credential-libsecret gnome-tweaks ifuse igt-gpu-tools
    krb5-workstation libgda libgda-sqlite libsss_autofs
    oddjob-mkhomedir osbuild-selinux powertop python3-pygit2
    samba setools-console sssd-ad sssd-krb5 waypipe wireguard-tools
    
    # Developer utility packages (no C/C++ toolchains)
    android-tools bcc bpftop bpftrace flatpak-builder
    genisoimage git-subtree git-svn iotop nicstat nu
    numactl podman-compose podman-tui sysprof tiptop
    trace-cmd ugrep util-linux-script
    
    # Fonts
    cascadia-code-fonts jetbrains-mono-fonts-all opendyslexic-fonts
    
    # Virtualization
    cockpit-machines cockpit-ostree incus incus-agent
    incus-client incus-selinux libvirt-daemon-kvm libvirt-dbus
    libvirt-glib libvirt-nss libvirt-ssh-proxy podman-machine
    qemu-user-binfmt qemu-user-static virt-manager virt-v2v virt-viewer
    
    # Extra utility
    starship
)

dnf -y install "${PACKAGES[@]}"

###############################################################################
# 3. Install NetBird
###############################################################################
echo "=== Installing NetBird ==="
NETBIRD_VERSION=$(curl -fsSL "https://api.github.com/repos/netbirdio/netbird/releases/latest" | grep -oP '"tag_name": "\K[^"]+' | sed 's/^v//')
ARCH=$(uname -m)
if [ "${ARCH}" = "x86_64" ]; then
    NETBIRD_ARCH="amd64"
else
    NETBIRD_ARCH="${ARCH}"
fi
tarball_url="https://github.com/netbirdio/netbird/releases/download/v${NETBIRD_VERSION}/netbird_${NETBIRD_VERSION}_linux_${NETBIRD_ARCH}.tar.gz"
curl -fsSL "${tarball_url}" | tar xz -C /tmp
install -Dm755 /tmp/netbird /usr/bin/netbird
rm -f /tmp/netbird

cat > /usr/lib/systemd/system/netbird.service << 'EOF'
[Unit]
Description=NetBird WireGuard Client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/netbird service run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

###############################################################################
# 4. Install xonedo kernel module (Xbox Wireless Dongle driver)
###############################################################################
echo "=== Installing xonedo kernel module ==="
KERNEL_VERSION=$(uname -r)
KERNEL_SRC="/usr/src/kernels/${KERNEL_VERSION}"
DKMS_SRC="/usr/src/xonedo"

# Clone xonedo
git clone --depth=1 https://github.com/OpenGamingCollective/xonedo.git /tmp/xonedo
XONEDO_VERSION=$(cd /tmp/xonedo && git describe --tags 2>/dev/null || echo "0.0.0")
XONEDO_VERSION="${XONEDO_VERSION##v}"
echo "xonedo version: ${XONEDO_VERSION}"

# Prepare DKMS source
mkdir -p "${DKMS_SRC}-${XONEDO_VERSION}"
cp -r /tmp/xonedo/* "${DKMS_SRC}-${XONEDO_VERSION}/"

# Replace version placeholder in dkms.conf and source files
find "${DKMS_SRC}-${XONEDO_VERSION}" -type f \( -name dkms.conf -o -name '*.c' \) \
    -exec sed -i "s/#VERSION#/${XONEDO_VERSION}/" {} +

# Build and install modules
cd "${DKMS_SRC}-${XONEDO_VERSION}"
make -C "${KERNEL_SRC}" M="${PWD}" modules
mkdir -p "/lib/modules/${KERNEL_VERSION}/extra"
cp *.ko "/lib/modules/${KERNEL_VERSION}/extra/"
depmod -a "${KERNEL_VERSION}"

# Install firmware (xow_dongle.bin)
install -Dm644 /tmp/xonedo/firmware/xow_dongle.bin /lib/firmware/xow_dongle.bin 2>/dev/null || true

# Blacklist mt76x2u to avoid conflicts
cat > /etc/modprobe.d/xone-blacklist.conf << 'EOF'
# Blacklist mt76x2u to avoid conflicts with xone/xonedo
blacklist mt76x2u
EOF

# Cleanup build artifacts
rm -rf /tmp/xonedo "${DKMS_SRC}-${XONEDO_VERSION}"

echo "=== xonedo installation complete ==="

###############################################################################
# 5. Install Docker CE (if not already present)
###############################################################################
if ! command -v docker &>/dev/null; then
    echo "=== Installing Docker CE ==="
    dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sed -i 's/enabled=.*/enabled=0/g' /etc/yum.repos.d/docker-ce.repo
    dnf -y install --enablerepo=docker-ce-stable \
        containerd.io \
        docker-buildx-plugin \
        docker-ce \
        docker-ce-cli \
        docker-compose-plugin \
        docker-model-plugin
fi

###############################################################################
# 6. Enable systemd services
###############################################################################
for svc in docker.socket podman.socket netbird.service; do
    systemctl enable "$svc" 2>/dev/null || true
done

###############################################################################
# 7. Starship prompt in profile.d
###############################################################################
cat > /etc/profile.d/starship.sh << 'EOF'
if [ "$(command -v starship)" ]; then
    eval "$(starship init bash)"
fi
EOF

###############################################################################
# 8. Clean runtime artifacts
###############################################################################
find /run -mindepth 1 -maxdepth 1 ! -name .containerenv ! -name secrets ! -name systemd ! -name mount -exec rm -rf '{}' '+' 2>/dev/null || true
find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf '{}' '+' 2>/dev/null || true
rm -f /var/log/dnf5.log
rm -rf /var/roothome/.local

# Unmount build-time mounts
for p in /run/systemd/resolve /run/systemd /run/mount; do
    if mountpoint -q "$p" 2>/dev/null; then
        umount -l "$p" 2>/dev/null || true
    fi
done
for p in /run/systemd/resolve /run/systemd /run/mount; do
    if ! findmnt -Rno TARGET "$p" &>/dev/null; then
        rm -rf "$p" 2>/dev/null || true
    fi
done

find /run -mindepth 1 -type d -empty ! -name .containerenv ! -name secrets -delete 2>/dev/null || true
rm -f /etc/resolv.conf
ln -s ../usr/lib/systemd/resolv.conf /etc/resolv.conf
rm -rf /run/systemd/resolve /run/systemd /run/mount 2>/dev/null || true
find /run -mindepth 1 -maxdepth 1 ! -name .containerenv ! -name secrets -exec rm -rf '{}' '+' 2>/dev/null || true
find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf '{}' '+' 2>/dev/null || true

echo "=== Build complete ==="

