#!/bin/bash

#######################################################################
######################## System Upgrade Options #######################
#######################################################################

# Country to generate the mirror list for
export MIRRORLIST_COUNTRY='United States'

# Directory where currently installed AUR packages are stored
export AUR_DIR="$HOME/.aur"

#######################################################################
##################### Filesystem Cleaning Options #####################
#######################################################################

# Directories in which broken symlinks should be searched
export SYMLINKS_CHECK=("/bin"
                       "/etc"
                       "/home"
                       "/lib"
                       "/lib64"
                       "/opt"
                       "/srv"
                       "/usr")

#######################################################################
######################## System Backup Options ########################
#######################################################################

# Protocol to use while backing up the system
export BACKUP_PROTOCOL="file"

# Where to save the system backup
export BACKUP_SAVE="/usr/local/backup"

# Directories to exclude from backup
export BACKUP_EXCLUDE=("/dev"
                       "/proc"
                       "/sys"
                       "/tmp"
                       "/run"
                       "/mnt"
                       "/media"
                       "/lost+found")
