#!/bin/bash
# =====================================================================
# Установщик Lain Rice для Void Linux (glibc)
# =====================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SCRIPTS_DIR="$HOME/Scripts"

echo "╔══════════════════════════════════════════╗"
echo "║   Lain Rice — Установщик для Void Linux  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# =====================================================================
# 0. Репозиторий Hyprland для Void
# =====================================================================
echo "[0/6] Подключаю репозиторий hyprland-void..."
HYPR_REPO_FILE="/etc/xbps.d/hyprland-void.conf"
if [ ! -f "$HYPR_REPO_FILE" ]; then
    echo "repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc" \
        | sudo tee "$HYPR_REPO_FILE" > /dev/null
    echo "  ✓ Репозиторий добавлен"
else
    echo "  · Репозиторий уже подключён"
fi

sudo xbps-install -S
echo "  ✓ Репозиторий синхронизирован"

# =====================================================================
# 1. Установка пакетов
# =====================================================================
echo "[1/6] Устанавливаю пакеты через xbps..."
sudo xbps-install -Sy \
    hyprland \
    xdg-desktop-portal-hyprland \
    hyprpaper \
    hypridle \
    hyprlock \
    hyprland-qtutils \
    Waybar \
    rofi \
    mako \
    sddm \
    foot \
    kitty \
    fish-shell \
    starship \
    fastfetch \
    mpv \
    Thunar \
    yazi \
    NetworkManager \
    network-manager-applet \
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
    elogind \
    dbus \
    xdg-user-dirs \
    bat \
    eza \
    ugrep \
    tty-clock \
    find-the-command \
    jq \
    git \
    python3 \
    python3-pip \
    font-jetbrains-mono \
    nerd-fonts-symbols-only

echo "  ✓ Основные пакеты установлены"

# =====================================================================
# 2. Установка clipse (менеджер буфера обмена)
# =====================================================================
echo "[2a] Устанавливаю clipse..."
CLIPSE_VERSION="1.2.0"
CLIPSE_BIN="$HOME/.local/bin/clipse"
mkdir -p "$HOME/.local/bin"

if [ ! -f "$CLIPSE_BIN" ]; then
    TMP_DIR=$(mktemp -d)
    ARCH="amd64"
    CLIPSE_URL="https://github.com/savedra1/clipse/releases/download/v${CLIPSE_VERSION}/clipse_${CLIPSE_VERSION}_linux_${ARCH}.tar.gz"
    echo "  Скачиваю clipse v${CLIPSE_VERSION}..."
    if curl -fsSL "$CLIPSE_URL" -o "$TMP_DIR/clipse.tar.gz" 2>/dev/null; then
        tar -xzf "$TMP_DIR/clipse.tar.gz" -C "$TMP_DIR"
        install -m 755 "$TMP_DIR/clipse" "$CLIPSE_BIN"
        rm -rf "$TMP_DIR"
        echo "  ✓ clipse установлен в ~/.local/bin/clipse"
    else
        echo "  ⚠ Не удалось скачать clipse. Установи вручную:"
        echo "    https://github.com/savedra1/clipse/releases"
        echo "    Положи бинарник в ~/.local/bin/clipse"
    fi
else
    echo "  · clipse уже установлен"
fi

# =====================================================================
# 2b. Установка unimatrix (виджет матрицы на рабочем столе)
# =====================================================================
echo "[2b] Устанавливаю unimatrix..."
if ! command -v unimatrix &>/dev/null; then
    pip install unimatrix --break-system-packages 2>/dev/null && \
        echo "  ✓ unimatrix установлен" || \
        echo "  ⚠ Не удалось установить unimatrix через pip"
else
    echo "  · unimatrix уже установлен"
fi

# =====================================================================
# 3. Группы пользователя и сервисы
# =====================================================================
echo "[3/6] Настраиваю сервисы и группы..."

# Только elogind — не seatd. Они конфликтуют!
for grp in video audio input wheel; do
    if id -nG "$USER" | grep -qw "$grp"; then
        echo "  · Группа $grp уже добавлена"
    else
        sudo usermod -aG "$grp" "$USER"
        echo "  ✓ Пользователь $USER добавлен в группу $grp"
    fi
done

for svc in dbus elogind NetworkManager bluetoothd sddm; do
    if [ ! -L "/var/service/$svc" ]; then
        sudo ln -s "/etc/sv/$svc" "/var/service/$svc"
        echo "  ✓ $svc включён"
    else
        echo "  · $svc уже включён"
    fi
done

# PipeWire запускается через hyprland (exec-once), не нужен как сервис
echo "  · PipeWire и WirePlumber запускаются из Hyprland (exec-once)"

echo "  ✓ Сервисы настроены"

# =====================================================================
# 4. Копирование dotfiles
# =====================================================================
echo "[4/6] Копирую dotfiles..."
mkdir -p \
    "$HOME/.config/hypr/scripts" \
    "$HOME/.config/waybar/scripts/bluetooth-widget" \
    "$HOME/.config/waybar/scripts/shutdown" \
    "$HOME/.config/waybar/scripts/view-mode-widget" \
    "$HOME/.config/waybar/scripts/volume-widget" \
    "$HOME/.config/rofi" \
    "$HOME/.config/mako" \
    "$HOME/.config/fastfetch" \
    "$HOME/.config/clipse" \
    "$HOME/.config/foot" \
    "$HOME/.config/kitty" \
    "$HOME/.config/fish/conf.d" \
    "$WALLPAPER_DIR" \
    "$SCRIPTS_DIR/rofi-run-on-current-workspace" \
    "$SCRIPTS_DIR/shutdown" \
    "$SCRIPTS_DIR/view-mode-widget" \
    "$SCRIPTS_DIR/volume-widget"

# Hyprland
cp -rv "$DOTFILES_DIR/dotfiles/hypr/"* "$HOME/.config/hypr/"

# Waybar
cp -rv "$DOTFILES_DIR/dotfiles/waybar/config" "$HOME/.config/waybar/"
cp -rv "$DOTFILES_DIR/dotfiles/waybar/style.css" "$HOME/.config/waybar/"
cp -rv "$DOTFILES_DIR/dotfiles/waybar/mouse.sh" "$HOME/.config/waybar/"
cp -rv "$DOTFILES_DIR/dotfiles/waybar/scripts/"* "$HOME/.config/waybar/scripts/"

# Скрипты
cp -v "$DOTFILES_DIR/dotfiles/waybar/scripts/shutdown/main.sh" "$SCRIPTS_DIR/shutdown/main.sh"
cp -v "$DOTFILES_DIR/dotfiles/waybar/scripts/shutdown/opening.sh" "$SCRIPTS_DIR/shutdown/opening.sh"
cp -v "$DOTFILES_DIR/dotfiles/waybar/scripts/view-mode-widget/main.py" "$SCRIPTS_DIR/view-mode-widget/main.py"
cp -v "$DOTFILES_DIR/dotfiles/waybar/scripts/volume-widget/main.sh" "$SCRIPTS_DIR/volume-widget/main.sh"

# Rofi launcher скрипт
cp -v "$DOTFILES_DIR/Scripts/rofi-run-on-current-workspace/main.sh" "$SCRIPTS_DIR/rofi-run-on-current-workspace/main.sh"

# Rofi
cp -rv "$DOTFILES_DIR/dotfiles/rofi/"* "$HOME/.config/rofi/"

# Mako
cp -v "$DOTFILES_DIR/dotfiles/mako/config" "$HOME/.config/mako/config"

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

# Права на выполнение
find "$HOME/.config/hypr/scripts" "$HOME/.config/waybar/scripts" "$SCRIPTS_DIR" \
    -name "*.sh" -exec chmod +x {} \;
find "$HOME/.config/waybar/scripts" \
    -name "*.py" -exec chmod +x {} \;
chmod +x "$SCRIPTS_DIR/view-mode-widget/main.py"

echo "  ✓ Dotfiles скопированы"

# =====================================================================
# 5. SDDM тема
# =====================================================================
echo "[5/6] Устанавливаю SDDM тему..."
sudo cp -r "$DOTFILES_DIR/sddm-theme/plasma-login-kawaiki" /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << 'EOF'
[Theme]
Current=plasma-login-kawaiki
EOF
echo "  ✓ SDDM тема установлена"

# =====================================================================
# 6. Fish как дефолтный шелл
# =====================================================================
echo "[6/6] Устанавливаю fish как дефолтный шелл..."
FISH_PATH="$(which fish)"
if ! grep -qF "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
fi
chsh -s "$FISH_PATH"
echo "  ✓ Fish установлен как дефолтный шелл"

# =====================================================================
# Финал
# =====================================================================
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║            Установка завершена!                      ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║                                                      ║"
echo "║  ⚠  ОБЯЗАТЕЛЬНО: перезагрузись полностью!           ║"
echo "║  Группы video/audio/input применяются только        ║"
echo "║  после полной перезагрузки (не re-login).            ║"
echo "║                                                      ║"
echo "║  Опциональные приложения (нет в Void репо):          ║"
echo "║  Установи через Flatpak если нужны:                  ║"
echo "║    flatpak install app.librewolf.librewolf           ║"
echo "║    flatpak install org.telegram.desktop              ║"
echo "║    flatpak install com.spotify.Client                ║"
echo "║  После установки раскомментируй строки в             ║"
echo "║  ~/.config/hypr/hyprland.conf (секция автозапуск)   ║"
echo "║                                                      ║"
echo "║  Nerd Fonts (если иконки не отображаются):           ║"
echo "║  sudo xbps-install nerd-fonts                        ║"
echo "║  Или скачай JetBrainsMono Nerd Font с:               ║"
echo "║    https://www.nerdfonts.com/font-downloads          ║"
echo "║  Положи в ~/.local/share/fonts/ и запусти:           ║"
echo "║    fc-cache -fv                                      ║"
echo "║                                                      ║"
echo "║  Горячие клавиши:                                    ║"
echo "║  Super+T     → терминал (foot)                       ║"
echo "║  Super+X     → rofi лаунчер                          ║"
echo "║  Super+E     → файловый менеджер (yazi)              ║"
echo "║  Super+Shift+E → Thunar (GUI)                        ║"
echo "║  Super+V     → менеджер буфера (clipse)              ║"
echo "║  Super+Q     → закрыть окно                          ║"
echo "║  Super+H     → скрыть/показать waybar                ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
