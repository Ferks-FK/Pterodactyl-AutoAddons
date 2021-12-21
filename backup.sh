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
# MORE BUTONS
MORE_BUTTONS="/var/www/pterodactyl/resources/scripts/components/server/MoreButtons.tsx"
# PMA_BUTTON_NAVBAR
PMA_ARCH="/var/www/pterodactyl/resources/scripts/routers/ServerRouter.tsx"
PMA_FILES="/var/www/pterodactyl/public/pma"
# PMA_BUTTON_DATABASE_TAB
PMA_FILE="/var/www/pterodactyl/resources/scripts/components/server/databases/DatabaseRow.tsx"
PMA_REDIRECT_FILE="/var/www/pterodactyl/public/pma_redirect.html"
PMA_NAME="/var/www/pterodactyl/public/phpmyadmin"
#
if [ -f "$MORE_BUTTONS" ]; then
  rm -r "$MORE_BUTTONS"
fi
if grep '<a href="/pma" target="_blank">PhpMyAdmin</a>' "$PMA_ARCH"; then
  sed -i '110d' "$PMA_ARCH"
  rm -r "$PMA_FILES"
fi
if grep 'location.replace("/pma_redirect.html");' "$PMA_FILE"; then
  sed -i '56,58d' "$PMA_FILE"
  sed -i '171,173d' "$PMA_FILE"
  rm -r "$PMA_NAME" "$PMA_REDIRECT_FILE"
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