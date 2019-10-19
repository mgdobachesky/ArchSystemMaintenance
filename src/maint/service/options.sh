#!/bin/bash

modify_settings() {
	case "$SETTINGS_EDITOR" in
		'vim')
			vim $(pkg_path)/settings.sh;;
		'nano')
			nano $(pkg_path)/settings.sh;;
		*)
			fallback_editor;;
	esac
}

repair_settings() {
	read -r -p "Would you like to repair settings? [y/N]"
	if [[ "$REPLY" =~ [yY] ]]; then
		update_settings
	fi
}
