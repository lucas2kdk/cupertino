# cupertino: apply WhiteSur theming to current user

# Apply WhiteSur (Plasma + Kvantum + GTK + icons + cursor) to your account
cupertino-apply-theme:
    #!/usr/bin/bash
    set -euo pipefail
    echo "Applying WhiteSur theme to $USER..."

    # Plasma look-and-feel (this rewrites several config files)
    if command -v plasma-apply-lookandfeel >/dev/null; then
        plasma-apply-lookandfeel -a com.github.vinceliuice.WhiteSur-dark || true
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
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__WhiteSur

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

    # Set default wallpaper (first wallpaper shipped by WhiteSur-kde)
    WP="$(ls /usr/share/wallpapers/*.jpg /usr/share/wallpapers/*.png 2>/dev/null | head -1 || true)"
    if [ -n "$WP" ] && command -v plasma-apply-wallpaperimage >/dev/null; then
        plasma-apply-wallpaperimage "$WP" || true
    fi

    # Rearrange panels: top global-menu bar + bottom icon dock
    {{just_executable()}} --justfile {{justfile()}} cupertino-apply-panels

    echo "Done. Log out and back in (or reboot) for all changes to take effect."

# Replace Plasma panels with a top menubar + bottom dock layout
cupertino-apply-panels:
    #!/usr/bin/bash
    set -euo pipefail
    SCRIPT='
    var allPanels = panels();
    for (var i = 0; i < allPanels.length; i++) { allPanels[i].remove(); }

    var top = new Panel;
    top.location = "top";
    top.height = 28;
    top.floating = false;
    top.lengthMode = "fill";
    var apple = top.addWidget("org.kde.plasma.kickoff");
    apple.currentConfigGroup = ["General"];
    apple.writeConfig("icon", "cupertino-apple");
    apple.writeConfig("menuLabel", "");
    top.addWidget("org.kde.plasma.appmenu");
    top.addWidget("org.kde.plasma.panelspacer");
    top.addWidget("org.kde.plasma.systemtray");
    top.addWidget("org.kde.plasma.battery");
    top.addWidget("org.kde.plasma.keyboardlayout");
    top.addWidget("org.kde.plasma.digitalclock");
    top.addWidget("org.kde.plasma.notifications");

    var dock = new Panel;
    dock.location = "bottom";
    dock.height = 64;
    dock.alignment = "center";
    dock.hiding = "normal";
    dock.lengthMode = "fit";
    dock.floating = true;
    var tasks = dock.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", "applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.mozilla.firefox.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kate.desktop,applications:org.kde.kcalc.desktop,applications:org.kde.gwenview.desktop,applications:org.kde.spectacle.desktop,applications:org.kde.discover.desktop,applications:steam.desktop,applications:com.discordapp.Discord.desktop,applications:com.spotify.Client.desktop,applications:systemsettings.desktop");
    tasks.writeConfig("showOnlyCurrentDesktop", false);
    tasks.writeConfig("showOnlyCurrentScreen", false);
    tasks.writeConfig("showOnlyCurrentActivity", false);
    '
    if command -v qdbus6 >/dev/null; then
        QDBUS=qdbus6
    else
        QDBUS=qdbus
    fi
    $QDBUS org.kde.plasmashell /PlasmaShell evaluateScript "$SCRIPT"

    # Window buttons: close/min/max on the LEFT, like macOS
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key ButtonsOnLeft "XIA"
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key ButtonsOnRight ""

    if command -v qdbus6 >/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure || true
    else
        qdbus org.kde.KWin /KWin reconfigure || true
    fi
    echo "Panels rearranged."

# Reset theming back to Plasma defaults
cupertino-reset-theme:
    #!/usr/bin/bash
    set -euo pipefail
    echo "Resetting Plasma theming to defaults..."
    rm -f ~/.config/kdeglobals ~/.config/kwinrc ~/.config/plasmarc
    rm -rf ~/.config/Kvantum ~/.icons/default
    echo "Done. Log out and back in."
