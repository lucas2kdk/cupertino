#!/bin/bash

set -ouex pipefail

### cupertino: macOS-inspired Bazzite KDE spin
### Base: bazzite-nvidia-open:stable (KDE + signed nvidia-open)
### This script layers: dx-style devtools + Qt/GTK theming stack for macOS look

### --- Theming stack (Kvantum + GTK + icons + cursors) ---
dnf5 install -y \
    kvantum \
    qt5ct \
    qt6ct \
    gtk-murrine-engine \
    sassc \
    gnome-themes-extra \
    papirus-icon-theme

### --- dx-style developer tooling ---
dnf5 install -y \
    tmux \
    git-credential-libsecret \
    gh \
    just \
    jq \
    fzf \
    ripgrep \
    fd-find \
    bat \
    htop \
    podman-compose \
    distrobox

### --- KDE extras for macOS feel ---
# Latte Dock is no longer in Fedora 42+, Plasma 6 uses native panel.
# Plasma6 already ships KWin Magic Lamp (Genie minimize) effect.
dnf5 install -y \
    plasma-systemmonitor \
    kdeplasma-addons || true

### Enable services
systemctl enable podman.socket
