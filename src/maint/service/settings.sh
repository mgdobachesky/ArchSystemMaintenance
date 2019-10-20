#!/bin/bash

modify_settings() {
	case "$SETTINGS_EDITOR" in
		'nano')
			nano $(pkg_path)/settings.sh;;
		'vim')
			check_optdepends vim
			if [[ "$?" == 0 ]]; then
				vim $(pkg_path)/settings.sh
			else
				printf "\nvim is not installed"
				fallback_editor
			fi;;
		'emacs')
			check_optdepends emacs
			if [[ "$?" == 0 ]]; then
				emacs $(pkg_path)/settings.sh
			else
				printf "\nemacs is not installed"
				fallback_editor
			fi;;
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
