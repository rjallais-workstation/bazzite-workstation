#!/usr/bin/env nu
#MISE description="Install: NetBird client (binary method avoids RPM scriptlet failures)"
def main [] {
    let release = (^curl -fsSL "https://api.github.com/repos/netbirdio/netbird/releases/latest" | from json)
    let netbird_version = (($release | get -o tag_name | default "") | str replace --regex '^v' '')
    if ($netbird_version | is-empty) { error make {msg: "Failed to detect latest NetBird version from GitHub API"} }
    let arch = (^uname -m | str trim)
    let netbird_arch = if $arch == "x86_64" { "amd64" } else { $arch }
    print $"Installing NetBird v($netbird_version) (($netbird_arch))"
    let tarball_url = $"https://github.com/netbirdio/netbird/releases/download/v($netbird_version)/netbird_($netbird_version)_linux_($netbird_arch).tar.gz"
    ^curl -fsSL $tarball_url | ^tar xz -C /tmp
    ^install -Dm755 /tmp/netbird /usr/bin/netbird
    ^rm -f /tmp/netbird
    let service_file = '/usr/lib/systemd/system/netbird.service'
    [
        '[Unit]'
        'Description=NetBird WireGuard Client'
        'After=network-online.target'
        'Wants=network-online.target'
        ''
        '[Service]'
        'Type=simple'
        'ExecStart=/usr/bin/netbird service run'
        'Restart=on-failure'
        'RestartSec=5'
        ''
        '[Install]'
        'WantedBy=multi-user.target'
        ''
    ] | str join (char nl) | save --force $service_file
}
