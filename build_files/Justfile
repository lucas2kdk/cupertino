# cupertino: apply WhiteSur theming to current user

# Apply WhiteSur (Plasma + Kvantum + GTK + icons + cursor) to your account
cupertino-apply-theme:
    #!/usr/bin/bash
    set -euo pipefail
    echo "Applying WhiteSur theme to $USER..."

    # Plasma look-and-feel (this rewrites several config files)
    if command -v plasma-apply-lookandfeel >/dev/null; then
        plasma-apply-lookandfeel -a com.github.vinceliuice.WhiteSur || true
    fi
    if command -v plasma-apply-colorscheme >/dev/null; then
        plasma-apply-colorscheme WhiteSurDark || true
    fi
    if command -v plasma-apply-desktoptheme >/dev/null; then
        plasma-apply-desktoptheme WhiteSur-dark || true
    fi
    if command -v plasma-apply-cursortheme >/dev/null; then
        plasma-apply-cursortheme WhiteSur-cursors || true
    fi

    # Widget style → Kvantum, icon theme → WhiteSur-dark
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
    kwriteconfig6 --file kdeglobals --group Icons --key Theme WhiteSur-dark

    # Window decoration → Aurorae WhiteSur-dark
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__WhiteSur-dark

    # Kvantum theme selection
    mkdir -p ~/.config/Kvantum
    echo -e "[General]\ntheme=WhiteSur" > ~/.config/Kvantum/kvantum.kvconfig

    # Default cursor for GTK/X apps
    mkdir -p ~/.icons/default
    echo -e "[Icon Theme]\nInherits=WhiteSur-cursors" > ~/.icons/default/index.theme

    # GTK theme
    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' || true
        gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' || true
        gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors' || true
    fi

    echo "Done. Log out and back in (or reboot) for all changes to take effect."

# Reset theming back to Plasma defaults
cupertino-reset-theme:
    #!/usr/bin/bash
    set -euo pipefail
    echo "Resetting Plasma theming to defaults..."
    rm -f ~/.config/kdeglobals ~/.config/kwinrc ~/.config/plasmarc
    rm -rf ~/.config/Kvantum ~/.icons/default
    echo "Done. Log out and back in."
