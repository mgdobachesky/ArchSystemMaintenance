#!/bin/bash

#######################################################################
########################## Menu Option Logic ##########################
#######################################################################

arch_news() {
	# Grab the latest Arch Linux news
	python $(pkg_path)/archNews.py | less
}

fetch_warnings() {
	# Fetch and warn the user if any known problems have been published since the last upgrade
	printf "\nChecking Arch Linux news...\n"
	last_upgrade="$(sed -n '/pacman -Syu/h; ${x;s/.\([0-9-]*\).*/\1/p;}' /var/log/pacman.log)"

	if [[ -n "$last_upgrade" ]]; then
		python $(pkg_path)/archNews.py "$last_upgrade"
	else
		python $(pkg_path)/archNews.py
	fi
	alerts="$?"
	
	if [[ "$alerts" == 1 ]]; then
		printf "WARNING: This upgrade requires out-of-the-ordinary user intervention.\n"
		printf "Continue only after fully resolving the above issue(s).\n"

		printf "\n"
		read -r -p "Are you ready to continue? [y/N]"
		if [[ "$REPLY" != "y" ]]; then
			exit
		fi
	else
		printf "...No new Arch Linux news posts\n"
	fi
}

update_mirrorlist() {
	# Get an up-to-date mirrorlist that is sorted by speed and syncronization
	printf "\n"
	read -r -p "Do you want to get an updated mirrorlist? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		printf "Updating mirrorlist...\n"
		sudo reflector --country "$MIRRORLIST_COUNTRY" --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
		printf "...Mirrorlist updated\n"
	fi
}

upgrade_system() {
	# Upgrade the system
	printf "\nUpgrading the system...\n"
	sudo pacman -Syu
	printf "...Done upgrading the system\n"
}

rebuild_aur() {
	# Rebuild AUR packages
	printf "\n"
	read -r -p "Do you want to rebuild AUR packages? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		printf "Rebuilding AUR packages...\n"
		if [[ -d "$AUR_DIR" ]]; then
			starting_dir="$(pwd)"
			for aur_pkg in "$AUR_DIR"/*/; do 
				if [[ -d "$aur_pkg" ]]; then
					cd "$aur_pkg"
					makepkg -sirc --noconfirm
				fi
			done
			cd "$starting_dir"
			printf "...Done rebuilding AUR packages\n"
		else
			printf "...AUR package directory not set up at $AUR_DIR\n"
		fi
	fi
}

remove_orphaned() {
	# Remove unused orphan packages
	printf "\nChecking for orphaned packages...\n"
	mapfile -t orphaned < <(pacman -Qtdq)
	if [[ ${orphaned[*]} ]]; then
		printf "ORPHANED PACKAGES FOUND:\n"
		printf '%s\n' "${orphaned[@]}"
		read -r -p "Do you want to remove the above orphaned packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns --noconfirm ${orphaned[*]}
		fi
	else 
		printf "...No orphaned packages found\n"
	fi
}

remove_dropped() {
	# Remove dropped packages
	printf "\nChecking for dropped packages...\n"
	if [[ -n "${AUR_DIR/[ ]*\n/}" ]]; then
		aur_list="maint"
		for aur_pkg in "$AUR_DIR"/*/; do 
			if [[ -d "$aur_pkg" ]]; then
				aur_list="$aur_list|$(basename "$aur_pkg")"
			fi
		done
		mapfile -t dropped < <(awk "!/${aur_list}/" <(pacman -Qmq))
	else
		mapfile -t dropped < <(pacman -Qmq)
	fi

	if [[ ${dropped[*]} ]]; then
		printf "DROPPED PACKAGES FOUND:\n"
		printf '%s\n' "${dropped[@]}"
		read -r -p "Do you want to remove the above dropped packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns --noconfirm ${dropped[*]}
		fi
	else
		printf "...No dropped packages found\n"
	fi
}

handle_pacfiles() {
	# Find and act on any .pacnew or .pacsave files
	printf "\nChecking for pacfiles...\n"
	sudo pacdiff
	printf "...Done checking for pacfiles\n"
}

upgrade_warnings() {
	# Get any warnings that might have occured while upgrading the system
	printf "\nChecking for upgrade warnings...\n"
	last_upgrade="$(sed -n '/pacman -Syu/h; ${x;s/.\([0-9-]*\).*/\1/p;}' /var/log/pacman.log)"

	if [[ -n "$last_upgrade" ]]; then
		paclog --after="$last_upgrade" | paclog --warnings
	fi
	printf "...Done checking for upgrade warnings\n"
}

clean_cache() {
	# Clean up the package cache
	printf "\n"
	read -r -p "Do you want to clean up the package cache? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		printf "Cleaning up the package cache...\n"
		sudo paccache -r
		printf "...Done cleaning up the package cache\n"
	fi
}

clean_symlinks() {
	# Check for broken symlinks in specified directories
	printf "\nChecking for broken symlinks...\n"
	mapfile -t broken_symlinks < <(sudo find ${SYMLINKS_CHECK[*]} -xtype l -print)
	if [[ ${broken_symlinks[*]} ]]; then
		printf "BROKEN SYMLINKS FOUND:\n"
		printf '%s\n' "${broken_symlinks[@]}"
		read -r -p "Do you want to remove the broken symlinks above? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo rm ${broken_symlinks[*]}
		fi
	else
		printf "...No broken symlinks found\n"
	fi
}

clean_old_config() {
	# Remind the user to clean up old configuration files
	printf "\nNOTICE: Check the following directories for old configuration files:\n"
	printf "~/\n"
	printf "~/.config/\n"
	printf "~/.cache/\n"
	printf "~/.local/share/\n"
}

failed_services() {
	# Check if any systemd services have failed
	printf "\nFAILED SYSTEMD SERVICES:\n"
	systemctl --failed
}

journal_errors() {
	# Look for high priority errors in the systemd journal
	printf "\nHIGH PRIORITY SYSTEMD JOURNAL ERRORS:\n"
	journalctl -p 3 -xb
}

execute_backup() {
	# Execute backup operations
	read -r -p "Do you want to backup the system to an image located at $BACKUP_LOCATION? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		printf "\nBacking up the system...\n"
		sudo rsync -aAXHS --info=progress2 --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/swapfile","/lost+found","$BACKUP_LOCATION"} / "$BACKUP_LOCATION"
		printf "...Done backing up to $BACKUP_LOCATION\n"
	fi
}

execute_restore() {
	# Execute restore operations
	read -r -p "Do you want to restore the system from the image located at $BACKUP_LOCATION? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		if [ -n "$(find $BACKUP_LOCATION -maxdepth 0 -type d -not -empty 2>/dev/null)" ]; then
			printf "\nRestoring the system...\n"
			sudo rsync -aAXHS --info=progress2 --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/swapfile","/lost+found","$BACKUP_LOCATION"} "$BACKUP_LOCATION" /
			printf "...Done restoring from $BACKUP_LOCATION\n"
		else
			printf "\nYou must create a system backup before restoring the system from it\n"; 
		fi
	fi
}

modify_settings() {
	# Modify user settings
	sudo vim $(pkg_path)/settings.sh
}

source_settings() {
	# Bring in user settings
	source $(pkg_path)/settings.sh
}

pkg_path() {
	# The package path is set during installation with the PKGBUILD
	local pkg_path={{PKG_PATH}}
	echo $pkg_path
}

#######################################################################
####################### Menu Option Definitions #######################
#######################################################################

fetch_news() {
	# Get latest news
	arch_news
	printf "\n"
}

system_upgrade() {
	# Upgrade the System
	fetch_warnings
	update_mirrorlist
	upgrade_system
	rebuild_aur
	remove_orphaned
	remove_dropped
	handle_pacfiles
	upgrade_warnings
	printf "\n"
}

system_clean() {
	# Clean the filesystem
	clean_cache
	clean_symlinks
	clean_old_config
	printf "\n"
}

system_errors() {
	# Check the system for errors
	failed_services
	journal_errors
	printf "\n"
}

backup_system() {
	# Backup the system
	execute_backup
	printf "\n"
}

restore_system() {
	# Restore the system
	execute_restore
	printf "\n"
}

update_settings() {
	# Update user settings
	modify_settings
	source_settings
	printf "\n"
}

#######################################################################
############################## Main Menu ##############################
#######################################################################

# Import settings
source_settings

# Take appropriate action
PS3='Action to take: '
select opt in "Arch Linux News" "Upgrade System" "Clean Filesystem" "System Error Check" "Backup System" "Restore System" "Update Settings" "Exit"; do
	case $REPLY in
		1) fetch_news;;
		2) system_upgrade;;
		3) system_clean;;
		4) system_errors;;
		5) backup_system;;
		6) restore_system;;
		7) update_settings;;
		8) break;;
		*) echo "Please choose an existing option";;
	esac
done
