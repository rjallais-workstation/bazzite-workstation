# vim: set ft=make :

[group('Apps')]
install-default-apps:
    #!/usr/bin/env bash
    brew bundle --file /usr/share/ublue-os/homebrew/default.Brewfile

[group('Apps')]
install-default-flatpaks:
    #!/usr/bin/env bash
    flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --user install -y flathub com.github.tchx84.Flatseal org.gnome.Boxes org.gnome.Calculator

[group('Apps')]
install-runtime-apps:
    #!/usr/bin/env bash
    brew bundle --file /usr/share/ublue-os/homebrew/default.Brewfile
    flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --user install -y flathub com.github.tchx84.Flatseal org.gnome.Boxes org.gnome.Calculator

[group('Apps')]
install-fd:
    #!/usr/bin/env bash
    brew install fd

[group('Apps')]
install-boxes:
    #!/usr/bin/env bash
    flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --user install -y flathub org.gnome.Boxes

[group('Apps')]
install-bat:
    #!/usr/bin/env bash
    brew install bat

[group('Apps')]
install-calculator:
    #!/usr/bin/env bash
    flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --user install -y flathub org.gnome.Calculator

