#!/usr/bin/env nu
#MISE description="Build: ISO image from local container image"
def main [] { with-env { TYPE: "iso", CONFIG: "disk_config/iso.toml" } {
        ^mise run build-qcow2
    } }
