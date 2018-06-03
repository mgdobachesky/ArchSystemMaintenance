#!/bin/bash

update_mirrorlist() {
	# Get an up-to-date mirrorlist that is sorted by speed and syncronization
	sudo reflector --country 'United States' --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
}

upgrade_system() {
	# Upgrade the system
	sudo pacman -Syu --noconfirm
}

rebuild_aur() {
	# Rebuild AUR packages
	ORIGIN_DIR="$(pwd)"
	while IFS= read -r -d $'\0'; do
		cd $REPLY
		for D in $REPLY/*/; do 
			if [ -d "$D" ]; 
			then
				cd "${D}"
				git pull origin master
				makepkg -sirc --noconfirm
			fi

		done
	done < <(sudo find /home -name ".aur" -print0)
	cd $ORIGIN_DIR
}

check_orphans() {
	# Check if any orphaned packages exist
	ORPHANED="$(pacman -Qtd)"
	echo $ORPHANED
}

remove_orphans() {
	# Remove unused orphan packages
	local ORPHANED=$(check_orphans)
	if [ -n "${ORPHANED/[ ]*\n/}" ];
	then
		sudo pacman -Rns $(pacman -Qtdq)
	fi
}

upgrade_alerts() {
	# Pay attention to alerts while upgrading the system
	echo "NOTICE: Check /var/log/pacman.log for alerts that might of come up while upgrading the system."

	# TODO: Use '/var/log/pacman.log' to automatically pick up any alerts for the user
}

find_pacfiles() {
	# Find and act on any .pacnew or .pacsave files
	sudo updatedb
	PACFILES="$(locate --existing --regex "\.pac(new|save)$")"
	if [ -n "${PACFILES/[ ]*\n/}" ];
	then
		echo "PACFILES: $PACFILES"
	fi
}

check_dropped() {
	# Check for dropped packages (NOTE: AUR packages are included in output)
	DROPPED="$(pacman -Qm)"
	if [ -n "${DROPPED/[ ]*\n/}" ];
	then
		echo "DROPPED: $DROPPED"
	fi

	# TODO: Don't display AUR packages in the dropped list
}

notify_actions() {
	# Notify of anything worth mentioning
	upgrade_alerts
	find_pacfiles
	check_dropped
}

clean_cache() {
	# Remove all packages from cache that are not currently installed
	sudo pacman -Sc --noconfirm
}

clean_symlinks() {
	# Remove broken symlinks
	while IFS= read -r -d $'\0'; do 
		sudo rm $REPLY
	done < <(sudo find / -path /proc -prune -o -path /run -prune -o -xtype l -print0)	
}

clean_config() {
	# Clean up old configuration files
	echo "NOTICE: Check ~/, ~/.config/, ~/.cache/, and ~/.local/share for old configuration files."

	# TODO: Find a way to automate the cleaning of ~/, ~/.config/, ~/.cache/, and ~/.local/share
}

system_upgrade() {
	# Upgrade the System
	update_mirrorlist
	upgrade_system
	rebuild_aur
	remove_orphans
	notify_actions
}

system_clean() {
	# Clean the filesystem
	clean_cache
	clean_symlinks
	clean_config
}

menu_options() {
	# Display menu options
	clear
	echo "WARNING: Read the Arch Linux home page for updates that require out-of-the-ordinary user intervention."
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
