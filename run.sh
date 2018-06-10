#!/bin/bash

fetch_warnings() {
	# Fetch and warn the user if any known problems have been published since the last upgrade
	LAST_UPGRADE="$(cat /var/log/pacman.log | grep -Po "(\d{4}-\d{2}-\d{2})(?=.*pacman -Syu)" | tail -1)"

	python ./Scripts/ArchNews.py $LAST_UPGRADE
	ALERTS=$?
	
	if [ $ALERTS == 1 ]; then
		echo "WARNING: This upgrade requires out-of-the-ordinary user intervention."
		echo "Continue only after fully resolving the above issue(s)."

		read -r -p "Are you ready to continue? [y/N]"
		if [ $REPLY != "y" ]; then
			exit
		fi
	fi
}

arch_news() {
	# Grab the latest Arch Linux news
	python ./Scripts/ArchNews.py
}

update_mirrorlist() {
	# Get an up-to-date mirrorlist that is sorted by speed and syncronization
	sudo reflector --country 'United States' --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
}

upgrade_system() {
	# Upgrade the system
	sudo pacman -Syu
}

aur_list() {
	list=""
	while IFS= read -r -d $'\0'; do
		for D in $REPLY/*/; do 
			if [ -d "$D" ]; then
				list="${list}_${D}"
			fi
		done
	done < <(sudo find /home -name ".aur" -print0)

	echo "${list:1}"
}

rebuild_aur() {
	# Rebuild AUR packages
	local aur_list=$(aur_list)
	IFS='_' read -r -a aur_list <<< "${aur_list}"

	ORIGIN_DIR="$(pwd)"
	for aur_dir in "${aur_list[@]}"; do
		cd "$aur_dir"
		git pull origin master
		makepkg -sirc
	done
	cd $ORIGIN_DIR
}

remove_pacfiles() {
	# Automatically remove specified pacfiles
	if [ -f /etc/pacman.d/mirrorlist.pacnew ]; then
		sudo rm /etc/pacman.d/mirrorlist.pacnew
	fi
}

remove_orphans() {
	# Remove unused orphan packages
	ORPHANED="$(pacman -Qtd)"
	if [ -n "${ORPHANED/[ ]*\n/}" ]; then
		echo "ORPHANED PACKAGES: $ORPHANED"
		read -r -p "Do you want to remove the above orphaned packages? [y/N]"
		if [ $REPLY == "y" ]; then
			sudo pacman -Rns $(pacman -Qtdq)
		fi
	fi
}

upgrade_alerts() {
	# Pay attention to alerts while upgrading the system
	echo "NOTICE: Check /var/log/pacman.log for alerts that might of come up while upgrading the system."

	# TODO: Use '/var/log/pacman.log' to automatically pick up any alerts for the user
	# TODO: Maybe save last update and retrieve all pacman warnings since then
}

find_pacfiles() {
	# Find and act on any .pacnew or .pacsave files
	sudo updatedb
	PACFILES="$(locate --existing --regex "\.pac(new|save)$")"
	if [ -n "${PACFILES/[ ]*\n/}" ]; then
		echo "PACFILES: $PACFILES"
	fi
}

check_dropped() {
	# Check for dropped packages
	DROPPED="$(pacman -Qm)"
	if [ -n "${DROPPED/[ ]*\n/}" ]; then
		echo "DROPPED: $DROPPED"
	fi

	# TODO: Don't display AUR packages in the dropped list
	# TODO: Delete dropped packages
}

notify_actions() {
	# Notify of anything worth mentioning
	upgrade_alerts
	find_pacfiles
	check_dropped
}

clean_cache() {
	# Remove all packages from cache that are not currently installed
	sudo pacman -Sc
}

clean_symlinks() {
	# Remove broken symlinks
	BROKEN_SYMLINKS="$(sudo find /home -xtype l -print)"
	if [ -n "${BROKEN_SYMLINKS/[ ]*\n/}" ]; then
		echo "BROKEN SYMLINKS: $BROKEN_SYMLINKS"
		read -r -p "Do you want to remove the above broken symlinks? [y/N]"
		if [ $REPLY == "y" ]; then
			while IFS= read -r -d $'\0'; do 
				rm $REPLY
			done < <(sudo find /home -xtype l -print0)
		fi
	fi	
}

clean_config() {
	# Clean up old configuration files
	python ./Scripts/rmjunk.py
	echo "NOTICE: Check ~/, ~/.config/, ~/.cache/, and ~/.local/share to further clean up old and potentially conflicting configuration files."
}

remove_lint() {
	# Run rmlint for further system cleaning
	rmlint /home
	sed -i -r "s/^handle_emptydir.*(Desktop|Documents|Downloads|Music|Pictures|Public|Templates|Videos).*//" rmlint.sh
	./rmlint.sh -x
	rm rmlint.sh
	rm rmlint.json
}

system_upgrade() {
	# Upgrade the System
	#fetch_warnings
	#update_mirrorlist
	#upgrade_system
	rebuild_aur
	#remove_pacfiles
	#remove_orphans
	#notify_actions
}

system_clean() {
	# Clean the filesystem
	clean_cache
	clean_symlinks
	remove_lint
	clean_config
}

fetch_news() {
	# Get latest news
	arch_news
}


menu_options() {
	# Display menu options
	clear
	echo "1) Arch Linux News"
	echo "2) Upgrade the System"
	echo "3) Clean the Filesystem"
	echo "0) Exit"

	# TODO: System security options? (tripwire, rkhunter)
	# TODO: Backup/restore system?
}

# Take appropriate action
while menu_options && read -r -p 'Action to take: ' response && [ "$response" != "0" ]; do
	case "$response" in
		"1")
			fetch_news
			;;
		"2")
			system_upgrade
			;;
		"3")
			system_clean
			;;
		*)
			echo "Please choose an existing option"
			;;
	esac

	read -r -p 'Press any key to continue...'	
done
