#!/bin/bash

modify_settings() {
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
