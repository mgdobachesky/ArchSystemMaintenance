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

aur_list() {
	LIST=""
	while IFS= read -r -d $'\0'; do
		for D in "$REPLY"/*/; do 
			if [[ -d "$D" ]]; then
				LIST="${LIST},${D}"
			fi
		done
	done < <(sudo find /home -name ".aur" -print0)

	echo "${LIST:1}"
}

rebuild_aur() {
	# Rebuild AUR packages
	local AUR_LIST="$(aur_list)"
	IFS=$',' read -a AUR_LIST <<< "${AUR_LIST}"

	ORIGIN_DIR="$(pwd)"
	for aur_dir in "${AUR_LIST[@]}"; do
		cd "$aur_dir"
		makepkg -sirc
	done
	cd "$ORIGIN_DIR"
}

remove_pacfiles() {
	# Automatically remove specified pacfiles
	if [[ -f /etc/pacman.d/mirrorlist.pacnew ]]; then
		sudo rm /etc/pacman.d/mirrorlist.pacnew
	fi
}

remove_orphans() {
	# Remove unused orphan packages
	ORPHANED="$(pacman -Qtd)"
	if [[ -n "${ORPHANED/[ ]*\n/}" ]]; then
		printf "\nORPHANED PACKAGES:\n$ORPHANED\n"
		read -r -p "Do you want to remove the above orphaned packages? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			sudo pacman -Rns "$(pacman -Qtdq)"
		fi
	fi
}

remove_dropped() {
	# Remove dropped packages
	DROPPED_LIST="$(pacman -Qmq)"
	if [[ -n "${DROPPED_LIST/[ ]*\n/}" ]]; then
		local AUR_LIST="$(aur_list)"

		DROPPED_ARRAY=()
		while IFS=$'\n' read -a DROPPED_ITEM; do
			DROPPED_ARRAY+=("$DROPPED_ITEM")
		done <<< "${DROPPED_LIST}"

		AUR_FILTERED=""
		for DROPPED_ITEM in "${DROPPED_ARRAY[@]}"; do
			IS_AUR="$(echo "$AUR_LIST" | grep "$DROPPED_ITEM")"
			if [[ ! -n "${IS_AUR/[ ]*\n/}" ]]; then
				AUR_FILTERED="${AUR_FILTERED} ${DROPPED_ITEM}"
			fi
		done
		AUR_FILTERED="${AUR_FILTERED:1}"

		if [[ -n "${AUR_FILTERED/[ ]*\n/}" ]]; then
			printf "\nDROPPED PACKAGES:\n$AUR_FILTERED\n"
			read -r -p "Do you want to remove the above dropped packages? [y/N]"
			if [[ "$REPLY" == "y" ]]; then
				sudo pacman -Rns "$AUR_FILTERED"
			fi
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
	BROKEN_SYMLINKS="$(sudo find /home -xtype l -print)"
	if [[ -n "${BROKEN_SYMLINKS/[ ]*\n/}" ]]; then
		printf "\nBROKEN SYMLINKS:\n$BROKEN_SYMLINKS\n"
		read -r -p "Do you want to remove the above broken symlinks? [y/N]"
		if [[ "$REPLY" == "y" ]]; then
			while IFS= read -r -d $'\0'; do 
				rm "$REPLY"
			done < <(sudo find /home -xtype l -print0)
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
		rmlint /home
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
	remove_orphans
	remove_dropped
	remove_pacfiles
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
