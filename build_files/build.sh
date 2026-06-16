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
    inkscape \
    util-linux-script \
    glib2-devel \
    libxml2

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
    kdeplasma-addons \
    appmenu-gtk3-module || true

### --- Install WhiteSur theme suite system-wide ---
# WhiteSur install scripts assume $USER, $HOME, and $TERM are set
# Container builds have no login session and no terminal
export USER="${USER:-root}"
export HOME="${HOME:-/root}"
export TERM="${TERM:-xterm}"
# WhiteSur uses these to fill SCSS placeholders; without gnome-shell installed
# the script generates invalid SCSS ('$GNOME_SHELL: ;')
export SHELL_VERSION="46"
export GNOME_VERSION="46-0"

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
if [ -d aurorae/themes ]; then
    cp -r aurorae/themes/* /usr/share/aurorae/themes/
else
    # Repo layout: aurorae/ IS the theme — place it under its own dir
    mkdir -p /usr/share/aurorae/themes/WhiteSur-dark
    cp -r aurorae/* /usr/share/aurorae/themes/WhiteSur-dark/
fi
ls /usr/share/aurorae/themes/
cp -r color-schemes/*.colors /usr/share/color-schemes/
cp -r Kvantum/* /usr/share/Kvantum/
cp -r wallpaper/* /usr/share/wallpapers/ || true
cd "$TMPDIR"

# Patch silent_mode default to true — avoids start_animation/setterm needing a tty
# and avoids --silent-mode flag's full_sudo /root writable check
patch_silent() {
    [ -f libs/lib-core.sh ] && sed -i 's/^silent_mode="false"/silent_mode="true"/' libs/lib-core.sh || true
    [ -f install.sh ] && sed -i 's|exec 2> "${WHITESUR_TMP_DIR}/error_log.txt"|true|' install.sh || true
    [ -f libs/lib-core.sh ] && sed -i "s|trap 'signal_exit' EXIT||" libs/lib-core.sh || true
    [ -f libs/lib-core.sh ] && sed -i "s|trap 'signal_error' ERR||" libs/lib-core.sh || true
}

# GTK theme
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
patch_silent
set +e
./install.sh -d /usr/share/themes -t default 2>&1 | tee /tmp/whitesur-gtk.log
rc=${PIPESTATUS[0]}
set -e
if [ "$rc" != 0 ]; then
    echo "=== WhiteSur GTK error_log.txt ==="
    cat /tmp/WhiteSur.lock/error_log.txt 2>&1 || true
    exit "$rc"
fi
cd "$TMPDIR"

# Icon theme
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
patch_silent
set +e
./install.sh -d /usr/share/icons -a 2>&1 | tee /tmp/whitesur-icons.log
rc=${PIPESTATUS[0]}
set -e
if [ "$rc" != 0 ]; then
    echo "=== WhiteSur icons error_log.txt ==="
    cat /tmp/WhiteSur.lock/error_log.txt 2>&1 || true
    exit "$rc"
fi
cd "$TMPDIR"

# Cursor theme
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git
cd WhiteSur-cursors
make build || true
mkdir -p /usr/share/icons/WhiteSur-cursors
cp -r dist/* /usr/share/icons/WhiteSur-cursors/ 2>/dev/null || cp -r dist /usr/share/icons/WhiteSur-cursors
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
install -Dm0644 /ctx/90-cupertino.just /usr/share/ublue-os/just/60-custom.just

### --- Apple logo for kickoff menu ---
install -Dm0644 /ctx/apple-logo.svg /usr/share/icons/hicolor/scalable/apps/cupertino-apple.svg
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

### --- Pick a default wallpaper from WhiteSur-kde wallpapers ---
DEFAULT_WP="$(ls /usr/share/wallpapers/*.jpg /usr/share/wallpapers/*.png 2>/dev/null | head -1 || true)"
if [ -n "$DEFAULT_WP" ]; then
    ln -sf "$DEFAULT_WP" /usr/share/wallpapers/cupertino-default
fi

### Enable services
systemctl enable podman.socket
