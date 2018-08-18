# Country to generate the mirror list for
export MIRRORLIST_COUNTRY='United States'

# Directory where currently installed AUR packages are stored
export AURDEST="$HOME/.aur"

# Directories where broken symlinks should be searched for
export SYMLINKS_CHECK=("/bin"
                       "/etc"
                       "/home"
                       "/lib"
                       "/lib64"
                       "/opt"
                       "/srv"
                       "/usr")
                       