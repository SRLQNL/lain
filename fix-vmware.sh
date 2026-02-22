#!/usr/bin/env bash
# =============================================================================
#  Фикс запуска Hyprland на VMware
#  Запускай из TTY: bash fix-vmware.sh
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${BLUE}[>>]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
die()   { echo -e "${RED}[ERR]${NC} $*" >&2; exit 1; }
hdr()   { echo -e "\n${BOLD}${BLUE}══════ $* ══════${NC}"; }

[ "$EUID" -ne 0 ] || die "Запусти как обычный пользователь."

# =============================================================================
# 1. Диагностика
# =============================================================================
hdr "Диагностика"

info "Ядро: $(uname -r)"
info "Arch: $(uname -m)"

# Проверяем DRM-устройства
info "DRM-устройства:"
ls /dev/dri/ 2>/dev/null && ok "DRM-устройства найдены" \
    || { warn "DRM-устройства не найдены! Wayland не запустится."; }

# Проверяем vmwgfx
info "Статус модуля vmwgfx:"
if lsmod | grep -q vmwgfx; then
    ok "vmwgfx загружен"
else
    warn "vmwgfx не загружен — попробуем загрузить"
fi

# Проверяем сервис ly
info "Статус ly:"
if sv status ly 2>/dev/null; then
    ok "ly работает"
else
    warn "ly не запущен или не установлен"
fi

# Проверяем Hyprland
info "Hyprland:"
command -v Hyprland &>/dev/null && ok "Hyprland найден: $(command -v Hyprland)" \
    || die "Hyprland не установлен! Запусти install.sh заново."

# =============================================================================
# 2. Установка VMware-пакетов
# =============================================================================
hdr "Установка VMware guest пакетов"

VMWARE_PKGS=(
    open-vm-tools       # VMware Guest Additions
    mesa-dri            # Mesa драйверы (включая vmwgfx)
    mesa-vulkan-vmwgfx  # Vulkan для VMware (если есть в репо)
    xf86-video-vmware   # X11 VMware driver (для совместимости)
    linux-headers       # Заголовки ядра (для модулей)
)

for pkg in "${VMWARE_PKGS[@]}"; do
    sudo xbps-install -y "$pkg" 2>/dev/null && ok "Установлен: $pkg" \
        || warn "Не найден в репо: $pkg (некритично)"
done

# =============================================================================
# 3. Загрузка модулей ядра
# =============================================================================
hdr "Загрузка модулей ядра"

MODULES=(vmwgfx drm drm_kms_helper)
for mod in "${MODULES[@]}"; do
    if sudo modprobe "$mod" 2>/dev/null; then
        ok "Модуль загружен: $mod"
    else
        warn "Не удалось загрузить: $mod"
    fi
done

# Добавляем vmwgfx в автозагрузку
MODULES_LOAD="/etc/modules-load.d/vmware.conf"
if ! [ -f "$MODULES_LOAD" ]; then
    echo "vmwgfx" | sudo tee "$MODULES_LOAD" > /dev/null
    ok "vmwgfx добавлен в автозагрузку"
fi

# =============================================================================
# 4. Фикс переменных окружения для VMware в hyprland.conf
# =============================================================================
hdr "Патч hyprland.conf для VMware"

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

if [ ! -f "$HYPR_CONF" ]; then
    die "hyprland.conf не найден: $HYPR_CONF"
fi

# Создаём резервную копию
cp "$HYPR_CONF" "${HYPR_CONF}.bak"
info "Резервная копия: ${HYPR_CONF}.bak"

# Проверяем, не применён ли патч уже
if grep -q "WLR_NO_HARDWARE_CURSORS" "$HYPR_CONF"; then
    ok "Патч VMware уже применён"
else
    # Вставляем VMware-переменные после блока env
    python3 - "$HYPR_CONF" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

vmware_env = """
# ── VMware fixes ──────────────────────────────────────────────
env = WLR_NO_HARDWARE_CURSORS,1      # обязательно для VMware
env = WLR_RENDERER_ALLOW_SOFTWARE,1  # разрешить software renderer
env = LIBSEAT_BACKEND,logind         # seat manager
env = XDG_SESSION_TYPE,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = MOZ_ENABLE_WAYLAND,1
# ─────────────────────────────────────────────────────────────
"""

# Вставляем после строки "env = XDG_SESSION_DESKTOP,Hyprland"
anchor = 'env = XDG_SESSION_DESKTOP,Hyprland'
if anchor in content:
    content = content.replace(anchor, anchor + vmware_env, 1)
else:
    # fallback: вставляем в начало
    content = vmware_env + content

with open(path, 'w') as f:
    f.write(content)

print("Patch applied.")
PYEOF
    ok "VMware env-переменные добавлены в hyprland.conf"
fi

# =============================================================================
# 5. Настройка ly (если установлен)
# =============================================================================
hdr "Настройка менеджера входа"

if command -v ly &>/dev/null; then
    # Включаем сервис
    sudo ln -sfn /etc/sv/ly /var/service/ 2>/dev/null || true

    # Конфиг ly
    LY_CONF="/etc/ly/config.ini"
    if [ -f "$LY_CONF" ]; then
        # Убеждаемся что waylandcmd указан
        sudo sed -i 's/^#waylandcmd.*/waylandcmd = Hyprland/' "$LY_CONF" 2>/dev/null || true
    fi
    ok "ly настроен"
else
    warn "ly не установлен — используем запуск из TTY"

    # Надёжный вариант: .bash_profile
    BASH_PROFILE="$HOME/.bash_profile"
    FISH_LOGIN="$HOME/.config/fish/login.fish"

    # bash / zsh
    if ! grep -q "exec Hyprland" "$BASH_PROFILE" 2>/dev/null; then
        cat >> "$BASH_PROFILE" <<'EOF'

# Автозапуск Hyprland на TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
EOF
        ok "Автозапуск добавлен в $BASH_PROFILE"
    else
        ok "Автозапуск уже есть в $BASH_PROFILE"
    fi

    # fish shell
    mkdir -p "$(dirname "$FISH_LOGIN")"
    if ! grep -q "exec Hyprland" "$FISH_LOGIN" 2>/dev/null; then
        cat >> "$FISH_LOGIN" <<'EOF'

# Автозапуск Hyprland на TTY1
if test -z "$WAYLAND_DISPLAY" && test -z "$DISPLAY" && test (tty) = "/dev/tty1"
    exec Hyprland
end
EOF
        ok "Автозапуск добавлен в $FISH_LOGIN (fish)"
    fi
fi

# =============================================================================
# 6. Включение сервиса open-vm-tools
# =============================================================================
hdr "Сервис open-vm-tools"

if [ -d /etc/sv/vmtoolsd ]; then
    sudo ln -sfn /etc/sv/vmtoolsd /var/service/ 2>/dev/null || true
    ok "vmtoolsd включён"
elif command -v vmtoolsd &>/dev/null; then
    warn "vmtoolsd есть, но runit-сервис не найден — запустим вручную при старте"
fi

# =============================================================================
# 7. Тест: попытка запустить Hyprland сейчас
# =============================================================================
hdr "Тест запуска"

echo ""
echo -e "${BOLD}Хочешь попробовать запустить Hyprland прямо сейчас? (y/n)${NC}"
read -r TRY_NOW

if [[ "$TRY_NOW" =~ ^[Yy]$ ]]; then
    echo ""
    info "Запускаю Hyprland с VMware-переменными..."
    info "Если что-то пойдёт не так, лог будет в /tmp/hyprland-test.log"
    echo ""

    WLR_NO_HARDWARE_CURSORS=1 \
    WLR_RENDERER_ALLOW_SOFTWARE=1 \
    XDG_SESSION_TYPE=wayland \
    XDG_CURRENT_DESKTOP=Hyprland \
        Hyprland 2>&1 | tee /tmp/hyprland-test.log

    echo ""
    info "Если не запустился — смотри лог: cat /tmp/hyprland-test.log"
else
    echo ""
    ok "Перезагрузись: sudo reboot"
    echo ""
    info "Или запусти вручную:"
    echo "  WLR_NO_HARDWARE_CURSORS=1 Hyprland"
fi

# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Фикс VMware применён!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo "  Если Hyprland всё ещё не запускается:"
echo ""
echo "  1. Проверь DRM:   ls -la /dev/dri/"
echo "  2. Попробуй запустить вручную:"
echo "       WLR_NO_HARDWARE_CURSORS=1 Hyprland"
echo "  3. Посмотри лог:  journalctl -xe | grep -i hypr"
echo "  4. Или:           cat ~/.local/share/hyprland/hyprland.log"
echo ""
