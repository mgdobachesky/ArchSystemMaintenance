#!/bin/bash

pkg_path() {
	# Return the path of the package
	if [[ -L "$0" ]]; then
		dirname "$(readlink $0)"
	else
		dirname "$0"
	fi
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

repair_settings() {
	read -r -p "Would you like to repair settings? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		update_settings
	fi
}

fallback_ui() {
	printf "\nIncorrect USER_INTERFACE setting -- falling back to default\n" 1>&2
	read
	source $(pkg_path)/ui/cli.sh
}

execute_main() {
	main
	
	if [[ "$?" == 1 ]]; then
		repair_settings
	fi
}

# Make sure script is running as root
if [[ "$EUID" -ne 0 ]]; then
	printf "This script must be run as root\n" 1>&2
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
			source $(pkg_path)/ui/cli.sh;;
		'dialog')
			source $(pkg_path)/ui/dialog.sh;;
		*)
			fallback_ui;;	
	esac

	execute_main
fi