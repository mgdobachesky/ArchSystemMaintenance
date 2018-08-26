#!/bin/bash

arch_news() {
	# Grab the latest Arch Linux news
	python {{PKG_PATH}}/archNews.py | less
}

fetch_warnings() {
	# Fetch and warn the user if any known problems have been published since the last upgrade
	last_upgrade="$(sed -n '/pacman -Syu/h; ${x;s/.\([0-9-]*\).*/\1/p;}' /var/log/pacman.log)"

	python {{PKG_PATH}}/archNews.py "$last_upgrade"
	alerts="$?"
	
	if [[ "$alerts" == 1 ]]; then
		printf "WARNING: This upgrade requires out-of-the-ordinary user intervention.\n"
		printf "Continue only after fully resolving the above issue(s).\n\n"

		read -r -p "Are you ready to continue? [y/N]"
		if [[ "$REPLY" != "y" ]]; then
			exit
		fi
	fi
}

update_mirrorlist() {
	# Get an up-to-date mirrorlist that is sorted by speed and syncronization
	read -r -p "Do you want to get an updated mirrorlist? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		printf "Updating mirrorlist...\n"
		sudo reflector --country "$MIRRORLIST_COUNTRY" --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
		printf "...Mirrorlist updated\n\n"
	fi
}

upgrade_system() {
	# Upgrade the system
	sudo pacman -Syu
}

rebuild_aur() {
	# Rebuild AUR packages
	if [[ -n "${AURDEST/[ ]*\n/}" ]]; then
		starting_dir="$(pwd)"
		for aur_dir in "$AURDEST"/*/; do 
			if [[ -d "$aur_dir" ]]; then
				cd "$aur_dir"
				makepkg -sirc
			fi
		done
		cd "$starting_dir"
	fi
}

remove_orphaned() {
	# Remove unused orphan packages
	printf "\nChecking for orphaned packages...\n"
	mapfile -t orphaned < <(pacman -Qtdq)
	if [[ ${orphaned[*]} ]]; then
		printf "...ORPHANED PACKAGES FOUND:\n"
		printf '%s\n' "${orphaned[@]}"
		read -r -p "Do you want to remove the above orphaned packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns --noconfirm ${orphaned[*]}
		fi
		printf "\n"
	else 
		printf "...No orphaned packages found\n\n"
	fi
}

remove_dropped() {
	# Remove dropped packages
	printf "Checking for dropped packages...\n"
	if [[ -n "${AURDEST/[ ]*\n/}" ]]; then
		aur_list="maint"
		for aur_dir in "$AURDEST"/*/; do 
			if [[ -d "$aur_dir" ]]; then
				aur_list="$aur_list|$(basename "$aur_dir")"
			fi
		done
		mapfile -t dropped < <(awk "!/${aur_list}/" <(pacman -Qmq))
	else
		mapfile -t dropped < <(pacman -Qmq)
	fi

	if [[ ${dropped[*]} ]]; then
		printf "...DROPPED PACKAGES FOUND:\n"
		printf '%s\n' "${dropped[@]}"
		read -r -p "Do you want to remove the above dropped packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns --noconfirm ${dropped[*]}
		fi
		printf "\n"
	else
		printf "...No dropped packages found\n\n"
	fi
}

handle_pacfiles() {
	# Find and act on any .pacnew or .pacsave files
	sudo pacdiff
}

upgrade_warnings() {
	# Get any warnings that might have occured while upgrading the system
	last_upgrade="$(sed -n '/pacman -Syu/h; ${x;s/.\([0-9-]*\).*/\1/p;}' /var/log/pacman.log)"
	paclog --after="$last_upgrade" | paclog --warnings
}

clean_cache() {
	# Clean up the package cache
	read -r -p "Do you want to clean up the package cache? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		sudo paccache -r
	fi
}

clean_symlinks() {
	# Check for broken symlinks in specified directories
	printf "\nChecking for broken symlinks...\n"
	mapfile -t broken_symlinks < <(sudo find ${SYMLINKS_CHECK[*]} -xtype l -print)
	if [[ ${broken_symlinks[*]} ]]; then
		printf "...BROKEN SYMLINKS FOUND:\n"
		printf '%s\n' "${broken_symlinks[@]}"
		read -r -p "Do you want to remove the broken symlinks above? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo rm ${broken_symlinks[*]}
		fi
		printf "\n"
	else
		printf "...No broken symlinks found\n\n"
	fi
}

clean_old_config() {
	# Remind the user to clean up old configuration files
	printf "NOTICE: Check the following directories for old configuration files:\n"
	printf "~/\n"
	printf "~/.config/\n"
	printf "~/.cache/\n"
	printf "~/.local/share/\n\n"
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

fetch_news() {
	# Get latest news
	arch_news
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
}

system_clean() {
	# Clean the filesystem
	clean_cache
	clean_symlinks
	clean_old_config
}

system_errors() {
	# Check the system for errors
	failed_services
	journal_errors
}

backup_system() {
	# Backup the system
	printf "\nBacking up the system...\n"
	BACKUP_EXCLUDE=("${BACKUP_EXCLUDE[@]/#/--exclude }")
	sudo duplicity ${BACKUP_EXCLUDE[*]} / "file://$BACKUP_SAVE"
	printf "...Backup saved to $BACKUP_SAVE\n\n"
}

update_settings() {
	sudo vim {{PKG_PATH}}/settings.sh
	source {{PKG_PATH}}/settings.sh
}

# Import settings
source {{PKG_PATH}}/settings.sh

# Take appropriate action
PS3='Action to take: '
select opt in "Arch Linux News" "Upgrade System" "Clean Filesystem" "System Error Check" "Backup System" "Update Settings" "Exit"; do
	case $REPLY in
		1) fetch_news;;
		2) system_upgrade;;
		3) system_clean;;
		4) system_errors;;
		5) backup_system;;
		6) update_settings;;
		7) break;;
		*) echo "Please choose an existing option";;
	esac
done
