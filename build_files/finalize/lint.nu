#!/usr/bin/env nu
#MISE description="Finalize: Clean runtime artifacts and run bootc lint"
def try_run [cmd: closure] {
    try { do $cmd } catch { null }
}
def main [] {
    try_run {|| ^find /run -mindepth 1 -maxdepth 1 ! -name .containerenv ! -name secrets ! -name systemd ! -name mount -exec rm -rf '{}' '+' }
    try_run {|| ^find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf '{}' '+' }
    ^rm -f /var/log/dnf5.log
    ^rm -rf /var/roothome/.local
    for p in [/run/systemd/resolve, /run/systemd, /run/mount] {
        let is_mount = (try {
            ^mountpoint -q $p
            true
        } catch { false })
        if $is_mount {
            try_run {|| ^umount -l $p }
        }
    }
    for p in [/run/systemd/resolve, /run/systemd, /run/mount] {
        let has_nested_mounts = (try {
            ^findmnt -Rno TARGET $p
            true
        } catch { false })
        if not $has_nested_mounts {
            try_run {|| ^rm -rf $p }
        }
    }
    try_run {|| ^find /run -mindepth 1 -type d -empty ! -name .containerenv ! -name secrets -delete }
    ^rm -f /etc/resolv.conf
    ^ln -s ../usr/lib/systemd/resolv.conf /etc/resolv.conf
    try_run {|| ^rm -rf /run/systemd/resolve /run/systemd /run/mount }
    try_run {|| ^find /run -mindepth 1 -maxdepth 1 ! -name .containerenv ! -name secrets -exec rm -rf '{}' '+' }
    try_run {|| ^find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf '{}' '+' }
    ^rm -rf /.mise /bin /mise.toml
    ^bootc container lint
}
