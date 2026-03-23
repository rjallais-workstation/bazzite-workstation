#!/usr/bin/env nu
#MISE description="Install: Remove unwanted base packages"
def main [] {
    let packages = [
        fedora-bookmarks
        fedora-chromium-config
        fedora-chromium-config-gnome
        yelp
        gamescope
        gamescope-libs
        gamescope-shaders
        lutris
        mangohud
        steam
        steamdeck-backgrounds
        steamdeck-gnome-presets
        umu-launcher
        vkBasalt
    ]
    ^dnf5 remove --setopt=clean_requirements_on_remove=False -y ...$packages
}
