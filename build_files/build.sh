#!/bin/bash

set -ouex pipefail

### cupertino: macOS-inspired Bazzite KDE spin
### Base: bazzite-nvidia-open:stable (KDE + signed nvidia-open)

### --- Theming stack (Kvantum + GTK + icons + cursors) ---
dnf5 install -y \
    kvantum \
    qt5ct \
    qt6ct \
    gtk-murrine-engine \
    sassc \
    papirus-icon-theme \
    git \
    inkscape

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
dnf5 install -y \
    plasma-systemmonitor \
    kdeplasma-addons || true

### --- Install WhiteSur theme suite system-wide ---
TMPDIR="$(mktemp -d)"
cd "$TMPDIR"

# Plasma / Aurorae / Kvantum / Color schemes / Wallpapers
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-kde.git
cd WhiteSur-kde
# Install components to system locations
mkdir -p /usr/share/plasma/look-and-feel \
         /usr/share/plasma/desktoptheme \
         /usr/share/aurorae/themes \
         /usr/share/color-schemes \
         /usr/share/Kvantum \
         /usr/share/wallpapers
cp -r plasma/look-and-feel/* /usr/share/plasma/look-and-feel/
cp -r plasma/desktoptheme/* /usr/share/plasma/desktoptheme/
cp -r aurorae/* /usr/share/aurorae/themes/
cp -r color-schemes/*.colors /usr/share/color-schemes/
cp -r Kvantum/* /usr/share/Kvantum/
cp -r wallpaper/* /usr/share/wallpapers/ || true
cd "$TMPDIR"

# GTK theme
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh -d /usr/share/themes -c light -c dark -t default
cd "$TMPDIR"

# Icon theme
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh -d /usr/share/icons -a
cd "$TMPDIR"

# Cursor theme
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git
cd WhiteSur-cursors
make build || true
cp -r dist /usr/share/icons/WhiteSur-cursors
cd /
rm -rf "$TMPDIR"

### --- System-wide defaults via /etc/xdg ---
mkdir -p /etc/xdg /etc/xdg/gtk-3.0 /etc/xdg/gtk-4.0

cat > /etc/xdg/kdeglobals <<'EOF'
[General]
ColorScheme=WhiteSurDark
Name=WhiteSur Dark
shadeSortColumn=true

[Icons]
Theme=WhiteSur-dark

[KDE]
LookAndFeelPackage=com.github.vinceliuice.WhiteSur
contrast=4
widgetStyle=kvantum

[WM]
activeBackground=44,49,58
activeBlend=44,49,58
activeForeground=255,255,255
inactiveBackground=44,49,58
inactiveBlend=44,49,58
inactiveForeground=161,169,177
EOF

cat > /etc/xdg/kwinrc <<'EOF'
[org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__WhiteSur-dark
EOF

cat > /etc/xdg/plasmarc <<'EOF'
[Theme]
name=WhiteSur-dark
EOF

# GTK defaults
cat > /etc/xdg/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=WhiteSur-Dark
gtk-icon-theme-name=WhiteSur-dark
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Inter 10
EOF
cp /etc/xdg/gtk-3.0/settings.ini /etc/xdg/gtk-4.0/settings.ini

# Kvantum default (per-user; seed via /etc/skel)
mkdir -p /etc/skel/.config/Kvantum
cat > /etc/skel/.config/Kvantum/kvantum.kvconfig <<'EOF'
[General]
theme=WhiteSur
EOF

# Default cursor
mkdir -p /etc/skel/.icons/default
cat > /etc/skel/.icons/default/index.theme <<'EOF'
[Icon Theme]
Inherits=WhiteSur-cursors
EOF

### --- Install cupertino ujust recipes ---
install -Dm0644 /ctx/90-cupertino.just /usr/share/ublue-os/just/90-cupertino.just

### Enable services
systemctl enable podman.socket
