## Fish config — Lain Rice, Void Linux
## Убраны все Arch/Garuda/pacman/systemd специфичные вещи

# Отключить приветствие
set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT "1"
set -x SHELL /usr/bin/fish

# man через bat
if command -v bat &>/dev/null
    set -xU MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -xU MANROFFOPT "-c"
end

# done plugin настройки
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

# .fish_profile
if test -f ~/.fish_profile
    source ~/.fish_profile
end

# ~/.local/bin в PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Starship prompt
if status --is-interactive
    if command -v starship &>/dev/null
        source (starship init fish --print-full-init | psub)
    end
end

# find-the-command (подсказки для неизвестных команд)
if test -f /usr/share/doc/find-the-command/ftc.fish
    source /usr/share/doc/find-the-command/ftc.fish
end

# =====================================================================
# Функции
# =====================================================================

# !! и !$ (история команд)
function __history_previous_command
    switch (commandline -t)
    case "!"
        commandline -t $history[1]; commandline -f repaint
    case "*"
        commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
    case "!"
        commandline -t ""
        commandline -f history-token-search-backward
    case "*"
        commandline -i '$'
    end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

# История с временем
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | string trim --right --chars=/)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# =====================================================================
# Aliases — замены стандартных утилит
# =====================================================================

# eza вместо ls
if command -v eza &>/dev/null
    alias ls 'eza -al --color=always --group-directories-first --icons'
    alias la 'eza -a --color=always --group-directories-first --icons'
    alias ll 'eza -l --color=always --group-directories-first --icons'
    alias lt 'eza -aT --color=always --group-directories-first --icons'
    alias l. 'eza -ald --color=always --group-directories-first --icons .*'
end

# bat вместо cat
if command -v bat &>/dev/null
    alias cat 'bat --style header --style snip --style changes --style header'
end

# ugrep вместо grep
if command -v ugrep &>/dev/null
    alias grep 'ugrep --color=auto'
    alias egrep 'ugrep -E --color=auto'
    alias fgrep 'ugrep -F --color=auto'
end

# =====================================================================
# Aliases — Void Linux (xbps)
# =====================================================================
alias xi 'sudo xbps-install -S'           # установить пакет
alias xu 'sudo xbps-install -Su'          # обновить систему
alias xr 'sudo xbps-remove -R'            # удалить пакет
alias xq 'xbps-query -Rs'                 # поиск пакета
alias xqi 'xbps-query -l'                 # список установленных
alias xlo 'sudo xbps-remove -Oo'          # удалить orphans
alias xup 'xbps-install -Mun'             # проверить обновления

# runit (Void init вместо systemctl)
alias sv 'sudo sv'
alias svs 'sudo sv status /var/service/*' # статус всех сервисов

# =====================================================================
# Общие aliases
# =====================================================================
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'
alias dir 'dir --color=auto'
alias vdir 'vdir --color=auto'
alias ip 'ip -color'
alias wget 'wget -c '
alias tarnow 'tar -acf '
alias untar 'tar -zxvf '
alias psmem 'ps auxf | sort -nr -k 4'
alias psmem10 'ps auxf | sort -nr -k 4 | head -10'
alias hw 'hwinfo --short'
alias please 'sudo'
alias tb 'nc termbin.com 9999'
alias helpme 'echo "Используй: tldr <команда>"'

# =====================================================================
# Запуск fastfetch при интерактивной сессии
# =====================================================================
if status --is-interactive
    if command -v fastfetch &>/dev/null
        fastfetch
    end
end
