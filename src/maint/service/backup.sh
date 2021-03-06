#!/bin/bash

execute_backup() {
	if [[ -d "$BACKUP_LOCATION" ]]; then
		read -r -p "Do you want to backup the system to $BACKUP_LOCATION? [y/N]"
		if [[ "$REPLY" =~ [yY] ]]; then
				printf "\nBacking up the system...\n"
				rsync -aAXHS --info=progress2 --delete \
				--exclude-from <(printf '%s\n' "${BACKUP_EXCLUDE[@]}") \
				--exclude={"/swapfile","/lost+found","$BACKUP_LOCATION"} \
				/ "$BACKUP_LOCATION"
				touch "$BACKUP_LOCATION/verified_backup_image.lock"
				printf "...Done backing up to $BACKUP_LOCATION\n"
		fi
	else
		printf "\n$BACKUP_LOCATION is not an existing directory\n"
		read -r -p "Do you want to create backup directory at $BACKUP_LOCATION? [y/N]"
		if [[ "$REPLY" =~ [yY] ]]; then
			mkdir -p "$BACKUP_LOCATION"
			execute_backup
		fi
	fi
}

execute_restore() {
	read -r -p "Do you want to restore the system from $BACKUP_LOCATION? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		if [[ -a "$BACKUP_LOCATION/verified_backup_image.lock" ]]; then
			printf "\nRestoring the system...\n"
			rsync -aAXHS --info=progress2 --delete \
			--exclude-from <(printf '%s\n' "${BACKUP_EXCLUDE[@]}") \
			--exclude={"/swapfile","/lost+found","/verified_backup_image.lock","$BACKUP_LOCATION"} \
			"$BACKUP_LOCATION/" /
			printf "...Done restoring from $BACKUP_LOCATION\n"
		else
			printf "\nYou must create a system backup before restoring the system from it\n";
		fi
	fi
}
