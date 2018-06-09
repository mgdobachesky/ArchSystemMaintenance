#!/bin/bash

fetch_warnings() {
	# Fetch and warn the user if any known problems have been published since the last upgrade
	LAST_UPGRADE="$(cat /var/log/pacman.log | grep -Po "(\d{4}-\d{2}-\d{2})(?=.*pacman -Syu)" | tail -1)"

	python ./Scripts/ArchNews.py $LAST_UPGRADE
	ALERTS=$?
	
	if [ $ALERTS == 1 ]; then
		echo "WARNING: This upgrade requires out-of-the-ordinary user intervention."
		echo "Continue only after fully resolving the above issue(s)."
		echo ""

		read -r -p "Are you ready to continue? [y/N]"
		if [ $REPLY != "y" ]; then
			exit
		fi
	fi
}

arch_news() {
	# Grab the latest Arch Linux news
	python ./Scripts/ArchNews.py 0
}

update_mirrorlist() {
	# Get an up-to-date mirrorlist that is sorted by speed and syncronization
	sudo reflector --country 'United States' --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist

	# TODO: Maybe delete mirrorlist.pacnew if it exists?
}

upgrade_system() {
	# Upgrade the system
	sudo pacman -Syu
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
				makepkg -sirc
			fi

		done
	done < <(sudo find /home -name ".aur" -print0)
	cd $ORIGIN_DIR
}

remove_orphans() {
	# Remove unused orphan packages
	ORPHANED="$(pacman -Qtd)"
	if [ -n "${ORPHANED/[ ]*\n/}" ];
	then
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
	BROKEN_SYMLINKS="$(sudo find ~ -xtype l -print)"
	if [ -n "${BROKEN_SYMLINKS/[ ]*\n/}" ];
	then
		echo "BROKEN SYMLINKS: $BROKEN_SYMLINKS"
		read -r -p "Do you want to remove the above broken symlinks? [y/N]"
		if [ $REPLY == "y" ]; then
			while IFS= read -r -d $'\0'; do 
				rm $REPLY
			done < <(sudo find ~ -xtype l -print0)
		fi
	fi	
}

clean_config() {
	# Clean up old configuration files
	echo "NOTICE: Check ~/, ~/.config/, ~/.cache/, and ~/.local/share for old configuration files."
	python ./Scripts/rmjunk.py 
}

remove_lint() {
	# Run rmlint for further system cleaning
	rmlint ~
	sed -i "s/^handle_emptydir[^\(\)].*//" rmlint.sh
	./rmlint.sh -x
	rm rmlint.sh
	rm rmlint.json

	# TODO: avoid deleting only certain empty directories in $HOME, rather than all of them
}

system_upgrade() {
	# Upgrade the System
	fetch_warnings
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
	remove_lint
}

system_security() {
	# Check system for security issues
	echo "TODO"

	# TODO: tripwire?
	# TODO: rkhunter?
}

fetch_news() {
	# Get latest news
	arch_news
}


menu_options() {
	# Display menu options
	clear
	echo "1) Upgrade the System"
	echo "2) Clean the Filesystem"
	echo "3) Check system security"
	echo "4) Fetch latest Arch Linux news"
	echo "0) Exit"

	# TODO: Backup/restore system?
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
		"3")
			system_security
			;;
		"4")
			fetch_news
			;;
		*)
			echo "Please choose an existing option"
			;;
	esac

	read -r -p 'Press any key to continue...'	
done
