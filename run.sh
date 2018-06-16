#!/bin/bash

fetch_warnings() {
	# Fetch and warn the user if any known problems have been published since the last upgrade
	LAST_UPGRADE="$(cat /var/log/pacman.log | grep -Po "(\d{4}-\d{2}-\d{2})(?=.*pacman -Syu)" | tail -1)"

	python ./Scripts/ArchNews.py "$LAST_UPGRADE"
	ALERTS="$?"
	
	if [[ "$ALERTS" == 1 ]]; then
		printf "WARNING: This upgrade requires out-of-the-ordinary user intervention."
		printf "\nContinue only after fully resolving the above issue(s).\n\n"

		read -r -p "Are you ready to continue? [y/N]"
		if [[ "$REPLY" != "y" ]]; then
			exit
		fi
	fi
}

arch_news() {
	# Grab the latest Arch Linux news
	python ./Scripts/ArchNews.py | less
}

update_mirrorlist() {
	# Get an up-to-date mirrorlist that is sorted by speed and syncronization
	read -r -p "Do you want to get an updated mirrorlist? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		sudo reflector --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
	fi
}

upgrade_system() {
	# Upgrade the system
	sudo pacman -Syu
}

rebuild_aur() {
	# Rebuild AUR packages
	if [[ -n "${AURDEST/[ ]*\n/}" ]]; then
		ORIGIN_DIR="$(pwd)"
		for D in "$AURDEST"/*/; do 
			if [[ -d "$D" ]]; then
				cd "$D"
				makepkg -sirc
			fi
		done
		cd "$ORIGIN_DIR"
	fi
}

remove_orphaned() {
	# Remove unused orphan packages
	mapfile -t orphaned < <(pacman -Qtdq)
	if [[ ${orphaned[*]} ]]; then
		printf "\nORPHANED PACKAGES:\n${orphaned[*]}\n"
		read -r -p "Do you want to remove the above orphaned packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns "${orphaned[*]}"
		fi
	fi
}

remove_dropped() {
	# Remove dropped packages
	if [[ -n "${AURDEST/[ ]*\n/}" ]]; then
		aur_list=""
		for D in "$AURDEST"/*/; do 
			if [[ -d "$D" ]]; then
				aur_list="$aur_list|$(basename "$D")"
			fi
		done
		mapfile -t dropped < <(awk "!/${aur_list:1}/" <(pacman -Qmq))
	else
		mapfile -t dropped < <(pacman -Qmq)
	fi

	if [[ ${dropped[*]} ]]; then
		printf "\nDROPPED PACKAGES:\n${dropped[*]}\n"
		read -r -p "Do you want to remove the above dropped packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns "${dropped[*]}"
		fi
	fi
}

upgrade_alerts() {
	# Get any alerts that might have occured while upgrading the system
	LAST_UPGRADE="$(cat /var/log/pacman.log | grep -Po "(\d{4}-\d{2}-\d{2})(?=.*pacman -Syu)" | tail -1)"
	WARNINGS="$(cat /var/log/pacman.log | grep -i "$LAST_UPGRADE.*WARNING")"
	if [[ -n "${WARNINGS/[ ]*\n/}" ]]; then
		printf "\nWARNINGS:\n$WARNINGS\n"
	fi
}

find_pacfiles() {
	# Find and act on any .pacnew or .pacsave files
	sudo updatedb
	PACFILES="$(locate --existing --regex "\.pac(new|save)$")"
	if [[ -n "${PACFILES/[ ]*\n/}" ]]; then
		printf "\nPACFILES:\n$PACFILES\n"
	fi
}

notify_actions() {
	# Notify of anything worth mentioning
	upgrade_alerts
	find_pacfiles
}

clean_cache() {
	# Remove all packages from cache that are not currently installed
	sudo pacman -Sc
}

clean_symlinks() {
	# Remove broken symlinks
	mapfile -t broken_symlinks < <(sudo find $HOME -xtype l -print0)
	if [[ ${broken_symlinks[*]} ]]; then
		printf "\nBROKEN SYMLINKS:\n${broken_symlinks[*]}\n"
		read -r -p "Do you want to remove the above broken symlinks? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			rm "${broken_symlinks[*]}"
		fi
	fi
}

clean_config() {
	# Clean up old configuration files
	python ./Scripts/rmjunk.py
}

remove_lint() {
	# Run rmlint for further system cleaning
	read -r -p "Do you want to run rmlint? [y/N]"
	if [[ "$REPLY" == "y" ]]; then
		rmlint $HOME
		sed -i -r "s/^handle_emptydir.*(Desktop|Documents|Downloads|Music|Pictures|Public|Templates|Videos).*//" rmlint.sh
		./rmlint.sh -x
		rm rmlint.sh
		rm rmlint.json
	fi
}

system_upgrade() {
	# Upgrade the System
	fetch_warnings
	update_mirrorlist
	upgrade_system
	rebuild_aur
	remove_orphaned
	remove_dropped
	notify_actions
}

system_clean() {
	# Clean the filesystem
	clean_cache
	clean_symlinks
	clean_config
	remove_lint
}

fetch_news() {
	# Get latest news
	arch_news
}

# Take appropriate action
PS3='Action to take: '
select opt in "Arch Linux News" "Upgrade the System" "Clean the Filesystem" "Exit"; do
    case $REPLY in
        1) fetch_news;;
        2) system_upgrade;;
        3) system_clean;;
        4) break;;
        *) echo "Please choose an existing option";;
    esac
done
