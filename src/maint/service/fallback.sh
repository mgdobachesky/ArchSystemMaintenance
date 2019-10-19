#!/bin/bash

fallback_view() {
	printf "\nIncorrect USER_INTERFACE setting -- falling back to default\n" 1>&2
	read
	source $(pkg_path)/view/dialog.sh
}

fallback_editor() {
	printf "\nIncorrect SETTINGS_EDITOR setting -- falling back to default\n" 1>&2
	read
	nano $(pkg_path)/settings.sh
}
