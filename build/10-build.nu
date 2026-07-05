# build/10-build.nu — Main image build script in Nushell

def main [] {
    ###############################################################################
    # 1. Install system files and runtime manifests
    ###############################################################################
    print "=== Installing system files and runtime manifests ==="
    mkdir "/usr/lib/sysusers.d"
    mkdir "/usr/lib/tmpfiles.d"
    ^install -Dm644 /ctx/system_files/usr/lib/sysusers.d/docker.conf /usr/lib/sysusers.d/docker.conf
    ^install -Dm644 /ctx/system_files/usr/lib/tmpfiles.d/bazzite-workstation.conf /usr/lib/tmpfiles.d/bazzite-workstation.conf

    mkdir "/usr/share/ublue-os/homebrew"
    for brewfile in (glob "/ctx/custom/brew/*.Brewfile") {
        cp $brewfile "/usr/share/ublue-os/homebrew/"
    }

    mkdir "/usr/share/flatpak/preinstall.d"
    for flatpak_file in (glob "/ctx/custom/flatpaks/*.preinstall") {
        cp $flatpak_file "/usr/share/flatpak/preinstall.d/"
    }

    mkdir "/usr/share/ublue-os/just"
    let custom_just = "/usr/share/ublue-os/just/60-custom.just"
    if not ($custom_just | path exists) {
        "" | save -f $custom_just
    }
    for just_file in (glob "/ctx/custom/ujust/*.just") {
        "\n\n" | save --append $custom_just
        (open $just_file | into string) | save --append $custom_just
    }

    ###############################################################################
    # 2. Add extra repositories & install workstation packages
    ###############################################################################
    print "=== Configuring repositories & packages ==="
    # Enable psygreg/linuxtoys COPR
    let fedora_version = (^rpm -E %fedora | str trim)
    let copr_url = $"https://copr.fedorainfracloud.org/coprs/psygreg/linuxtoys/repo/fedora-($fedora_version)/psygreg-linuxtoys-fedora-($fedora_version).repo"
    (http get $copr_url) | save -f /etc/yum.repos.d/psygreg-linuxtoys.repo

    # Define workstation packages (excluding C/C++ developer tools like gcc, cmake, meson, ninja, valgrind etc.)
    let packages = [
        # Bluefin packages
        "adcli" "bcache-tools" "cryfs" "davfs2" "foo2zjs" "fuse-encfs"
        "git-credential-libsecret" "gnome-tweaks" "ifuse" "igt-gpu-tools"
        "krb5-workstation" "libgda" "libgda-sqlite" "libsss_autofs"
        "oddjob-mkhomedir" "osbuild-selinux" "powertop" "python3-pygit2"
        "samba" "setools-console" "sssd-ad" "sssd-krb5" "waypipe" "wireguard-tools"

        # Developer utility packages (no C/C++ toolchains)
        "android-tools" "bcc" "bpftop" "bpftrace" "flatpak-builder"
        "genisoimage" "git-subtree" "git-svn" "iotop" "nicstat" "nu"
        "numactl" "podman-compose" "podman-tui" "sysprof" "tiptop"
        "trace-cmd" "ugrep" "util-linux-script"

        # Fonts
        "cascadia-code-fonts" "jetbrains-mono-fonts-all" "opendyslexic-fonts"

        # Virtualization
        "cockpit-machines" "cockpit-ostree" "incus" "incus-agent"
        "incus-client" "incus-selinux" "libvirt-daemon-kvm" "libvirt-dbus"
        "libvirt-glib" "libvirt-nss" "libvirt-ssh-proxy" "podman-machine"
        "qemu-user-binfmt" "qemu-user-static" "virt-manager" "virt-v2v" "virt-viewer"

        # Extra utility
        "fastfetch" "dconf-editor" "htop"
    ]

    ^dnf5 -y install ...$packages

    ###############################################################################
    # 3. Install Starship
    ###############################################################################
    print "=== Installing Starship ==="
    let starship_release = (http get "https://api.github.com/repos/starship/starship/releases/latest")
    let starship_version = ($starship_release.tag_name | str replace "v" "")
    let arch = (^uname -m | str trim)
    let starship_arch = if $arch == "x86_64" { "x86_64" } else if $arch == "aarch64" { "aarch64" } else { $arch }

    let starship_tarball_url = $"https://github.com/starship/starship/releases/download/v($starship_version)/starship-($starship_arch)-unknown-linux-musl.tar.gz"

    http get $starship_tarball_url | save -f /tmp/starship.tar.gz
    mkdir /tmp/starship_extracted
    ^tar xz -C /tmp/starship_extracted -f /tmp/starship.tar.gz
    ^install -Dm755 /tmp/starship_extracted/starship /usr/bin/starship
    rm -rf /tmp/starship.tar.gz /tmp/starship_extracted

    ###############################################################################
    # 4. Install NetBird
    ###############################################################################
    print "=== Installing NetBird ==="
    let release = (http get "https://api.github.com/repos/netbirdio/netbird/releases/latest")
    let netbird_version = ($release.tag_name | str replace "v" "")
    let arch = (^uname -m | str trim)
    let netbird_arch = if $arch == "x86_64" { "amd64" } else { $arch }

    let tarball_url = $"https://github.com/netbirdio/netbird/releases/download/v($netbird_version)/netbird_($netbird_version)_linux_($netbird_arch).tar.gz"

    # Download and extract
    http get $tarball_url | save -f /tmp/netbird.tar.gz
    mkdir /tmp/netbird_extracted
    ^tar xz -C /tmp/netbird_extracted -f /tmp/netbird.tar.gz
    ^install -Dm755 /tmp/netbird_extracted/netbird /usr/bin/netbird
    rm -rf /tmp/netbird.tar.gz /tmp/netbird_extracted

    let netbird_service = "
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
"
    $netbird_service | save -f /usr/lib/systemd/system/netbird.service

    ###############################################################################
    # 4. Install xonedo kernel module (Xbox Wireless Dongle driver)
    ###############################################################################
    print "=== Installing xonedo kernel module ==="
    let kernel_version = (^uname -r | str trim)
    let kernel_src = $"/usr/src/kernels/($kernel_version)"
    let dkms_src = "/usr/src/xonedo"

    if not ($kernel_src | path exists) {
        print $"Kernel headers not found at ($kernel_src); skipping xonedo kernel module build."
    } else {
        # Clone xonedo
        ^git clone --depth=1 "https://github.com/OpenGamingCollective/xonedo.git" "/tmp/xonedo"
        let xonedo_describe = (^git describe --tags | complete)
        let xonedo_version = if $xonedo_describe.exit_code == 0 {
            ($xonedo_describe.stdout | str trim | str replace -a "v" "")
        } else {
            "0.0.0"
        }
        print $"xonedo version: ($xonedo_version)"

        # Prepare DKMS source
        let dkms_dest = $"($dkms_src)-($xonedo_version)"
        mkdir $dkms_dest
        for entry in (glob "/tmp/xonedo/*") {
            cp -r $entry $dkms_dest
        }

        # Replace version placeholder in dkms.conf and source files
        let files_to_replace = ((glob $"($dkms_dest)/**/dkms.conf") | append (glob $"($dkms_dest)/**/*.c"))
        for f in $files_to_replace {
            let content = (open $f | into string | str replace -a "#VERSION#" $xonedo_version)
            $content | save -f $f
        }

        # Build and install modules
        cd $dkms_dest
        ^make -C $kernel_src $"M=($env.PWD)" modules
        mkdir $"/lib/modules/($kernel_version)/extra"
        cp *.ko $"/lib/modules/($kernel_version)/extra/"
        ^depmod -a $kernel_version

        # Install firmware (xow_dongle.bin)
        let firmware_src = "/tmp/xonedo/firmware/xow_dongle.bin"
        if ($firmware_src | path exists) {
            mkdir "/lib/firmware"
            cp $firmware_src "/lib/firmware/xow_dongle.bin"
        }

        # Blacklist mt76x2u to avoid conflicts
        let blacklist_content = "
# Blacklist mt76x2u to avoid conflicts with xone/xonedo
blacklist mt76x2u
"
        mkdir "/etc/modprobe.d"
        $blacklist_content | save -f "/etc/modprobe.d/xone-blacklist.conf"

        # Cleanup build artifacts
        cd "/"
        rm -rf /tmp/xonedo $dkms_dest
        print "=== xonedo installation complete ==="
    }

    ###############################################################################
    # 5. Install Docker CE (if not already present)
    ###############################################################################
    if not (try { which docker | is-not-empty } catch { false }) {
        print "=== Installing Docker CE ==="
        http get "https://download.docker.com/linux/fedora/docker-ce.repo" | save -f "/etc/yum.repos.d/docker-ce.repo"
        let repo_content = (open "/etc/yum.repos.d/docker-ce.repo" | into string | str replace -a "enabled=1" "enabled=0")
        $repo_content | save -f "/etc/yum.repos.d/docker-ce.repo"

        ^dnf5 -y install --enablerepo=docker-ce-stable "containerd.io" "docker-buildx-plugin" "docker-ce" "docker-ce-cli" "docker-compose-plugin" "docker-model-plugin"
    }

    ###############################################################################
    # 6. Enable systemd services
    ###############################################################################
    print "=== Enabling systemd services ==="
    for svc in ["docker.socket" "podman.socket" "netbird.service"] {
        do -i { ^systemctl enable $svc }
    }

    ###############################################################################
    # 7. Starship prompt in profile.d
    ###############################################################################
    print "=== Configuring Starship prompt ==="
    let starship_profile = "
if [ \"$(command -v starship)\" ]; then
    eval \"$(starship init bash)\"
fi
"
    mkdir "/etc/profile.d"
    $starship_profile | save -f "/etc/profile.d/starship.sh"

    ###############################################################################
    # 8. Clean runtime artifacts
    ###############################################################################
    print "=== Cleaning runtime artifacts ==="
    do -i { rm -f /var/log/dnf5.log }
    do -i { rm -rf /var/roothome/.local }

    print "=== Build complete ==="
}
