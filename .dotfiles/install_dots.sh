#!/usr/bin/env zsh
# Script de restauracion y configuracion automatica de entorno para Fedora
set -euo pipefail

REPO_URL="git@github.com:jrodriiguezg/dotfiles.git"
TARGET_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

echo "==> [1/9] Configurando SELinux y repositorios COPR..."
# Permitir carga dinamica de modulos en kernels personalizados
sudo setsebool -P domain_kernel_load_modules on

# Repositorios COPR para kernel CachyOS y addons
sudo dnf copr enable -y bieszczaders/kernel-cachyos
sudo dnf copr enable -y bieszczaders/kernel-cachyos-addons

# Repositorios RPM Fusion (free y nonfree)
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "==> [2/9] Instalando kernel CachyOS, plugin DNF5 y fijando entrada por defecto..."
sudo dnf install -y kernel-cachyos kernel-cachyos-devel-matched libdnf5-plugin-actions

# Crear hook DNF5 para fijar siempre el kernel CachyOS mas reciente en GRUB
sudo mkdir -p /etc/dnf/libdnf5-plugins/actions.d
sudo tee /etc/dnf/libdnf5-plugins/actions.d/cachy-default.actions << 'EOF'
# After installing any kernel* package, set the latest CachyOS kernel as the default boot entry
post_transaction:kernel*:in::/usr/bin/sh -c /usr/bin/grubby\ --set-default=/boot/$(ls\ /boot\ |\ grep\ vmlinuz.*cachy\ |\ sort\ -V\ |\ tail\ -1)
EOF

# Aplicar grubby de forma inmediata
LATEST_CACHY=$(ls /boot | grep 'vmlinuz.*cachy' | sort -V | tail -1 || true)
if [[ -n "$LATEST_CACHY" ]]; then
  sudo grubby --set-default="/boot/$LATEST_CACHY"
fi

echo "==> [3/9] Instalando CachyOS addons, planificadores sched-ext y ananicy-cpp..."
sudo dnf swap -y zram-generator-defaults cachyos-settings
sudo dracut -f
sudo dnf install -y scx-scheds scx-tools ananicy-cpp
sudo systemctl enable --now ananicy-cpp

echo "==> [4/9] Instalando paquetes base, Wayland, Hyprland y utilidades..."
sudo dnf install -y \
  git zsh nano jq curl wget tree \
  hyprland swaybg waybar kitty mako wlogout \
  libnotify wl-clipboard grim slurp \
  polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  pam-u2f fido2-tools pcsc-lite pcsc-lite-ccid opensc \
  akmod-nvidia xorg-x11-drv-nvidia-cuda \
  mesa-demos vulkan-tools tuned

echo "==> [5/9] Instalando stack de virtualizacion, gaming y contenedores..."
sudo dnf install -y virt-manager bridge-utils
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER"

sudo dnf install -y steam lutris wine winetricks gamemode mangohud \
                    vulkan-loader.i686 mesa-vulkan-drivers.i686 \
                    podman podman-compose

# NVIDIA Container Toolkit (CDI para Podman)
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo dnf install -y nvidia-container-toolkit

echo "==> [6/9] Habilitando demonio para Google Titan Key..."
sudo systemctl enable --now pcscd

echo "==> [7/9] Instalando binario precompilado de swww..."
if ! command -v swww >/dev/null 2>&1; then
  SWWW_URL=$(curl -sL https://api.github.com/repos/LGFae/swww/releases/latest | \
    grep "browser_download_url.*x86_64.*tar.gz" | cut -d : -f 2,3 | tr -d \")
  if [[ -n "$SWWW_URL" ]]; then
    wget -qO /tmp/swww.tar.gz "$SWWW_URL"
    sudo tar -xzf /tmp/swww.tar.gz -C /usr/local/bin/
    sudo chmod +x /usr/local/bin/swww /usr/local/bin/swww-daemon
    rm -f /tmp/swww.tar.gz
  fi
fi

echo "==> [8/9] Desplegando dotfiles desde el repositorio bare..."
if [[ ! -d "$TARGET_DIR" ]]; then
  git clone --bare "$REPO_URL" "$TARGET_DIR"
fi

config_git() {
  /usr/bin/git --git-dir="$TARGET_DIR" --work-tree="$HOME" "$@"
}

mkdir -p "$BACKUP_DIR"
if ! config_git checkout 2>/dev/null; then
  echo "==> Respaldando colisiones en $BACKUP_DIR..."
  config_git checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' | while read -r file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    mv "$HOME/$file" "$BACKUP_DIR/$file"
  done
  config_git checkout
fi

config_git config --local status.showUntrackedFiles no

echo "==> [9/9] Ajustes finales de sistema y permisos..."
if [[ ! -f "$HOME/.zshenv" ]]; then
  echo 'export ZDOTDIR="$HOME/.config"' > "$HOME/.zshenv"
fi

# Generar CDI de NVIDIA si el modulo esta activo
if command -v nvidia-ctk >/dev/null 2>&1; then
  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml 2>/dev/null || true
fi

# Regla sudoers para cambiar perfiles de tuned-adm desde Waybar sin contrasena
echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/tuned-adm" | sudo tee /etc/sudoers.d/99-tuned-waybar >/dev/null
sudo chmod 0440 /etc/sudoers.d/99-tuned-waybar
sudo systemctl enable --now tuned

echo "==> Despliegue completado con exito."
