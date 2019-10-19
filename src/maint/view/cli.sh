#!/bin/bash

main() {
	if [[ "$EUID" -eq 0 ]]; then
		PS3='Action to take: '
		select opt in "Arch Linux News" "Upgrade System" "Clean Filesystem" "System Error Check" "Backup System" "Restore System" "Update Settings" "Exit"; do
			case $REPLY in
				1) fetch_news;;
				2) system_upgrade;;
				3) system_clean;;
				4) system_errors;;
				5) backup_system;;
				6) restore_system;;
				7) update_settings;;
				8) break;;
				*) echo "Please choose an existing option";;
			esac
		done
	fi
}
