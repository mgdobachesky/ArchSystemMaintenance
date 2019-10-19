#!/bin/bash

pkg_path() {
	if [[ -L "$0" ]]; then
		dirname "$(readlink $0)"
	else
		dirname "$0"
	fi
}

source_settings() {
	source $(pkg_path)/settings.sh
}

source_service() {
	source $(pkg_path)/service/news.sh
	source $(pkg_path)/service/upgrade.sh
	source $(pkg_path)/service/cleanup.sh
	source $(pkg_path)/service/errors.sh
	source $(pkg_path)/service/backup.sh
	source $(pkg_path)/service/options.sh
	source $(pkg_path)/service/fallback.sh
}

source_controller() {
	source $(pkg_path)/controller.sh
}

execute_main() {
	main
	
	if [[ "$?" == 1 ]]; then
		repair_settings
	fi
}

if [[ "$EUID" -ne 0 ]]; then
	printf "This script must be run as root\n" 1>&2
	exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
	source_settings
	source_service
	source_controller

	case "$USER_INTERFACE" in
		'cli')
			source $(pkg_path)/view/cli.sh;;
		'dialog')
			source $(pkg_path)/view/dialog.sh;;
		*)
			fallback_view;;	
	esac

	execute_main
fi
