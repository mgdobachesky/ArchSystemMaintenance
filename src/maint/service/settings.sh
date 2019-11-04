#!/bin/bash

modify_settings() {
	if [[ -n "$EDITOR" ]]; then
		execute_editor "$EDITOR" "\nEDITOR environment variable of $EDITOR is not valid"
	elif [[ "$SETTINGS_EDITOR" =~ (vim|nano|emacs) ]]; then
		execute_editor "$SETTINGS_EDITOR"
	else
		fallback_editor
	fi
}

execute_editor() {
	check_optdepends "$1"
	if [[ "$?" == 0 ]]; then
		$1 $(pkg_path)/settings.sh
	else
		printf "${2:-\n$1 is not installed}"
		fallback_editor
	fi
}

repair_settings() {
	read -r -p "Would you like to repair settings? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		update_settings
	fi
}
