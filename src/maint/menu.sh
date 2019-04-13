#!/bin/bash

#######################################################################
####################### Menu Option Definitions #######################
#######################################################################

fetch_news() {
	# Get latest news
	arch_news
	printf "\n"
}

system_upgrade() {
	# Upgrade the System
	fetch_warnings
	update_mirrorlist
	upgrade_system
	rebuild_aur
	upgrade_warnings
	printf "\n"
}

system_clean() {
	# Clean the filesystem
	remove_orphaned_packages
	remove_dropped_packages
	clean_package_cache
	clean_broken_symlinks
	handle_pacfiles
	clean_old_config
	printf "\n"
}

system_errors() {
	# Check the system for errors
	failed_services
	journal_errors
	printf "\n"
}

backup_system() {
	# Backup the system
	execute_backup
	printf "\n"
}

restore_system() {
	# Restore the system
	execute_restore
	printf "\n"
}

update_settings() {
	# Update user settings
	modify_settings
	source_settings
	printf "\n"
}