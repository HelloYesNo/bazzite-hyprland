#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 

### Install Hyprland and Quickshell for desktop environment
# Enable required COPR repositories
dnf5 -y copr enable errornointernet/quickshell
dnf5 -y copr enable msmafra/nwg-shell

# Install Hyprland, Quickshell and dependencies
dnf5 -y install \
    hyprland \
    hyprpaper \
    hyprpicker \
    hypridle \
    hyprlock \
    hyprpolkitagent \
    swww \
    mpvpaper \
    cliphist \
    hyprland-plugins \
    xdg-desktop-portal-hyprland \
    qt6ct-kde \
    lxpolkit

# Install Material Icons font
mkdir -p /tmp/material-design-icons
git clone https://github.com/google/material-design-icons.git /tmp/material-design-icons --depth 1
mkdir -p /usr/share/fonts/TTF
cp -r /tmp/material-design-icons/font/* /usr/share/fonts/TTF/ 2>/dev/null || true
cp -r /tmp/material-design-icons/variablefont/* /usr/share/fonts/TTF/ 2>/dev/null || true
fc-cache -fv
rm -rf /tmp/material-design-icons

# Disable COPR repos so they don't end up enabled on the final image
dnf5 -y copr disable errornointernet/quickshell
dnf5 -y copr disable msmafra/nwg-shell

# Install ujust commands for Hyprland customization
if [[ -f /ctx/just_scripts/90-bazzite-hyprland.just ]]; then
    echo "Installing Hyprland ujust commands..."
    mkdir -p /usr/share/ublue-os/just
    cp /ctx/just_scripts/90-bazzite-hyprland.just /usr/share/ublue-os/just/
    echo "import \"/usr/share/ublue-os/just/90-bazzite-hyprland.just\"" >> /usr/share/ublue-os/justfile
    echo "Hyprland ujust commands installed"
else
    echo "Warning: Hyprland just script not found at /ctx/just_scripts/90-bazzite-hyprland.just"
fi

# Verify SDDM session registration for Hyprland
echo "Verifying Hyprland SDDM session registration..."
if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
    echo "✓ Hyprland SDDM session file found: /usr/share/wayland-sessions/hyprland.desktop"
else
    echo "✗ Warning: Hyprland SDDM session file not found at /usr/share/wayland-sessions/hyprland.desktop"
    echo "Creating minimal Hyprland desktop entry..."
    mkdir -p /usr/share/wayland-sessions
    cat > /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
    echo "Created Hyprland desktop entry"
fi

#### Example for enabling a System Unit File

systemctl enable podman.socket
