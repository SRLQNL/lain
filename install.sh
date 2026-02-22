#!/usr/bin/env bash
# =============================================================================
#  Void Linux — Hyprland Setup Script
#  Запускай от обычного пользователя: bash install.sh
# =============================================================================
set -euo pipefail

# --- Цвета ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()   { echo -e "${BLUE}[>>]${NC} $*"; }
ok()     { echo -e "${GREEN}[ok]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
die()    { echo -e "${RED}[ERR]${NC} $*" >&2; exit 1; }
hdr()    { echo -e "\n${BOLD}${BLUE}══════ $* ══════${NC}"; }

# =============================================================================
# Проверки
# =============================================================================
hdr "Проверка окружения"

[ -f /etc/os-release ] && grep -qi "void" /etc/os-release \
    || die "Скрипт рассчитан на Void Linux."

[ "$EUID" -ne 0 ] \
    || die "Запусти как обычный пользователь, не root. sudo вызовется сам."

command -v sudo &>/dev/null \
    || die "sudo не установлен. Установи: xbps-install -S sudo, добавь себя в wheel."

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

info "Dotfiles : $DOTFILES"
info "Пользователь: $USER  Домашняя: $HOME"

# =============================================================================
# 1. Обновление репозиториев
# =============================================================================
hdr "Обновление репозиториев"
sudo xbps-install -Syu --yes
ok "Репозитории обновлены"

# =============================================================================
# 2. Пакеты из xbps
# =============================================================================
hdr "Установка пакетов из xbps"

# Пакеты, точно присутствующие в void repos
XBPS_PKGS=(
    # Wayland / Hyprland
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-user-dirs

    # Статус-бар
    waybar

    # Терминал
    alacritty

    # Shell
    fish-shell

    # Лаунчеры
    rofi-wayland
    wofi

    # Скриншоты
    grim
    slurp

    # Буфер обмена
    wl-clipboard

    # Звук
    pipewire
    wireplumber
    pavucontrol
    pamixer

    # Яркость и медиа
    brightnessctl
    playerctl

    # Приложения
    nautilus
    gnome-text-editor
    blueman
    neofetch
    xfce4-taskmanager
    firefox

    # Системные
    dbus
    git
    curl
    wget
    unzip
    tar
    python3
    python3-pip
    fontconfig
    noto-fonts-ttf
    noto-fonts-cjk
)

# Пакеты, которые МОГУТ быть в репо (пробуем — не паникуем при ошибке)
XBPS_OPTIONAL=(
    hyprlock
    swww
    swaync
    swaynotificationcenter
    wlogout
    cliphist
    hyprshade
    ly
    greetd
    greetd-tuigreet
)

# Устанавливаем основные пакеты
info "Устанавливаю основные пакеты..."
sudo xbps-install -y "${XBPS_PKGS[@]}" || true

# Пробуем опциональные по одному
info "Пробую опциональные пакеты..."
for pkg in "${XBPS_OPTIONAL[@]}"; do
    if sudo xbps-install -y "$pkg" 2>/dev/null; then
        ok "  $pkg"
    else
        warn "  $pkg — не найден в репо (установим вручную)"
    fi
done

# =============================================================================
# 3. Ручная установка пакетов не из репо
# =============================================================================
hdr "Ручная установка отсутствующих пакетов"

ARCH="$(uname -m)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- swww (daemon обоев) ---
if ! command -v swww &>/dev/null; then
    info "Устанавливаю swww..."
    SWWW_VER="0.9.5"
    SWWW_URL="https://github.com/LGFae/swww/releases/download/v${SWWW_VER}/swww-${ARCH}-unknown-linux-musl.tar.gz"
    if curl -fsSL "$SWWW_URL" -o "$TMP/swww.tar.gz"; then
        tar -xf "$TMP/swww.tar.gz" -C "$TMP"
        sudo install -Dm755 "$TMP/swww"        /usr/local/bin/swww
        sudo install -Dm755 "$TMP/swww-daemon" /usr/local/bin/swww-daemon
        ok "swww установлен"
    else
        warn "swww: не удалось скачать. Установи вручную: https://github.com/LGFae/swww"
    fi
fi

# --- cliphist (история буфера обмена) ---
if ! command -v cliphist &>/dev/null; then
    info "Устанавливаю cliphist..."
    CLIPHIST_VER="0.6.1"
    CLIPHIST_URL="https://github.com/sentriz/cliphist/releases/download/v${CLIPHIST_VER}/v${CLIPHIST_VER}-linux-${ARCH}"
    if curl -fsSL "$CLIPHIST_URL" -o "$TMP/cliphist"; then
        sudo install -Dm755 "$TMP/cliphist" /usr/local/bin/cliphist
        ok "cliphist установлен"
    else
        warn "cliphist: не удалось скачать."
    fi
fi

# --- swaync / SwayNotificationCenter ---
if ! command -v swaync &>/dev/null; then
    info "Устанавливаю swaync..."
    SWAYNC_VER="0.10.1"
    SWAYNC_URL="https://github.com/ErikReider/SwayNotificationCenter/releases/download/v${SWAYNC_VER}/swaync-v${SWAYNC_VER}-x86_64.tar.gz"
    if [ "$ARCH" = "x86_64" ] && curl -fsSL "$SWAYNC_URL" -o "$TMP/swaync.tar.gz"; then
        tar -xf "$TMP/swaync.tar.gz" -C "$TMP"
        # Бинарник может быть в разных местах внутри архива
        SWAYNC_BIN="$(find "$TMP" -name 'swaync' -type f | head -1)"
        if [ -n "$SWAYNC_BIN" ]; then
            sudo install -Dm755 "$SWAYNC_BIN" /usr/local/bin/swaync
            ok "swaync установлен"
        fi
    else
        warn "swaync: не удалось скачать (только x86_64). Попробуй: xbps-install -S swaync"
    fi
fi

# --- wlogout ---
if ! command -v wlogout &>/dev/null; then
    warn "wlogout не найден в репо. Установи вручную при необходимости."
    warn "  https://github.com/ArtsyMacaw/wlogout"
fi

# --- hyprshade (Python) ---
if ! command -v hyprshade &>/dev/null; then
    info "Устанавливаю hyprshade (pip)..."
    pip3 install --user hyprshade 2>/dev/null && ok "hyprshade установлен" \
        || warn "hyprshade: ошибка установки через pip"
fi

# --- hyprlock (если не установился из репо) ---
if ! command -v hyprlock &>/dev/null; then
    warn "hyprlock не найден. Установи вручную: https://github.com/hyprwm/hyprlock"
fi

# =============================================================================
# 4. Менеджер входа (ly)
# =============================================================================
hdr "Менеджер входа"

if command -v ly &>/dev/null; then
    info "Включаю ly в автозапуск..."
    sudo ln -sfn /etc/sv/ly /var/service/ 2>/dev/null && ok "ly включён" \
        || warn "Не удалось включить ly."
else
    warn "ly не найден. Hyprland можно запускать вручную с TTY:"
    warn "  Добавь в ~/.bash_profile или ~/.zprofile:"
    warn "    if [ -z \"\$WAYLAND_DISPLAY\" ] && [ \"\$XDG_VTNR\" = \"1\" ]; then"
    warn "      exec Hyprland"
    warn "    fi"

    # Автоматически добавим запуск в .bash_profile если ly не установлен
    BASH_PROFILE="$HOME/.bash_profile"
    if ! grep -q "exec Hyprland" "$BASH_PROFILE" 2>/dev/null; then
        info "Добавляю автозапуск Hyprland в $BASH_PROFILE..."
        cat >> "$BASH_PROFILE" <<'EOF'

# Автозапуск Hyprland на TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec Hyprland
fi
EOF
        ok "Автозапуск добавлен в $BASH_PROFILE"
    fi
fi

# =============================================================================
# 5. Системные сервисы (runit)
# =============================================================================
hdr "Включение системных сервисов"

SERVICES=(dbus bluetoothd)
for svc in "${SERVICES[@]}"; do
    if [ -d "/etc/sv/$svc" ]; then
        sudo ln -sfn "/etc/sv/$svc" /var/service/ 2>/dev/null && ok "$svc включён" \
            || warn "$svc: уже включён или ошибка"
    else
        warn "Сервис не найден: $svc"
    fi
done

# =============================================================================
# 6. Установка шрифтов
# =============================================================================
hdr "Установка шрифтов"

FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

if [ -d "$DOTFILES/additional-assets" ]; then
    FONT_COUNT=0
    for font_archive in "$DOTFILES/additional-assets"/Font_*.tar.gz; do
        [ -f "$font_archive" ] || continue
        font_name="$(basename "$font_archive" .tar.gz)"
        info "  Распаковываю: $font_name"
        tar -xf "$font_archive" -C "$FONTS_DIR" 2>/dev/null && FONT_COUNT=$((FONT_COUNT+1)) \
            || warn "  Не удалось распаковать: $font_name"
    done

    if [ "$FONT_COUNT" -gt 0 ]; then
        fc-cache -f "$FONTS_DIR" && ok "$FONT_COUNT шрифтов установлено"
    else
        warn "Шрифты не найдены в additional-assets/"
    fi
else
    warn "Папка additional-assets/ не найдена"
fi

# =============================================================================
# 7. Курсор Bibata-Modern-Classic
# =============================================================================
hdr "Установка курсора Bibata"

ICONS_DIR="$HOME/.local/share/icons"
mkdir -p "$ICONS_DIR"

if ! [ -d "$ICONS_DIR/Bibata-Modern-Classic" ]; then
    info "Скачиваю Bibata-Modern-Classic..."
    BIBATA_URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz"
    if curl -fsSL "$BIBATA_URL" -o "$TMP/bibata.tar.xz"; then
        tar -xf "$TMP/bibata.tar.xz" -C "$ICONS_DIR"
        ok "Bibata-Modern-Classic установлен"
    else
        warn "Bibata: не удалось скачать."
    fi
else
    ok "Bibata-Modern-Classic уже установлен"
fi

# =============================================================================
# 8. Копирование dotfiles
# =============================================================================
hdr "Копирование конфигов"

# ~/.config/*
if [ -d "$DOTFILES/.config" ]; then
    mkdir -p "$HOME/.config"
    cp -r "$DOTFILES/.config/"* "$HOME/.config/"
    ok "Конфиги скопированы в ~/.config/"
fi

# Файлы из home/ (без скрытых — это .bashrc и т.п.)
if [ -d "$DOTFILES/home" ]; then
    for f in "$DOTFILES/home"/.[!.]* "$DOTFILES/home"/*; do
        [ -e "$f" ] || continue
        fname="$(basename "$f")"
        cp -r "$f" "$HOME/$fname"
        ok "  Скопирован: ~/$fname"
    done
fi

# =============================================================================
# 9. Копирование обоев
# =============================================================================
hdr "Копирование обоев"

mkdir -p "$WALLPAPER_DIR"
mkdir -p "$HOME/.cache/rofi-wallpapers"

if [ -d "$DOTFILES/wallpapers" ]; then
    cp "$DOTFILES/wallpapers/"* "$WALLPAPER_DIR/" 2>/dev/null && \
        ok "Обои скопированы в $WALLPAPER_DIR"
fi

# =============================================================================
# 10. Исправление путей в конфигах
# =============================================================================
hdr "Исправление путей"

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

# --- hyprland.conf ---
if [ -f "$HYPR_CONF" ]; then
    # Заменяем захардкоженного пользователя
    sed -i "s|/home/anik|$HOME|g" "$HYPR_CONF"

    # Указываем первый доступный обой
    FIRST_WALL="$(ls "$WALLPAPER_DIR"/*.{jpg,jpeg,png,gif} 2>/dev/null | head -1 || true)"
    if [ -n "$FIRST_WALL" ]; then
        # Добавляем запуск swww после daemon
        sed -i "s|exec-once=swww-daemon --format xrgb|exec-once=swww-daemon --format xrgb\nexec-once=sleep 1 \&\& swww img \"$FIRST_WALL\"|" "$HYPR_CONF"
        info "Обой по умолчанию: $FIRST_WALL"
    fi

    # Комментируем AGS (не установлен на чистом void)
    sed -i 's|^exec-once=/usr/local/bin/ags|#exec-once=/usr/local/bin/ags  # AGS: установи вручную при необходимости|g' "$HYPR_CONF"
    sed -i 's|^bind = \$mainMod, Z, exec, /usr/local/bin/ags|#bind = $mainMod, Z, exec, /usr/local/bin/ags|g' "$HYPR_CONF"

    ok "hyprland.conf обновлён"
fi

# --- wofi.sh — меняем директорию обоев ---
WOFI_SCRIPT="$HOME/wofi.sh"
if [ -f "$WOFI_SCRIPT" ]; then
    sed -i "s|WALLPAPER_DIR=\".*\"|WALLPAPER_DIR=\"$WALLPAPER_DIR\"|g" "$WOFI_SCRIPT"
    chmod +x "$WOFI_SCRIPT"
    ok "wofi.sh обновлён (WALLPAPER_DIR=$WALLPAPER_DIR)"
fi

# --- fish/config.fish — убираем /home/anik ---
FISH_CONF="$HOME/.config/fish/config.fish"
if [ -f "$FISH_CONF" ]; then
    sed -i "s|/home/anik|$HOME|g" "$FISH_CONF"
    ok "fish config обновлён"
fi

# =============================================================================
# 11. XDG директории
# =============================================================================
hdr "XDG директории"
xdg-user-dirs-update && ok "XDG директории созданы"

# =============================================================================
# 12. Установка fish как shell (опционально)
# =============================================================================
hdr "Установка fish shell"
if command -v fish &>/dev/null; then
    FISH_PATH="$(command -v fish)"
    # Добавляем fish в /etc/shells если ещё нет
    grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null || echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    info "Fish shell доступен по: $FISH_PATH"
    info "Чтобы сделать fish дефолтным: chsh -s $FISH_PATH"
else
    warn "fish не найден"
fi

# =============================================================================
# Итог
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║          Установка завершена успешно!                ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Что дальше:${NC}"
echo ""
echo -e "  1. Перезагрузись:  ${BOLD}sudo reboot${NC}"
echo ""

if command -v ly &>/dev/null; then
    echo -e "  2. На экране ly выбери сессию ${BOLD}Hyprland${NC}"
else
    echo -e "  2. Войди на TTY1 — Hyprland запустится автоматически"
    echo -e "     (или вручную: ${BOLD}Hyprland${NC})"
fi

echo ""
echo -e "  ${BOLD}Клавиши Hyprland:${NC}"
echo "    Super+Q   → Терминал (alacritty)"
echo "    Super+E   → Файловый менеджер (nautilus)"
echo "    Super+A   → Rofi (лаунчер приложений)"
echo "    Super+R   → Wofi (лаунчер)"
echo "    Super+W   → Смена обоев (wofi.sh)"
echo "    Super+L   → Экран блокировки (hyprlock)"
echo "    Super+G   → Звук (pavucontrol)"
echo "    Super+T   → Task Manager"
echo "    Super+\`   → Обзор воркспейсов (hyprexpo)"
echo "    Alt+S     → Скриншот в буфер"
echo "    Super+O   → История буфера обмена"
echo ""
echo -e "  ${BOLD}Обои:${NC} $WALLPAPER_DIR"
echo -e "  ${BOLD}Конфиг Hyprland:${NC} ~/.config/hypr/hyprland.conf"
echo -e "  ${BOLD}Конфиг Waybar:${NC}  ~/.config/waybar/config.jsonc"
echo ""
echo -e "  ${YELLOW}Замечание:${NC} AGS (Super+Z) требует отдельной установки."
echo -e "  Подробнее: ${BOLD}https://aylur.github.io/ags-docs/${NC}"
echo ""
