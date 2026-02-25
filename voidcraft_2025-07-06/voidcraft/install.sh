#!/usr/bin/env bash

## Copyright (C) 2020-2025 Aditya Shakya <adi1090x@gmail.com>
##
## Archcraftify your Void Linux Installation
##
## It is advised that you install this on a fresh installation of Void Linux.
## Created on : void-live-x86_64-20250202-base.iso (https://repo-default.voidlinux.org/live/current/void-live-x86_64-20250202-base.iso)

## General --------------------------------------------

## ANSI Colors
RED="$(printf '\033[31m')"      GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[33m')"   BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"    BLACK="$(printf '\033[30m')"

## Global Variables
_dir="`pwd`"
_rootfs="$_dir/files"
_copy_cmd='sudo cp --preserve=mode --force --recursive'

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
    return
}

## Messages
show_msg() {
	if [[ "$1" == '-r' ]]; then
		{ echo -e ${RED}"$2"; reset_color; }
	elif [[ "$1" == '-g' ]]; then
		{ echo -e ${GREEN}"$2"; reset_color; }
	elif [[ "$1" == '-o' ]]; then
		{ echo -e ${ORANGE}"$2"; reset_color; }
	elif [[ "$1" == '-b' ]]; then
		{ echo -e ${BLUE}"$2"; reset_color; }
	elif [[ "$1" == '-m' ]]; then
		{ echo -e ${MAGENTA}"$2"; reset_color; }
	elif [[ "$1" == '-c' ]]; then
		{ echo -e ${CYAN}"$2"; reset_color; }
	fi
}

## Script termination
exit_on_signal_SIGINT() {
	show_msg -r "\n[!] Script interrupted.\n"
	exit 1
}

exit_on_signal_SIGTERM() {
	show_msg -r "\n[!] Script terminated.\n"
	exit 1
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## Packages -------------------------------------------

## List of packages
_failed_to_install=()
_packages=(
		  # boot splash
		  plymouth

		  # display manager
		  sddm
		  qt5-declarative
		  qt5-graphicaleffects
		  qt5-quickcontrols
		  qt5-quickcontrols2
		  qt5-svg

		  # full x11 server
		  xorg

		  # authorization tools
		  polkit
		  elogind
		  xfce-polkit

		  # network management daemon
		  NetworkManager
		  NetworkManager-l2tp
		  NetworkManager-openconnect
		  NetworkManager-openvpn
		  NetworkManager-pptp
		  NetworkManager-strongswan
		  NetworkManager-vpnc
		  network-manager-applet

		  # bluetooth tools
		  bluez
		  blueman

		  # printing system
		  cups
		  cups-filters
		  cups-pdf
		  ghostscript
		  foomatic-db
		  foomatic-db-engine
		  gsfonts
		  gutenprint

		  # disk management and filesystem
		  gvfs
		  gvfs-afc
		  gvfs-afp
		  gvfs-cdda
		  gvfs-gphoto2
		  gvfs-mtp
		  gvfs-smb
		  udiskie
		  udisks2
		  
		  # file manager functionalities
		  ffmpegthumbnailer
		  highlight
		  trash-cli
		  tumbler
		  ueberzug
		  xdg-user-dirs
		  xdg-user-dirs-gtk
		  thunar-archive-plugin
		  thunar-media-tags-plugin
		  thunar-volman

		  # audio
		  pipewire
		  wireplumber
		  pavucontrol
		  alsa-pipewire
		  alsa-plugins-jack
		  alsa-plugins-pulseaudio

		  # video
		  libde265
		  libmpeg2
		  libtheora
		  libvpx
		  x264
		  x265
		  xvidcore
		  gstreamer1
		  ffmpeg
		  gst-libav
		  gst-plugins-good1
		  gst-plugins-bad1
		  gst-plugins-ugly1
		  mesa-vaapi
		  mesa-vdpau

		  # images
		  jasper
		  libwebp
		  libavif
		  libheif

		  # fonts
		  noto-fonts-ttf 
		  noto-fonts-emoji
		  noto-fonts-ttf-extra

		  # openbox
		  openbox
		  obmenu-generator
		  perl-Linux-DesktopFiles
		  plank
		  tint2
		  xmlstarlet
		  xfce4-terminal
		  xfce4-settings

		  # bspwm
		  bspwm
		  sxhkd
		  feh
		  xsettingsd
		  
		  # i3wm
		  i3
		  i3status
		  hsetroot

		  # basic gui apps
		  alacritty
		  kitty
		  firefox
		  geany
		  geany-plugins
		  Thunar
		  viewnior
		  atril

		  # basic cli apps
		  htop
		  nethogs
		  ncdu
		  powertop
		  ranger
		  vim

		  # archives
		  bzip2
		  gzip
		  lrzip
		  lz4
		  lzip
		  lzop
		  p7zip
		  unzip
		  xz
		  xarchiver
		  zstd
		  zip

		  # utilities : qt
		  kvantum
		  qt5ct
		  qt6ct

		  # utilities : internet
		  curl
		  git
		  inetutils
		  wget

		  # utilities : multimedia
		  mpc
		  mpd
		  ncmpcpp
		  mplayer
		  pulsemixer

		  # utilities : information
		  neofetch
		  wireless_tools

		  # utilities : common tools
		  betterlockscreen
		  dunst
		  ksuperkey
		  nitrogen
		  pastel
		  picom
		  polybar
		  pywal
		  rofi
		  maim
		  slop

		  # utilities : power management
		  acpi
		  light
		  xfce4-power-manager

		  # utilities : misc
		  arandr
		  bc
		  dialog
		  galculator
		  gparted
		  gtk3-nocsd
		  gtk-engine-murrine
		  gnome-keyring
		  inotify-tools
		  jq
		  meld
		  nano
		  psmisc
		  sound-theme-freedesktop
		  wmctrl
		  wmname
		  xclip
		  xcolor
		  xdotool
		  yad
		  zsh
)

## Banner
banner() {
	clear
    cat <<- EOF
		${GREEN}░█░█░█▀█░▀█▀░█▀▄░█▀▀░█▀▄░█▀█░█▀▀░▀█▀
		${GREEN}░▀▄▀░█░█░░█░░█░█░█░░░█▀▄░█▀█░█▀▀░░█░
		${GREEN}░░▀░░▀▀▀░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀░░░░▀░${WHITE}
		
		${CYAN}Voidcraft    ${WHITE}: ${MAGENTA}Install Archcraft on Void Linux
		${CYAN}Developed By ${WHITE}: ${MAGENTA}Aditya Shakya (@adi1090x)
		
		${RED}Recommended  ${WHITE}: ${ORANGE}Install this on a fresh installation of Void Linux ${WHITE}
	EOF
}

## Check command status
check_cmd_status() {
	if [[ "$?" != '0' ]]; then
		{ show_msg -r "\n[!] Failed to $1 '$2' ${3}.\n"; exit 1; }
	fi
}

## Check internet connection
check_internet() {
	show_msg -b "\n[*] Checking for internet connection..."
	if ping -c 3 www.google.com &>/dev/null; then
		show_msg -g "[+] Connected to internet."
	else
		show_msg -r "[-] No internet connectivity.\n[!] Connect to internet and run the script again.\n"
		exit 1;
	fi
}

## Perform system upgrade
upgrade_system() {
	check_internet
	show_msg -b "\n[*] Performing system upgrade..."

	# update xbps package
	show_msg -o "\n[*] Updating 'xbps' package..."
	sudo xbps-install --sync --update --yes xbps
	check_cmd_status 'install' 'xbps' 'package'
	
	# upgrade entire system
	show_msg -o "\n[*] Updating system..."
	sudo xbps-install --sync --update --yes
	check_cmd_status 'perform' 'system' 'upgrade'
}

## Install packages
install_pkgs() {
	upgrade_system
	show_msg -b "\n[*] Installing required packages..."
	for _pkg in "${_packages[@]}"; do
		show_msg -o "\n[+] Installing package : $_pkg"
		sudo xbps-install --yes "$_pkg"
		if [[ "$?" != '0' ]]; then
			show_msg -r "\n[!] Failed to install package: $_pkg"
			_failed_to_install+=("$_pkg")
		fi
	done

	# List failed packages
	if [[ -n "${_failed_to_install}" ]]; then
		echo
		for _failed in "${_failed_to_install[@]}"; do
			show_msg -r "[!] Failed to install package : ${ORANGE}${_failed}"
		done
		{ show_msg -r "\n[!] Install these packages manually to continue, exiting...\n"; exit 1; }
	fi
}

## Files ----------------------------------------------

## Install shared files
install_shared_files() {
	_bindir='/usr/local/bin'
	_sharedir='/usr/share'

	show_msg -b "\n[*] Installing shared files..."

	_shared_files=(backgrounds fonts icons themes)
	for _sfile in "${_shared_files[@]}"; do
		show_msg -o "[+] Installing '${_sfile}'"
		${_copy_cmd} "$_rootfs"/shared/"$_sfile" "$_sharedir"
		check_cmd_status 'install' "$_sfile" "in $_sharedir directory"
	done

	show_msg -b "\n[*] Installing openbox menu libraries and pipemenus..."
	${_copy_cmd} "$_rootfs"/shared/archcraft "$_sharedir"
	check_cmd_status 'install' 'archcraft' "in $_sharedir directory"

	show_msg -b "\n[*] Installing desktop files for applications..."
	${_copy_cmd} "$_rootfs"/shared/applications "$_sharedir"
	check_cmd_status 'install' 'desktop files' "in $_sharedir directory"

	show_msg -b "\n[*] Installing scripts..."
	${_copy_cmd} --verbose "$_rootfs"/scripts/* "$_bindir"
	check_cmd_status 'install' 'scripts' "in $_bindir directory"

	show_msg -b "\n[*] Installing theme files..."
	_shared_themes=(grub plymouth sddm)
	for _stheme in "${_shared_themes[@]}"; do
		if [[ ! -d "$_sharedir/$_stheme/themes" ]]; then
			sudo mkdir -p "$_sharedir/$_stheme/themes"
		fi
		show_msg -o "[+] Installing theme for '${_stheme}'"
		${_copy_cmd} "$_rootfs"/${_stheme}/void "$_sharedir"/${_stheme}/themes/
		check_cmd_status 'install' "$_stheme" "theme in $_sharedir/$_stheme directory"
	done
}

## Install system wide config files
install_sys_config_files() {
	show_msg -b "\n[*] Installing system-wide config files..."
	
	_sys_cfgs=(polkit-1 sudoers.d udev X11 environment)
	for _scfg in "${_sys_cfgs[@]}"; do
		show_msg -o "\n[+] Installing ${_scfg} files..."
		${_copy_cmd} --verbose "$_rootfs"/etc/${_scfg} /etc
		check_cmd_status 'install' "$_scfg" "files in /etc directory"
	done

	show_msg -o "\n[+] Installing sddm config files..."
	${_copy_cmd} --verbose "$_rootfs"/sddm/config/* /etc
	check_cmd_status 'install' 'sddm' "config files in /etc directory"
}

## Install skeleton
install_skeleton_files() {
	_skel='/etc/skel'

	show_msg -b "\n[*] Installing skeleton files..."

	_skel_files=(`ls --almost-all --group-directories-first ${_rootfs}/skel/`)
	for _skfile in "${_skel_files[@]}"; do
		show_msg -o "[+] Installing ${_skfile} files..."
		${_copy_cmd} "$_rootfs"/skel/${_skfile} "$_skel"
		check_cmd_status 'install' "$_skfile" "files in $_skel directory"	
	done
}

## Copy files in user's directory
copy_files_in_home() {
	_cp_cmd='cp --preserve=mode --force --recursive'
	_skel_dir='/etc/skel'
	_bnum=`echo $RANDOM`

	show_msg -b "\n[*] Copying config files in $HOME directory..."
	_cfiles=(
		  '.cache'
		  '.config'
		  '.icons'
		  '.mpd'
		  '.ncmpcpp'
		  '.oh-my-zsh'
		  '.vim_runtime'
		  '.dmrc'
		  '.face'
		  '.fehbg'
		  '.gtkrc-2.0'
		  '.hushlogin'
		  '.vimrc'
		  '.zshrc'
		  'Music'
		  'Pictures'
		  )
	
	for _file in "${_cfiles[@]}"; do
		if [[ -e "$HOME/$_file" ]]; then
			show_msg -m "\n[-] Backing-up : $HOME/$_file"
			mv "$HOME/$_file" "$HOME/${_file}_backup_${_bnum}"
			show_msg -c "[!] Backup stored in : $HOME/${_file}_backup_${_bnum}"
		fi
		show_msg -o "[+] Copying $_skel_dir/$_file in $HOME directory"
		${_cp_cmd} "$_skel_dir/$_file" "$HOME"
	done
}

## Copy files in root directory
copy_files_in_root() {
	_skel_dir='/etc/skel'
	_bnum=`echo $RANDOM`

	show_msg -b "\n[*] Copying config files in /root directory..."
	_cfiles=(
		  '.config'
		  '.gtkrc-2.0'
		  '.oh-my-zsh'
		  '.vimrc'
		  '.vim_runtime'
		  '.zshrc'
		  )
	
	for _file in "${_cfiles[@]}"; do
		if sudo test -e "/root/$_file"; then
			show_msg -m "\n[-] Backing-up : /root/$_file"
			sudo mv "/root/$_file" "/root/${_file}_backup_${_bnum}"
			show_msg -c "[!] Backup stored in : /root/${_file}_backup_${_bnum}"
		fi
		show_msg -o "[+] Copying $_skel_dir/$_file in /root directory"
		${_copy_cmd} "$_skel_dir/$_file" /root
	done
}

## Misc -----------------------------------------------

## Modify grub bootloader settings
update_grub_settings() {
	_grub_file='/etc/default/grub'
	_grub_dir='/etc/grub.d'
	_grub_new_cmdline='quiet splash loglevel=3 udev.log_level=3 vt.global_cursor_default=0 video=efifb:nobgrt'
	_grub_theme='/usr/share/grub/themes/void/theme.txt'
	
	show_msg -b "\n[*] Updating grub configurations..."

	show_msg -m "[-] Backing-up grub config file..."
	${_copy_cmd} "$_grub_file"{,.default} 

	show_msg -o "[+] Modifying grub cmdline..."
	_grub_current_cmdline="`cat $_grub_file | grep 'GRUB_CMDLINE_LINUX_DEFAULT=' | cut -d'"' -f2 | sed s/loglevel=4//g`"
	sudo sed -i -e "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$_grub_new_cmdline $_grub_current_cmdline\"/g" ${_grub_file}
	check_cmd_status 'modify' 'grub cmdline' "in file $_grub_file"

	show_msg -o "[+] Enabling graphical terminal..."
	if cat "$_grub_file" | grep "^GRUB_TERMINAL_OUTPUT=console$" &>/dev/null; then
		sudo sed -i -e "s/GRUB_TERMINAL_OUTPUT=console/#GRUB_TERMINAL_OUTPUT=console/g" ${_grub_file}
		check_cmd_status 'enable' 'graphical terminal' "in file $_grub_file"
	fi
	if cat "$_grub_file" | grep "^GRUB_TERMINAL_INPUT=console$" &>/dev/null; then
		sudo sed -i -e "s/GRUB_TERMINAL_INPUT=console/#GRUB_TERMINAL_INPUT=console/g" ${_grub_file}
		check_cmd_status 'enable' 'graphical terminal' "in file $_grub_file"
	fi

	show_msg -o "[+] Setting resolution for graphical terminal..."
	if cat "$_grub_file" | grep "^#GRUB_GFXMODE=.*$" &>/dev/null; then
		sudo sed -i -e "s/#GRUB_GFXMODE=.*/GRUB_GFXMODE=auto/g" ${_grub_file}
		check_cmd_status 'set' 'resolution' "for graphical terminal in file $_grub_file"
	fi

	show_msg -o "[+] Enabling os-prober execution..."
	echo "# Uncomment this option to enable os-prober execution in the grub-mkconfig command" | sudo tee -a "$_grub_file" &>/dev/null
	echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a "$_grub_file" &>/dev/null
	check_cmd_status 'enable' 'os-prober' "execution in file $_grub_file"

	show_msg -o "[+] Enabling gfx-theme for grub..."
	echo "# Set your desired gfxtheme" | sudo tee -a "$_grub_file" &>/dev/null
	echo -e "GRUB_THEME=\"$_grub_theme\"" | sudo tee -a "$_grub_file" &>/dev/null
	check_cmd_status 'set' 'gfxtheme' "for grub in file $_grub_file"

	show_msg -o "[+] Adding recovery class for this OS's menuenties..."
	sudo sed -i -e "s#\"Advanced options for %s\" \"\${OS}\" | grub_quote)'#\"Advanced options for %s\" \"\${OS}\" | grub_quote)' --class recovery#g" "$_grub_dir"/10_linux
	check_cmd_status 'add' 'recovery' "class in $_grub_dir/10_linux file"

	show_msg -o "[+] Adding recovery class for os-prober menuenties..."
	sudo sed -i -e "s#\"Advanced options for %s\" \"\${OS} \$onstr\" | grub_quote)'#\"Advanced options for %s\" \"\${OS} \$onstr\" | grub_quote)' --class recovery#g" "$_grub_dir"/30_os-prober
	check_cmd_status 'add' 'recovery' "class in $_grub_dir/30_os-prober file"

	show_msg -o "[+] Adding efi class for uefi menuentry..."
	sudo sed -i -e "s/menuentry '\$LABEL'/menuentry '\$LABEL' --class efi/g" "$_grub_dir"/30_uefi-firmware
	check_cmd_status 'add' 'efi' "class in $_grub_dir/30_uefi-firmware file"

	show_msg -o "[+] Adding shutdown and reboot menu entries..."
	echo -e "\nmenuentry 'Reboot Computer' --class restart {\n    reboot\n}\n\nmenuentry 'Shutdown Computer' --class shutdown {\n    halt\n}" | sudo tee -a "$_grub_dir"/40_custom &>/dev/null
	check_cmd_status 'add' 'powermenu' "entries in $_grub_dir/40_custom file"
}

## Modify plymouth boot-splash settings
update_plymouth_settings() {
	_plymouth_cfg='/etc/plymouth/plymouthd.conf'

	show_msg -b "\n[*] Updating plymouth configuration..."

	show_msg -m "[-] Backing-up plymouth config file..."
	${_copy_cmd} "$_plymouth_cfg"{,.default}

	show_msg -o "[+] Setting new theme for plymouth..."
	sudo sed -i -e "s/#\[Daemon\]/\[Daemon\]/g" "$_plymouth_cfg"
	sudo sed -i -e "s/#Theme=.*/Theme=void/g" "$_plymouth_cfg"
	check_cmd_status 'set' 'new theme' "for plymouth"
}

## Modify sddm display manager settings
update_sddm_settings() {
	_sddm_cfg='/etc/sddm.conf.d/kde_settings.conf'
	_sddm_state='/var/lib/sddm/state.conf'
	_sddm_xsession='/usr/share/sddm/scripts/Xsession'

	show_msg -b "\n[*] Updating sddm configuration..."

	show_msg -o "[+] Setting new theme for sddm..."
	sudo sed -i -e "s/Current=.*/Current=void/g" "$_sddm_cfg"
	check_cmd_status 'set' 'new theme' "for sddm"

	show_msg -o "[+] Updating sddm's Xsession file..."
	sudo sed -i -e "s/exec \$@/exec dbus-run-session \$@/g" "$_sddm_xsession"
	check_cmd_status 'update' 'Xsession' "file for sddm"
	
	show_msg -o "[+] Installing state.conf file for sddm..."
	${_copy_cmd} "$_rootfs"/sddm/state.conf "$_sddm_state"
	check_cmd_status 'install' "$_sddm_state" 'file'

	if [[ -e "$_sddm_state" ]]; then
		show_msg -o "[+] Updating sddm's state.conf file..."
		sudo sed -i -e "s/User=.*/User=$USER/g" "$_sddm_state"
		sudo sed -i -e "s|Session=.*|Session=/usr/share/xsessions/openbox.desktop|g" "$_sddm_state"
		check_cmd_status 'update' "$_sddm_state" 'file'
	fi
}

## Enable runit services
enable_services() {
	_runit_services=(NetworkManager
					 bluetoothd
					 cups-browsed
					 cupsd
					 dbus
					 polkitd
					 sddm)

	_serv_disable=(dhcpcd wpa_supplicant)

	show_msg -b "\n[*] Enabling runit services..."
	
	for _serv in "${_runit_services[@]}"; do
		if ! sudo sv status "$_serv" &>/dev/null; then
			show_msg -o "\n[+] Enabling '$_serv' service..."
			sudo ln -v -s /etc/sv/"$_serv" /var/service/
		fi
	done

	if [[ -L '/var/service/NetworkManager' ]]; then
		show_msg -c "\n[!] NetworkManager service is enabled, So..."
		for _servd in "${_serv_disable[@]}"; do
			if sudo sv status "$_servd" &>/dev/null; then
				show_msg -m "[-] Disabling '$_servd' service..."
				sudo rm -v /var/service/"$_servd"
			fi
		done
	fi
} 

## Perform misc operations
perform_misc_operations() {
	show_msg -b "\n[*] Performing various operations..."

	show_msg -o "[+] Fixing shutdown/reboot without sudo issue..."
	_wheel_file='/etc/sudoers.d/wheel'
	if [[ -e "$_wheel_file" ]]; then
		sudo rm -f "$_wheel_file"
	fi
	
	show_msg -o "[+] Updating font cache..."
	sudo fc-cache && fc-cache

	show_msg -o "[+] Making scripts executable..."
	sudo chmod 755 /usr/local/bin/*

	show_msg -o "[+] Updating user ${USER}'s home directories..."
	xdg-user-dirs-update && xdg-user-dirs-gtk-update

	show_msg -o "[+] Changing user ${USER}'s shell..."
	sudo chsh -s /bin/zsh "$USER" &>/dev/null
	
	show_msg -o "[+] Regenerating initrd and updating grub config..."
	_kern_ver=`uname -r | cut -d'_' -f1 | cut -d'.' -f1,2`
	sudo xbps-reconfigure -f linux${_kern_ver}
}

## Finalization
finalization() {
	show_msg -b "\n[*] Performing cleanup..."

	# Remove all unused packages
	show_msg -o "[-] Removing unused packages..."
	sudo xbps-remove --clean-cache --remove-orphans --yes

	# Removing useless xsession files
	show_msg -o "[-] Removing uselss xsession files..."
	sudo rm -rf /usr/share/xsessions/{i3-with-shmlog.desktop,openbox-gnome.desktop,openbox-kde.desktop}

	# Completed
	show_msg -g "\n[*] Installation Completed, You may now reboot your computer.\n"
}

## Main --------------------------------------
banner
install_pkgs
install_shared_files
install_sys_config_files
install_skeleton_files
copy_files_in_home
copy_files_in_root
update_grub_settings
update_plymouth_settings
update_sddm_settings
enable_services
perform_misc_operations
finalization
