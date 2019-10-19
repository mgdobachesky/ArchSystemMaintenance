#!/bin/bash

fetch_news() {
	arch_news
	printf "\n"
}

system_upgrade() {
	fetch_warnings
	update_mirrorlist
	upgrade_system
	rebuild_aur
	handle_pacfiles
	upgrade_warnings
	printf "\n"
}

system_clean() {
	remove_orphaned_packages
	remove_dropped_packages
	clean_package_cache
	clean_broken_symlinks
	clean_old_config
	printf "\n"
}

system_errors() {
	failed_services
	journal_errors
	printf "\n"
}

backup_system() {
	execute_backup
	printf "\n"
}

restore_system() {
	execute_restore
	printf "\n"
}

update_settings() {
	modify_settings
	source_settings
	printf "\n"
}
