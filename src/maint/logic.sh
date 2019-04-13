#!/bin/bash

#######################################################################
########################## Menu Option Logic ##########################
#######################################################################

arch_news() {
	# Grab the latest Arch Linux news
	export COLUMNS
	python $(pkg_path)/other/archNews.py | less
}

fetch_warnings() {
	# Fetch and warn the user if any known problems have been published since the last upgrade
	export COLUMNS
	printf "\nChecking Arch Linux news...\n"
	last_upgrade="$(sed -n '/pacman -Syu/h; ${x;s/.\([0-9-]*\).*/\1/p;}' /var/log/pacman.log)"

	if [[ -n "$last_upgrade" ]]; then
		python $(pkg_path)/other/archNews.py "$last_upgrade"
	else
		python $(pkg_path)/other/archNews.py
	fi
	alerts="$?"

	if [[ "$alerts" == 1 ]]; then
		printf "WARNING: This upgrade requires out-of-the-ordinary user intervention\n"
		printf "Continue only after fully resolving the above issue(s)\n"

		printf "\n"
		read -r -p "Are you ready to continue? [y/N]"
		if [[ ! "$REPLY" =~ [yY] ]]; then
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
	if [[ "$REPLY" =~ [yY] ]]; then
		printf "Updating mirrorlist...\n"
		reflector --country "$MIRRORLIST_COUNTRY" --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
		printf "...Mirrorlist updated\n"
	fi
}

upgrade_system() {
	# Upgrade the system
	printf "\nUpgrading the system...\n"
	pacman -Syu
	printf "...Done upgrading the system\n"
}

aur_setup() {
	# Make sure the AUR directory is setup correctly
	printf "\n"
	read -r -p "Do you want to setup the AUR package directory at $AUR_DIR? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		printf "Setting up AUR package directory...\n"
		if [[ ! -d "$AUR_DIR" ]]; then
			mkdir "$AUR_DIR"
		fi
		chgrp nobody "$AUR_DIR"
		chmod g+ws "$AUR_DIR"
		setfacl -d --set u::rwx,g::rx,o::rx "$AUR_DIR"
		setfacl -m u::rwx,g::rwx,o::- "$AUR_DIR"
		printf "...AUR package directory set up at $AUR_DIR\n"
	fi
}

rebuild_aur() {
	# Rebuild AUR packages
	printf "\n"
	read -r -p "Do you want to rebuild AUR packages? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		if [[ -w "$AUR_DIR" ]] && sudo -u nobody bash -c "[[ -w $AUR_DIR ]]"; then
			printf "Rebuilding AUR packages...\n"
			if [[ -n "$(ls -A $AUR_DIR)" ]]; then
				starting_dir="$(pwd)"
				for aur_pkg in "$AUR_DIR"/*/; do
					if [[ -d "$aur_pkg" ]]; then
						if sudo -u nobody bash -c "[[ ! -w $aur_pkg ]]"; then
							chmod -R g+w "$aur_pkg"
						fi
						cd "$aur_pkg"
						if [[ "$AUR_UPGRADE" == "true" ]]; then
							git pull origin master
						fi
						source PKGBUILD
						pacman -S --needed --asdeps "${depends[@]}" "${makedepends[@]}" --noconfirm
						sudo -u nobody makepkg -fc --noconfirm
						pacman -U "$(sudo -u nobody makepkg --packagelist)" --noconfirm
					fi
				done
				cd "$starting_dir"
				printf "...Done rebuilding AUR packages\n"
			else
				printf "...No AUR packages in $AUR_DIR\n"
			fi
		else
			printf "AUR package directory not set up\n"
			aur_setup
		fi
	fi
}

remove_orphaned_packages() {
	# Remove unused orphan packages
	printf "\nChecking for orphaned packages...\n"
	mapfile -t orphaned < <(pacman -Qtdq)
	if [[ "${orphaned[*]}" ]]; then
		printf "ORPHANED PACKAGES FOUND:\n"
		printf '%s\n' "${orphaned[@]}"
		read -r -p "Do you want to remove the above orphaned packages? [y/N]"
		if [[ "$REPLY" =~ [yY] ]]; then
			pacman -Rns --noconfirm "${orphaned[@]}"
		fi
	else
		printf "...No orphaned packages found\n"
	fi
}

remove_dropped_packages() {
	# Remove dropped packages
	printf "\nChecking for dropped packages...\n"
	whitelist="maint"
	for aur_pkg in "${AUR_WHITELIST[@]}"; do
		whitelist="$whitelist|$aur_pkg"
	done
	if [[ -d "$AUR_DIR" ]]; then
		for aur_pkg in "$AUR_DIR"/*/; do
			if [[ -d "$aur_pkg" ]]; then
				whitelist="$whitelist|$(basename "$aur_pkg")"
			fi
		done
	fi
	mapfile -t dropped < <(awk "!/${whitelist}/" <(pacman -Qmq))

	if [[ "${dropped[*]}" ]]; then
		printf "DROPPED PACKAGES FOUND:\n"
		printf '%s\n' "${dropped[@]}"
		read -r -p "Do you want to remove the above dropped packages? [y/N]"
		if [[ "$REPLY" =~ [yY] ]]; then
			pacman -Rns --noconfirm "${dropped[@]}"
		fi
	else
		printf "...No dropped packages found\n"
	fi
}

handle_pacfiles() {
	# Find and act on any .pacnew or .pacsave files
	printf "\nChecking for pacfiles...\n"
	pacdiff
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

clean_package_cache() {
	# Clean up the package cache
	printf "\n"
	read -r -p "Do you want to clean up the package cache? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		printf "Cleaning up the package cache...\n"
		paccache -r
		printf "...Done cleaning up the package cache\n"
	fi
}

clean_broken_symlinks() {
	# Check for broken symlinks in specified directories
	printf "\nChecking for broken symlinks...\n"
	mapfile -t broken_symlinks < <(find "${SYMLINKS_CHECK[@]}" -xtype l -print)
	if [[ "${broken_symlinks[*]}" ]]; then
		printf "BROKEN SYMLINKS FOUND:\n"
		printf '%s\n' "${broken_symlinks[@]}"
		read -r -p "Do you want to remove the broken symlinks above? [y/N]"
		if [[ "$REPLY" =~ [yY] ]]; then
			rm "${broken_symlinks[@]}"
		fi
	else
		printf "...No broken symlinks found\n"
	fi
}

clean_old_config() {
	# Remind the user to clean up old configuration files
	user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
	if [[ -z "$user_home" ]]; then
		user_home="~"
	fi
	printf "\nREMINDER: Check the following directories for old configuration files\n"
	printf "$user_home/\n"
	printf "$user_home/.config/\n"
	printf "$user_home/.cache/\n"
	printf "$user_home/.local/share/\n"
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
	read -r -p "Do you want to backup the system to $BACKUP_LOCATION? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		if [[ -d "$BACKUP_LOCATION" ]]; then
			printf "\nBacking up the system...\n"
			rsync -aAXHS --info=progress2 --delete \
			--exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/swapfile","/lost+found","$BACKUP_LOCATION"} \
			/ "$BACKUP_LOCATION"
			touch "$BACKUP_LOCATION/verified_backup_image.lock"
			printf "...Done backing up to $BACKUP_LOCATION\n"
		else
			printf "\n$BACKUP_LOCATION is not an existing directory\n"
		fi
	fi
}

execute_restore() {
	# Execute restore operations
	read -r -p "Do you want to restore the system from $BACKUP_LOCATION? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		if [[ -a "$BACKUP_LOCATION/verified_backup_image.lock" ]]; then
			printf "\nRestoring the system...\n"
			rsync -aAXHS --info=progress2 --delete \
			--exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/swapfile","/lost+found","/verified_backup_image.lock","$BACKUP_LOCATION"} \
			"$BACKUP_LOCATION/" /
			printf "...Done restoring from $BACKUP_LOCATION\n"
		else
			printf "\nYou must create a system backup before restoring the system from it\n";
		fi
	fi
}

fallback_editor() {
	printf "\nIncorrect SETTINGS_EDITOR setting -- falling back to default" 1>&2
	read
	vim $(pkg_path)/settings.sh
}

modify_settings() {
	# Modify user settings
	case "$SETTINGS_EDITOR" in
		'vim')
			vim $(pkg_path)/settings.sh;;
		'nano')
			check_optdepends nano
			if [[ "$?" == 0 ]]; then
				nano $(pkg_path)/settings.sh
			else
				printf "\nnano is not installed"
				fallback_editor
			fi
			;;
		*)
			fallback_editor;;
	esac
}

check_optdepends() {
	if [[ -n "$(command -v $1)" ]]; then
		return 0
	else
		return 1
	fi
}

