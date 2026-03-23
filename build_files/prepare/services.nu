#!/usr/bin/env nu
#MISE description="Prepare: Enable systemd services"
def main [] {
    for svc in [docker.socket, podman.socket, netbird.service] {
        try { ^systemctl enable $svc } catch { null }
    }
}
