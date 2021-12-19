#!/bin/bash

set -e

########################################################
# 
#         Pterodactyl-AutoAddons Installation
#
#         Created and maintained by Ferks-FK
#
#            Protected by GPL 3.0 License
#
########################################################

#### Variables ####
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"


print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}


hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}


#### Colors ####

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
reset="\e[0m"
red='\033[0;31m'


#### Deletes all files installed by the script ####

delete_files() {
MORE_BUTTONS="/var/www/pterodactyl/resources/scripts/components/server/MoreButtons.tsx"
if [ -f "$MORE_BUTTONS" ]; then
    rm -r "$MORE_BUTTONS"
fi
}

#### Restore Backup ####

restore() {
echo
print_brake 35
echo -e "* ${GREEN}Checking for a backup...${reset}"
print_brake 35
echo
if [ -f "/var/www/pterodactyl/PanelBackup/PanelBackup.zip" ]; then
    cd /var/www/pterodactyl/PanelBackup
    unzip PanelBackup.zip
    rm -R PanelBackup.zip
    cp -r -- * .env /var/www/pterodactyl
    rm -r /var/www/pterodactyl/PanelBackup
  else
    print_brake 45
    echo -e "* ${red}There was no backup to restore, Aborting...${reset}"
    print_brake 45
    echo
    exit 1
fi
}
 
bye() {
print_brake 50
echo
echo -e "* ${GREEN}Backup restored successfully!"
echo -e "* Thank you for using this script."
echo -e "* Support group: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${reset}"
echo
print_brake 50
}


#### Exec Script ####
delete_files
restore
bye