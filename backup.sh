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


#### OS check ####

check_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "$ID")
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    OS_VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID")
    OS_VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS="debian"
    OS_VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    OS="SuSE"
    OS_VER="?"
  elif [ -f /etc/redhat-release ]; then
    OS="Red Hat/CentOS"
    OS_VER="?"
  else
    OS=$(uname -s)
    OS_VER=$(uname -r)
  fi

  OS=$(echo "$OS")
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}


#### Delete entire panel ####

restore() {
BKP="/var/www/pterodactyl/PanelBackup/PanelBackup.zip"
PTERO="/var/www/pterodactyl"
    if [ -f "$BKP" ]; then
            mv "$BKP" /var/www
            rm -r "$PTERO"
            mkdir -p "$PTERO"
            mv "/var/www/PanelBackup.zip" /var/www/pterodactyl
            unzip /var/www/pterodactyl/PanelBackup.zip
            rm -r PanelBackup.zip
            cd /var/www/pterodactyl/PanelBackup
            cp -rf app config database public resources routes storage .env /var/www/pterodactyl
            rm -r PanelBackup
        else
            print_brake 45
            echo -e "* ${red}The backup does not exist, aborting...${reset}"
            print_brake 45
            exit 1
    fi
    case "$OS" in
    debian | ubuntu)
        if [ ! "$(command -v nginx)" ]; then
                chown -R www-data:www-data /var/www/pterodactyl/*
            else
                chown -R www-data:www-data /var/www/pterodactyl/*
        fi
    ;;
    esac
    if [ "$OS_VER_MAJOR" == "7" ] && [ "$OS_VER_MAJOR" == "8" ]; then
        if [ ! "$(command -v nginx)" ]; then
            chown -R nginx:nginx /var/www/pterodactyl/*
        elif [ ! "$(command -v apache)" ]; then
            chown -R apache:apache /var/www/pterodactyl/*
        fi
    fi     
}


#### Restore Backup ####

main() {
echo
print_brake 35
echo -e "* ${GREEN}Checking for a backup...${reset}"
print_brake 35
echo
if [ -f "/var/www/pterodactyl/PanelBackup/PanelBackup.zip" ]; then
cd /var/www/pterodactyl/PanelBackup
unzip PanelBackup.zip
rm -R PanelBackup.zip
cp -rf app config database public resources routes storage .env /var/www/pterodactyl
cd
else
print_brake 45
echo -e "* ${red}There was no backup to restore, Aborting...${reset}"
print_brake 45
echo
exit 1
fi
if [ -f "/var/www/pterodactyl/PanelBackup/tailwind.config.js" ]; then
cd /var/www/pterodactyl/PanelBackup
cp -rf tailwind.config.js /var/www/pterodactyl
cd ..
rm -rf PanelBackup
else
echo
fi
}


bye() {
print_brake 50
echo
echo -e "${GREEN}* Backup restored successfully!"
echo -e "* Thank you for using this script."
echo -e "* Support group: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${reset}"
echo
print_brake 50
}


#### Exec Script ####
restore
bye