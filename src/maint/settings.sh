#!/bin/bash

# Country to generate the mirror list for
export MIRRORLIST_COUNTRY='United States'

# Directory where currently installed AUR packages are stored
<<<<<<< HEAD
export AUR_DIR="/usr/local/aur/"
=======
export AUR_DIR="$HOME/.aur"
>>>>>>> master

# Where to store the system backup
export BACKUP_LOCATION="/usr/local/backup"

# Directories in which broken symlinks should be searched
export SYMLINKS_CHECK=("/bin"
                       "/etc"
                       "/home"
                       "/lib"
                       "/lib64"
                       "/opt"
                       "/srv"
                       "/usr")
