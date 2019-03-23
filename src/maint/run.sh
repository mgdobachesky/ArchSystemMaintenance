#!/bin/bash

pkg_path() {
	# Return the path of the package
	dirname "$(readlink $0)"
}

source_settings() {
	# Bring in user settings
	source $(pkg_path)/settings.sh
}

source_logic() {
	# Bring in logic
	source $(pkg_path)/logic.sh
}

source_menu() {
	# Bring in logic
	source $(pkg_path)/menu.sh
}

execute_maint() {
	main
	
	if [[ "$?" == 1 ]]; then
		read -r -p "Would you like to update settings? [y/N]"
		if [[ "$REPLY" =~ [yY] ]]; then
			update_settings
		fi
	fi
}

# Make sure script is running as root
if [[ "$EUID" -ne 0 ]]; then
	echo "maint must be run as root" 1>&2
	exit 1
fi

# Continue if script is running as root
if [[ "$EUID" -eq 0 ]]; then
	# Import program files
	source_settings
	source_logic
	source_menu

	case "$USER_INTERFACE" in
		'cli')
			source $(pkg_path)/ui/cli.sh
			;;
		'nCurses')
			source $(pkg_path)/ui/nCurses.sh
			;;
		*)
			echo "Incorrect USER_INTERFACE setting" 1>&2
			exit 1	
	esac

	execute_maint
fi