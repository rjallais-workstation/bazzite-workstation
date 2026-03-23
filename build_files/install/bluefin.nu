#!/usr/bin/env nu
#MISE description="Install: Bluefin modular components (just recipes, Brewfiles, profile.d)"
def copy_if_dir_exists [sources: list<string>, destination: string] {
    for dir in $sources {
        if ($dir | path exists) { ^cp -af $"($dir)/." $destination }
    }
}
def main [] {
    ^install -Dm644 /ctx/usr/lib/sysusers.d/docker.conf /usr/lib/sysusers.d/docker.conf
    ^install -Dm644 /ctx/usr/lib/tmpfiles.d/bazzite-workstation.conf /usr/lib/tmpfiles.d/bazzite-workstation.conf
    ^mkdir -p /usr/share/ublue-os/just /usr/share/ublue-os/homebrew /etc/profile.d
    copy_if_dir_exists [/oci/common/usr/share/ublue-os/just, /oci/common/bluefin/usr/share/ublue-os/just, /oci/common/shared/usr/share/ublue-os/just] /usr/share/ublue-os/just/
    copy_if_dir_exists [/oci/common/usr/share/ublue-os/homebrew, /oci/common/bluefin/usr/share/ublue-os/homebrew, /oci/common/shared/usr/share/ublue-os/homebrew] /usr/share/ublue-os/homebrew/
    copy_if_dir_exists [/oci/common/etc/profile.d, /oci/common/bluefin/etc/profile.d, /oci/common/shared/etc/profile.d] /etc/profile.d/
    ['if [ "$(command -v starship)" ]; then', '    eval "$(starship init bash)"', 'fi', ''] | str join (char nl) | save --force /etc/profile.d/starship.sh
}
