#!/bin/bash

update_mirrorlist() {
	# Commands for getting an up-to-date mirrorlist
	curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | sudo tee /etc/pacman.d/mirrorlist.backup
	rankmirrors -n 10 /etc/pacman.d/mirrorlist.backup | sudo tee /etc/pacman.d/mirrorlist
}

upgrade_system() {
	# Upgrade the system
	sudo pacman -Syu
}

upgrade_alerts() {
	# Pay attention to alerts while upgrading the system
	read -r -p "Were there any alerts? [y/N]" alerts
	if [[ "$alerts" == "y" ]];
	then
		ALERT_ACTION="There were alerts during the upgrade that require user intervention.";
	else
		ALERT_ACTION="";
	fi
	echo $ALERT_ACTION
}

rebuild_aur() {
	# Rebuild AUR packages
	for D in $HOME/.aur/*/; do 
		cd "${D}";
		git pull origin master;
		makepkg -sirc --noconfirm "${D}";
		cd $HOME;
	done
}

find_pacfiles() {
	# Find and act on any .pacnew or .pacsave files
	sudo updatedb
	PACFILES="$(locate --existing --regex "\.pac(new|save)$")";
	echo $PACFILES
}

check_orphans() {
	# Check for orphaned packages
	ORPHANED="$(pacman -Qtd)";
	echo $ORPHANED
}

remove_orphans() {
	# Remove unused orphan packages
	sudo pacman -Rns $(pacman -Qtdq)
}

check_dropped() {
	# Check for dropped packages (NOTE: AUR packages are included in output)
	DROPPED="$(pacman -Qm)";
	echo $DROPPED
}

clean_cache() {
	# Remove all packages from cache that are not currently installed
	sudo pacman -Sc
}

clean_config() {
	# Clean up old configuration files
	echo "Check ~/.config/, ~/.cache/, and ~/.local/share for old configuration files"
	# ~/.config/
	# ~/.cache/
	# ~/.local/share
}

clean_symlinks() {
	# Remove broken symlinks
	sudo find -xtype l -print | xargs rm
}

notify_actions() {
	# Notify of anything worth mentioning
	if [ -n "${1/[ ]*\n/}" ];
	then
		echo "Alerts: $1"
	fi
	
	if [ -n "${2/[ ]*\n/}" ];
	then
		echo "Pacfiles: $2"
	fi
	
	if [ -n "${3/[ ]*\n/}" ];
	then
		echo "Orphaned: $3"
	fi
	
	if [ -n "${4/[ ]*\n/}" ];
	then
		echo "Dropped: $4"
	fi
}

system_upgrade() {
	# Upgrade the System
	update_mirrorlist
	upgrade_system
	local ALERT_ACTION=$(upgrade_alerts)
	rebuild_aur
	local PACFILES=$(find_pacfiles)
	local ORPHANS=$(check_orphans)
	remove_orphans
	local DROPPED=$(check_dropped)
	notify_actions "$ALERT_ACTION" "$PACFILES" "$ORPHANED" "$DROPPED"
}

system_clean() {
	# Clean the filesystem
	clean_cache
	clean_config
	clean_symlinks
}

menu_options() {
	# Display menu options
	clear
	echo "WARNING: Read the Arch Linux home page for updates that require out-of-the-ordinary user intervention"
	echo "1) Upgrade the System"
	echo "2) Clean the Filesystem"
	echo "0) Exit"
}

# Take appropriate action
while menu_options && read -r -p 'Action to take: ' response && [ "$response" != "0" ];
do
	case "$response" in
		"1")
			system_upgrade
			;;
		"2")
			system_clean
			;;
		*)
			echo "Please choose an existing option"
			;;
	esac

	read -r -p 'Press any key to continue...'	
done
