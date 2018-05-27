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
	echo "Getting an up-to-date mirrorlist:"
	#update_mirrorlist

	echo "Upgrading the system:"
	#upgrade_system

	echo "Pay attention to alerts while upgrading the system:"
	local ALERT_ACTION=$(upgrade_alerts)

	echo "Rebuilding AUR packages:"
	#rebuild_aur

	echo "Finding pacnew / pacsave files:"
	local PACFILES=$(find_pacfiles)

	echo "Checking for orphaned packages:"
	local ORPHANS=$(check_orphans)

	echo "Removing unused orphan packages:"
	remove_orphans

	echo "Checking for dropped packages:"
	local DROPPED=$(check_dropped)

	echo "Removing all packages from cache that are not installed:"
	clean_cache

	echo "Cleaning up old configuration files:"
	clean_config

	echo "Removing broken symlinks:"
	clean_symlinks

	echo "Notify user of any alerts:"
	notify_actions "$ALERT_ACTION" "$PACFILES" "$ORPHANED" "$DROPPED"

}

# Read arch linux website for potential problems
echo "Read the Arch Linux website for potential problems before continuing:"
read -r -p "Ready? [y/N] " response
if [[ "$response" == "y" ]];
then
	system_upgrade
else
	echo "Come back after reading the website for potential problems";
fi
