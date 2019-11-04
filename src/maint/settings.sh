#######################################################################
######################## Customization Options ########################
#######################################################################

# User interface of choice (cli, dialog)
export USER_INTERFACE='dialog'

# Editor used to modify settings (vim, nano, emacs)
# NOTE: EDITOR environment variable takes precedence
export SETTINGS_EDITOR='vim'

# Country to generate the mirror list for
export MIRRORLIST_COUNTRY='United States'


#######################################################################
############################# AUR Options #############################
#######################################################################

# Directory where currently installed AUR packages are stored
export AUR_DIR="/home/build"

# Decide whether or not to upgrade AUR Packages while rebuilding
export AUR_UPGRADE=true

# Whitelist of AUR packages that should not show up as dropped packages
# NOTE: AUR packages in the AUR_DIR will automatically be whitelisted
export AUR_WHITELIST=()


#######################################################################
####################### Backup / Restore Options ######################
#######################################################################

# Where to store the system backup
export BACKUP_LOCATION="/usr/local/backup"

# Directories to exclude from backup/restore process
export BACKUP_EXCLUDE=("/dev/*" "/proc/*" "/sys/*" "/tmp/*" "/run/*" "/mnt/*" "/media/*")


#######################################################################
####################### System Cleaning Options #######################
#######################################################################

# Directories in which broken symlinks should be searched for
export SYMLINKS_CHECK=("/etc" "/home" "/opt" "/srv" "/usr")
