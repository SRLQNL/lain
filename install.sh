#!/bin/bash
# =====================================================================
# Установщик Lain Rice для Void Linux
# =====================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SCRIPTS_DIR="$HOME/Scripts"

echo "╔══════════════════════════════════════════╗"
echo "║   Lain Rice — Установщик для Void Linux  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- 0. Подключение стороннего репозитория Hyprland ---
# Hyprland отсутствует в официальных репозиториях Void — нужен сторонний реп.
# https://github.com/Makrennel/hyprland-void
echo "[0/5] Подключаю репозиторий hyprland-void..."
HYPR_REPO_FILE="/etc/xbps.d/hyprland-void.conf"
if [ ! -f "$HYPR_REPO_FILE" ]; then
    echo "repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc" \
        | sudo tee "$HYPR_REPO_FILE" > /dev/null
    echo "  ✓ Репозиторий добавлен"
else
    echo "  · Репозиторий уже подключён"
fi

# Принять fingerprint репозитория и синхронизировать
sudo xbps-install -S
echo "  ✓ Репозиторий синхронизирован"

# --- 1. Установка пакетов ---
echo "[1/5] Устанавливаю пакеты через xbps..."
sudo xbps-install -Sy \
    hyprland \
    xdg-desktop-portal-hyprland \
    hyprpaper \
    hypridle \
    hyprlock \
    waybar \
    rofi \
    mako \
    sddm \
    foot \
    kitty \
    fish-shell \
    neofetch \
    mpv \
    thunar \
    yazi \
    NetworkManager \
    nm-applet \
    brightnessctl \
    swaylock \
    swayidle \
    grim \
    slurp \
    swappy \
    wl-clipboard \
    pipewire \
    wireplumber \
    pavucontrol \
    bluez \
    bluetuith \
    pamixer \
    playerctl \
    wlogout \
    polkit-gnome \
    yad \
    python3 \
    jq \
    git \
    git

# --- 2. Включение сервисов runit ---
echo "[2/5] Включаю системные сервисы..."

# seatd нужен чтобы Hyprland получил доступ к графическому устройству
sudo xbps-install -Sy seatd

# Добавляем пользователя в группу _seatd — без этого Hyprland не запустится
sudo usermod -aG _seatd "$USER"
echo "  ✓ Пользователь $USER добавлен в группу _seatd"

for svc in dbus seatd elogind NetworkManager bluetoothd sddm; do
    if [ ! -L "/var/service/$svc" ]; then
        sudo ln -s "/etc/sv/$svc" "/var/service/$svc"
        echo "  ✓ $svc"
    else
        echo "  · $svc уже включён"
    fi
done

# --- 3. Установка PipeWire через сервисы ---
for svc in pipewire wireplumber; do
    if [ -d "/etc/sv/$svc" ] && [ ! -L "/var/service/$svc" ]; then
        sudo ln -s "/etc/sv/$svc" "/var/service/$svc"
        echo "  ✓ $svc"
    fi
done

# --- 4. Копирование dotfiles ---
echo "[3/5] Копирую dotfiles..."
mkdir -p \
    "$HOME/.config/hypr/scripts" \
    "$HOME/.config/waybar/scripts/bluetooth-widget" \
    "$HOME/.config/waybar/scripts/shutdown" \
    "$HOME/.config/waybar/scripts/view-mode-widget" \
    "$HOME/.config/waybar/scripts/volume-widget" \
    "$HOME/.config/rofi" \
    "$HOME/.config/mako" \
    "$HOME/.config/neofetch" \
    "$HOME/.config/clipse" \
    "$HOME/.config/foot" \
    "$HOME/.config/kitty" \
    "$HOME/.config/fish/conf.d" \
    "$WALLPAPER_DIR" \
    "$SCRIPTS_DIR/rofi-run-on-current-workspace" \
    "$SCRIPTS_DIR/shutdown"

# Hyprland
cp -rv "$DOTFILES_DIR/dotfiles/hypr/"* "$HOME/.config/hypr/"

# Waybar
cp -rv "$DOTFILES_DIR/dotfiles/waybar/config" "$HOME/.config/waybar/"
cp -rv "$DOTFILES_DIR/dotfiles/waybar/style.css" "$HOME/.config/waybar/"
cp -rv "$DOTFILES_DIR/dotfiles/waybar/mouse.sh" "$HOME/.config/waybar/"
cp -rv "$DOTFILES_DIR/dotfiles/waybar/scripts/"* "$HOME/.config/waybar/scripts/"

# Скрипты shutdown → ~/Scripts
cp -v "$DOTFILES_DIR/dotfiles/waybar/scripts/shutdown/main.sh" "$SCRIPTS_DIR/shutdown/main.sh"
cp -v "$DOTFILES_DIR/dotfiles/waybar/scripts/shutdown/opening.sh" "$SCRIPTS_DIR/shutdown/opening.sh"

# Rofi
cp -rv "$DOTFILES_DIR/dotfiles/rofi/"* "$HOME/.config/rofi/"

# Mako
cp -v "$DOTFILES_DIR/dotfiles/mako/config" "$HOME/.config/mako/config"

# Neofetch
cp -v "$DOTFILES_DIR/dotfiles/neofetch/config.conf" "$HOME/.config/neofetch/config.conf"

# Clipse
cp -rv "$DOTFILES_DIR/dotfiles/clipse/"* "$HOME/.config/clipse/"

# Терминалы
cp -v "$DOTFILES_DIR/terminal-colors/foot/foot.ini" "$HOME/.config/foot/foot.ini"
cp -v "$DOTFILES_DIR/terminal-colors/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
cp -v "$DOTFILES_DIR/terminal-colors/fish/config.fish" "$HOME/.config/fish/config.fish"
cp -v "$DOTFILES_DIR/terminal-colors/fish/fish_variables" "$HOME/.config/fish/fish_variables"
cp -v "$DOTFILES_DIR/terminal-colors/fish/conf.d/"* "$HOME/.config/fish/conf.d/"

# Обои
cp -v "$DOTFILES_DIR/wallpapers and backgrounds/"* "$WALLPAPER_DIR/"

# Сделать скрипты исполняемыми
find "$HOME/.config/hypr/scripts" "$HOME/.config/waybar/scripts" "$SCRIPTS_DIR" \
    -name "*.sh" -exec chmod +x {} \;

echo "  ✓ Dotfiles скопированы"

# --- 5. SDDM тема ---
echo "[4/5] Устанавливаю SDDM тему..."
sudo cp -r "$DOTFILES_DIR/sddm-theme/plasma-login-kawaiki" /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << 'EOF'
[Theme]
Current=plasma-login-kawaiki
EOF
echo "  ✓ SDDM тема установлена"

# --- 6. Fish как дефолтный шелл ---
echo "[5/5] Устанавливаю fish как дефолтный шелл..."
if ! grep -q fish /etc/shells; then
    which fish | sudo tee -a /etc/shells > /dev/null
fi
chsh -s "$(which fish)"
echo "  ✓ Fish установлен как дефолтный шелл"

# --- Финал ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║            Установка завершена!           ║"
echo "╠══════════════════════════════════════════╣"
echo "║                                          ║"
echo "║  ⚠  ВАЖНО: перезагрузись полностью!      ║"
echo "║  Группа _seatd применится только после   ║"
echo "║  перезагрузки, не просто re-login.        ║"
echo "║                                          ║"
echo "║  Следующие шаги:                         ║"
echo "║  1. Перезагрузись (reboot)               ║"
echo "║  2. На экране SDDM выбери Hyprland        ║"
echo "║  3. Обои берутся из ~/Pictures/wallpapers ║"
echo "║                                          ║"
echo "║  Горячие клавиши:                        ║"
echo "║  Super+T     → терминал                  ║"
echo "║  Super+X     → rofi лаунчер              ║"
echo "║  Super+E     → файловый менеджер (yazi)  ║"
echo "║  Super+H     → скрыть/показать waybar    ║"
echo "║  Super+Q     → закрыть окно              ║"
echo "║                                          ║"
echo "╚══════════════════════════════════════════╝"
