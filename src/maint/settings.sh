# User interface of choice (cli, nCurses)
export USER_INTERFACE='nCurses'

# Editor used to modify settings (nano, vim)
export SETTINGS_EDITOR='vim'

# Country to generate the mirror list for
export MIRRORLIST_COUNTRY='United States'

# Decide to upgrade AUR Packages while rebuilding
export AUR_UPGRADE=true

# Whitelist of AUR packages that should not show up as dropped packages
export AUR_WHITELIST=()

# Directory where currently installed AUR packages are stored
export AUR_DIR="/home/build"

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
