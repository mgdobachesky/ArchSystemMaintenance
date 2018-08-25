# Arch System Maintenance
[AUR maint package](https://aur.archlinux.org/packages/maint/)

## Installation / Upgrade
#### Installation
git clone https://<span></span>aur.archlinux.org/maint.git <br />
cd maint <br />
makepkg -sirc

#### Upgrade
cd maint
git pull origin master
makepkg -sirc

### Setup:
1. Update settings to reflect the country you want your mirrorlists to be generated in. (Default is United States)
2. Update settings to use the location where you store your AUR packages. (Default is $HOME/.aur)
3. Update settings to use the location of where you want to store your system backups. (Default is /usr/local/backup)

## Usage
maint

### Options:
1. Arch Linux News
2. Upgrade System
3. Clean Filesystem
4. System Error Check
5. Backup System
6. Update Settings
7. Exit
