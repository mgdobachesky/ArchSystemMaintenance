#!/bin/bash

#######################################################################
####################### nCurses User Interface ########################
#######################################################################

dialog_check_exit() {
	printf "Done - Press enter to continue\n";
	read
}

main () {
	# Continue if script is running as root
	if [[ "$EUID" -eq 0 ]]; then
		while true; do
			# Take appropriate action
			REPLY=$(dialog --stdout --title "Arch System Maintenance" --menu "Choose Maintenence Task:" 15 50 8 \
					1 "Arch Linux News" \
					2 "Upgrade System" \
					3 "Clean Filesystem" \
					4 "System Error Check" \
					5 "Backup System" \
					6 "Restore System" \
					7 "Update Settings" \
					0 "Exit")
			clear;
			case "$REPLY" in
				1) fetch_news;;
				2) system_upgrade; dialog_check_exit;;
				3) system_clean; dialog_check_exit;;
				4) system_errors;;
				5) backup_system; dialog_check_exit;;
				6) restore_system; dialog_check_exit;;
				7) update_settings;;
				*) clear; exit;;
			esac
		done
	fi
}