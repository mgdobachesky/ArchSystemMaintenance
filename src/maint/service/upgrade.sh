#!/bin/bash

update_mirrorlist() {
	printf "\n"
	read -r -p "Do you want to get an updated mirrorlist? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		printf "Updating mirrorlist...\n"
		reflector --country "$MIRRORLIST_COUNTRY" --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
		printf "...Mirrorlist updated\n"
	fi
}

upgrade_system() {
	printf "\nUpgrading the system...\n"
	pacman -Syu
	printf "...Done upgrading the system\n"
}

aur_setup() {
	printf "\n"
	read -r -p "Do you want to setup the AUR package directory at $AUR_DIR? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		printf "Setting up AUR package directory...\n"
		if [[ ! -d "$AUR_DIR" ]]; then
			mkdir -p "$AUR_DIR"
			test -n "$SUDO_USER" && chown "$SUDO_USER" "$AUR_DIR"
		fi

		chgrp "$1" "$AUR_DIR"
		chmod g+ws "$AUR_DIR"
		setfacl -d --set u::rwx,g::rx,o::rx "$AUR_DIR"
		setfacl -m u::rwx,g::rwx,o::- "$AUR_DIR"
		printf "...AUR package directory set up at $AUR_DIR\n"
	fi
}

rebuild_aur() {
	AUR_DIR_GROUP="nobody"
	test -n "$SUDO_USER" && AUR_DIR_GROUP="$SUDO_USER"

	if [[ -w "$AUR_DIR" ]] && sudo -u "$AUR_DIR_GROUP" test -w "$AUR_DIR"; then
		printf "\n"
		read -r -p "Do you want to rebuild the AUR packages in $AUR_DIR? [y/N]"
		if [[ "$REPLY" =~ [yY] ]]; then
			printf "Rebuilding AUR packages...\n"
			if [[ -n "$(ls -A $AUR_DIR)" ]]; then
				starting_dir="$(pwd)"
				for aur_pkg in "$AUR_DIR"/*/; do
					if [[ -d "$aur_pkg" ]]; then
						if ! sudo -u "$AUR_DIR_GROUP" test -w "$aur_pkg"; then
							chmod -R g+w "$aur_pkg"
						fi
						cd "$aur_pkg"
						if [[ "$AUR_UPGRADE" == "true" ]]; then
							git pull origin master
						fi
						source PKGBUILD
						pacman -S --needed --asdeps "${depends[@]}" "${makedepends[@]}" --noconfirm
						sudo -u "$AUR_DIR_GROUP" makepkg -fc --noconfirm
						pacman -U "$(sudo -u $AUR_DIR_GROUP makepkg --packagelist)" --noconfirm
					fi
				done
				cd "$starting_dir"
				printf "...Done rebuilding AUR packages\n"
			else
				printf "...No AUR packages in $AUR_DIR\n"
			fi
		fi
	else
		printf "\nAUR package directory not set up"
		aur_setup "$AUR_DIR_GROUP"
	fi
}

handle_pacfiles() {
	printf "\nChecking for pacfiles...\n"
	pacdiff
	printf "...Done checking for pacfiles\n"
}

upgrade_warnings() {
	printf "\nChecking for upgrade warnings...\n"
	last_upgrade="$(sed -n '/pacman -Syu/h; ${x;s/.\([0-9-]*\).*/\1/p;}' /var/log/pacman.log)"

	if [[ -n "$last_upgrade" ]]; then
		paclog --after="$last_upgrade" | paclog --warnings
	fi
	printf "...Done checking for upgrade warnings\n"
}
