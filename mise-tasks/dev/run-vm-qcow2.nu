#!/usr/bin/env nu
#MISE description="VM: Run QEMU from qcow2 image"
def main [] { ^mise run run-vm qcow2 disk_config/disk.toml }
