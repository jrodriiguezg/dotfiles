#!/usr/bin/env zsh
# Script de restauracion y configuracion automatica de entorno para Fedora
set -euo pipefail

REPO_URL="git@github.com:jrodriiguezg/dotfiles.git"
TARGET_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

echo "==> [1/7] Habilitando RPM Fusion (free/nonfree)..."
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "==> [2/7] Instalando paquetes base, Wayland, Hyprland y utilidades de terminal..."
sudo dnf install -y \
  git zsh nano jq curl wget tree \
  hyprland swaybg waybar kitty mako wlogout \
  libnotify wl-clipboard grim slurp \
  polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  pam-u2f fido2-tools pcsc-lite pcsc-lite-ccid opensc \
  podman podman-compose \
  akmod-nvidia xorg-x11-drv-nvidia-cuda \
  mesa-demos vulkan-tools

echo "==> [3/7] Configurando repositorio y herramientas de NVIDIA CDI para Podman..."
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo dnf install -y nvidia-container-toolkit

echo "==> [4/7] Habilitando demonio para Google Titan Key..."
sudo systemctl enable --now pcscd

echo "==> [5/7] Instalando binario precompilado de swww..."
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

echo "==> [6/7] Desplegando dotfiles desde el repositorio bare..."
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

echo "==> [7/7] Configurando entorno de Zsh y carpetas de sistema..."
# Asegurar que ZDOTDIR o el loader de zsh apunte a ~/.config/zshrc si no existe .zshenv
if [[ ! -f "$HOME/.zshenv" ]]; then
  echo 'export ZDOTDIR="$HOME/.config"' > "$HOME/.zshenv"
fi

# Generar CDI de NVIDIA si el driver ya compilo
if command -v nvidia-ctk >/dev/null 2>&1; then
  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml 2>/dev/null || true
fi

# Configurar permisos NOPASSWD para cambiar perfiles de tuned desde Waybar
echo "==> Configurando regla sudoers para tuned-adm..."
echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/tuned-adm" | sudo tee /etc/sudoers.d/99-tuned-waybar >/dev/null
sudo chmod 0440 /etc/sudoers.d/99-tuned-waybar

# Asegurar servicio tuned activo
sudo systemctl enable --now tuned

echo "==> Despliegue completado con exito."
