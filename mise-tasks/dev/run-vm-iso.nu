#!/usr/bin/env nu
#MISE description="VM: Run QEMU from ISO image"
def main [] { ^mise run run-vm iso disk_config/iso.toml }
