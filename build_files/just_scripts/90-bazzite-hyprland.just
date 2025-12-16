# Hyprland customization commands for Bazzite
# These commands help users customize their Hyprland desktop environment

[group('Hyprland')]

# Install popular HyprlandDE-Quickshell dotfiles
install-hyprland-rice:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Installing HyprlandDE-Quickshell dotfiles..."
    
    # Create backup of existing configuration
    BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    if [[ -d ~/.config ]]; then
        echo "Backing up existing ~/.config to $BACKUP_DIR"
        cp -r ~/.config "$BACKUP_DIR"
    fi
    
    # Clone the dotfiles repository
    DOTFILES_DIR="/tmp/hyprlandde-quickshell"
    rm -rf "$DOTFILES_DIR"
    git clone https://github.com/ryzendew/HyprlandDE-Quickshell.git "$DOTFILES_DIR" --branch Stable --depth 1
    
    # Copy configuration files
    if [[ -d "$DOTFILES_DIR/.config" ]]; then
        echo "Copying configuration files..."
        cp -r "$DOTFILES_DIR/.config"/* ~/.config/
        
        # Update environment configuration with current user info
        ENV_CONF="$HOME/.config/hypr/hyprland/env.conf"
        if [[ -f "$ENV_CONF" ]]; then
            USERID=$(id -u)
            sed -i "s|^# env = XDG_RUNTIME_DIR,/run/user/|# env = XDG_RUNTIME_DIR,/run/user/$USERID|g" "$ENV_CONF"
            sed -i "s|^# env = QML2_IMPORT_PATH,.*|env = QML2_IMPORT_PATH,$HOME/.config/hypr/quickshell|g" "$ENV_CONF"
            sed -i "s|^env = QML2_IMPORT_PATH,.*|env = QML2_IMPORT_PATH,$HOME/.config/hypr/quickshell|g" "$ENV_CONF"
        fi
        
        # Install wallpapers
        if [[ -d "$DOTFILES_DIR/Wallpapers" ]]; then
            mkdir -p ~/Pictures
            cp -r "$DOTFILES_DIR/Wallpapers" ~/Pictures/
        fi
        
        # Create necessary directories
        mkdir -p ~/.local/state/quickshell/{Dock,Icons,Wallpapers}
        
        echo "Dotfiles installation complete!"
        echo "Please reboot and select 'Hyprland' in SDDM."
        echo "Your original config is backed up at: $BACKUP_DIR"
    else
        echo "Error: Could not find .config directory in the repository"
        exit 1
    fi
    
    rm -rf "$DOTFILES_DIR"

# Install hyprswitch (optional window switcher)
install-hyprswitch:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Installing hyprswitch window switcher..."
    
    # Check if Rust is installed
    if ! command -v cargo &>/dev/null; then
        echo "Installing Rust..."
        rpm-ostree install rust cargo
    fi
    
    # Install build dependencies
    echo "Installing build dependencies..."
    rpm-ostree install gtk4-devel pkgconf cairo-devel pango-devel gdk-pixbuf2-devel glib2-devel gtk4-layer-shell-devel
    
    # Clone and build
    HYPRSWITCH_DIR="/tmp/hyprswitch"
    rm -rf "$HYPRSWITCH_DIR"
    git clone https://github.com/ryzendew/hyprswitch.git "$HYPRSWITCH_DIR"
    cd "$HYPRSWITCH_DIR"
    
    echo "Building hyprswitch..."
    cargo build --release
    
    echo "Installing to /usr/local/bin..."
    sudo cp target/release/hyprswitch /usr/local/bin/
    sudo chmod +x /usr/local/bin/hyprswitch
    
    # Install systemd service if available
    if [[ -f "systemd/hyprswitch.service" ]]; then
        sudo cp systemd/hyprswitch.service /etc/systemd/user/
        sudo systemctl daemon-reload
        echo "Systemd service installed"
    fi
    
    cd ~
    rm -rf "$HYPRSWITCH_DIR"
    echo "hyprswitch installed successfully!"

# Install additional icon themes
install-hyprland-themes:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Installing additional icon themes for Hyprland..."
    
    # Install Tela Circle icons
    echo "Installing Tela Circle icon theme..."
    TELA_DIR="/tmp/Tela-circle-icon-theme"
    rm -rf "$TELA_DIR"
    git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$TELA_DIR"
    (cd "$TELA_DIR" && sudo ./install.sh -a)
    rm -rf "$TELA_DIR"
    
    # Install OneUI4-Icons
    echo "Installing OneUI4-Icons..."
    rm -rf /tmp/OneUI4-Icons
    git clone https://github.com/end-4/OneUI4-Icons.git /tmp/OneUI4-Icons
    sudo cp -r /tmp/OneUI4-Icons/OneUI* /usr/share/icons/
    rm -rf /tmp/OneUI4-Icons
    
    # Install Bibata Modern Classic cursor
    echo "Installing Bibata Modern Classic cursor theme..."
    wget -O /tmp/Bibata-Modern-Classic.tar.xz https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Classic.tar.xz
    sudo mkdir -p /usr/share/icons
    sudo tar -xf /tmp/Bibata-Modern-Classic.tar.xz -C /usr/share/icons
    rm /tmp/Bibata-Modern-Classic.tar.xz
    
    # Update icon caches
    echo "Updating icon caches..."
    sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor
    sudo gtk-update-icon-cache -f -t /usr/share/icons/Papirus
    sudo gtk-update-icon-cache -f -t /usr/share/icons/Tela-circle*
    
    echo "Theme installation complete!"
    echo "You can change themes using qt6ct or your preferred theme switcher."

# Reset Hyprland configuration to defaults
reset-hyprland-config:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Resetting Hyprland configuration to defaults..."
    
    # Create backup
    BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    if [[ -d ~/.config/hypr ]]; then
        echo "Backing up current Hyprland config to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        cp -r ~/.config/hypr "$BACKUP_DIR/"
    fi
    
    # Remove existing configuration
    rm -rf ~/.config/hypr
    rm -rf ~/.config/quickshell
    
    # Create minimal default configuration
    mkdir -p ~/.config/hypr
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Default Hyprland configuration for Bazzite
# Generated on $(date)

# Monitor configuration
monitor=,preferred,auto,1

# Execute at launch
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/libexec/polkit-gnome-authentication-agent-1
exec-once = waybar
exec-once = mako

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = false
    }
}

# General configuration
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = false
}

# Window rules
windowrule = float, ^(kitty)$
windowrule = center, ^(kitty)$

# Keybindings
$mainMod = SUPER

bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, nautilus
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF

    echo "Default Hyprland configuration created at ~/.config/hypr/hyprland.conf"
    echo "Backup of old config saved to: $BACKUP_DIR"
    echo "Please restart Hyprland or reboot to apply changes."