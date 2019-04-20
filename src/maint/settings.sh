# User interface of choice (cli, dialog)
export USER_INTERFACE='dialog'

# Editor used to modify settings (nano, vim)
export SETTINGS_EDITOR='vim'

# Country to generate the mirror list for
export MIRRORLIST_COUNTRY='United States'

# Decide whether or not to upgrade AUR Packages while rebuilding
export AUR_UPGRADE=true

# Whitelist of AUR packages that should not show up as dropped packages
# NOTE: AUR packages in the AUR_DIR will automatically be whitelisted
export AUR_WHITELIST=()

# Directory where currently installed AUR packages are stored
export AUR_DIR="/home/build"

# Where to store the system backup
export BACKUP_LOCATION="/usr/local/backup"

# Directories in which broken symlinks should be searched
export SYMLINKS_CHECK=("/etc" "/home" "/opt" "/srv" "/usr")
