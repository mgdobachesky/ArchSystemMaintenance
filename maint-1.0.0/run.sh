#!/bin/bash

arch_news() {
	# Grab the latest Arch Linux news
	python ./archNews.py | less
}

fetch_warnings() {
	# Fetch and warn the user if any known problems have been published since the last upgrade
	last_upgrade="$(sed -n '/pacman -Syu/h; ${x;s/.\([0-9-]*\).*/\1/p;}' /var/log/pacman.log)"

	python ./archNews.py "$last_upgrade"
	alerts="$?"
	
	if [[ "$alerts" == 1 ]]; then
		printf "WARNING: This upgrade requires out-of-the-ordinary user intervention."
		printf "\nContinue only after fully resolving the above issue(s).\n\n"

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
		sudo reflector --country "$MIRRORLIST_COUNTRY" --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
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
	mapfile -t orphaned < <(pacman -Qtdq)
	if [[ ${orphaned[*]} ]]; then
		printf "\nORPHANED PACKAGES:\n${orphaned[*]}\n"
		read -r -p "Do you want to remove the above orphaned packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns --noconfirm "${orphaned[*]}"
		fi
	fi
}

remove_dropped() {
	# Remove dropped packages
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
		printf "\nDROPPED PACKAGES:\n${dropped[*]}\n"
		read -r -p "Do you want to remove the above dropped packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns --noconfirm "${dropped[*]}"
		fi
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

clean_symlinks_dir() {
	# Remove broken symlinks in a specific directory
	mapfile -t broken_symlinks < <(sudo find $1 -xtype l -print0)
	if [[ ${broken_symlinks[*]} ]]; then
		printf "\nBROKEN SYMLINKS:\n${broken_symlinks[*]}\n"
		read -r -p "Do you want to remove the broken $1 symlinks above? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			rm "${broken_symlinks[*]}"
		fi
	fi
}

clean_symlinks() {
	# Check for broken symlinks in specified directories
	for sym_dir in "${SYMLINKS_CHECK[@]}"; do 
		if [[ -d "$sym_dir" ]]; then
			clean_symlinks_dir "$sym_dir"
		fi
	done
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
}

system_errors() {
	# Check the system for errors
	failed_services
	journal_errors
}

update_settings() {
	sudo vim settings.sh
}

# Import settings
source ./settings.sh

# Take appropriate action
PS3='Action to take: '
select opt in "Arch Linux News" "Upgrade the System" "Clean the Filesystem" "Check for Errors" "Update Settings" "Exit"; do
    case $REPLY in
        1) fetch_news;;
        2) system_upgrade;;
        3) system_clean;;
		4) system_errors;;
		5) update_settings;;
        6) break;;
        *) echo "Please choose an existing option";;
    esac
done
