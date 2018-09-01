# [Arch System Maintenance](https://aur.archlinux.org/packages/maint/)
maint is a package that will automatically take care of various Arch Linux system maintenance tasks. This package makes it easy to follow best practices while upgrading the system because the best practices are directly built in, as follows:
* Users can easily view the latest Arch Linux News right from the terminal.
* Users can follow the optimal upgrade steps with a single tap. First, the latest Arch Linux warning are gathered and the user is prompted to deal with any out-of-the-ordinary issues. Next, the user is given the option to update the mirrorlist. After that, the system is upgraded. The next step is to rebuild the user's AUR packages with the newly upgraded system packages. After that, both orphaned and dropped packages are searched for and the user is prompted to remove them. When that is finished, pacfiles are searched for and the user is prompted to deal with them. Finally, any other warnings that came up during the upgrade are output so the user can't miss them.
* Users are also given the option to clean up their filesystems. First, the package cache is cleaned to include only the latest pkg files. After that, broken symlinks are searched for in a list of susceptible directories. Finally, users are given advice on where to look for files to clean up.
* The option of instantly alerting the user towards important system errors has also been provided. First, failed services are searched for and displayed. After that, journaling errors over priority three are shown to the user.
* Users are also given the option to backup their systems. Duplicity has been chosen for its ability to gracefully handle incremental backups, allowing for faster subsequent runs. Additionally, the path where backups are stored can be modified by the user.
* All user-configurable options are stored in one easy-to-access file that is available right from the main menu. Options have meaningful default values, but offer the ability to be modified if the user sees fit. Users can change options such as their AUR package directory, mirrorlist country, backup location, and more.

## Installation / Upgrade
#### Installation:
git clone https://<span></span>aur.archlinux.org/maint.git <br />
cd maint <br />
makepkg -sirc

#### Upgrade:
cd maint <br />
git pull origin master <br />
makepkg -sirc

## Setup
1. Update settings to reflect the country you want your mirrorlists to be generated in. (Default is United States)
2. Update settings to use the location where you store your AUR packages. (Default is $HOME/.aur)
3. Update settings to use the location of where you want to store your system backups. (Default is /usr/local/backup)

## Usage
maint

#### Options:
1. Arch Linux News
2. Upgrade System
3. Clean Filesystem
4. System Error Check
5. Backup System
6. Update Settings
7. Exit

##Notes for advanced users
* If you are building this package from source then you will have to replace {{PKG_PATH}} in the main executable.