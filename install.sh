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

SCRIPT_VERSION="v3.3"


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

reset="\e[0m"
red='\033[0;31m'

error() {
  red='\033[0;31m'
  reset="\e[0m"

  echo ""
  echo -e "* ${red}ERROR${reset}: $1"
  echo ""
}


#### Check Sudo ####

if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi


#### Check Curl ####

if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

cancel() {
echo
echo -e "* ${red}Installation Canceled!${reset}"
done=true
exit 1
}

done=false

echo
print_brake 70
echo "* Pterodactyl-AutoAddons Script @ $SCRIPT_VERSION"
echo
echo "* Copyright (C) 2021 - $(date +%Y), Ferks-FK."
echo "* https://github.com/Ferks-FK/Pterodactyl-AutoAddons"
echo
echo "* This script is not associated with the official Pterodactyl Project."
print_brake 70
echo

Backup() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/backup.sh)
}

More_Buttons() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/More_Buttons/build.sh)
}

More_Server_Info() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/More_Server_Info/build.sh)
}

Server_Router_Icons() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/Server_Router_Icons/build.sh)
}

PMA_Button_NavBar() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/PMA_Button_NavBar/build.sh)
}

PMA_Button_Database_Tab() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/PMA_Button_Database_Tab/build.sh)
}

MC_Paste() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/MC_Paste/build.sh)
}

Bigger_Console() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/Bigger_Console/build.sh)
}

Files_In_Editor() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/Files_In_Editor/build.sh)
}

PhpMyAdmin() {
bash <(curl -s https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/features/PhpMyAdmin/build.sh)
}


while [ "$done" == false ]; do
  options=(
    "Restore Panel Backup (To remove some addon and restore your old panel.)"
    "Install More Buttons (Only 1.6.6 and 1.7.0)"
    "Install More Server Info (Only 1.6.6 and 1.7.0)"
    "Install Server Router Icons (Only 1.6.6 and 1.7.0)"
    "Install PMA Button NavBar (Only 1.6.6 and 1.7.0)"
    "Install PMA Button Database Tab (Only 1.6.6 and 1.7.0)"
    "Install MC Paste (Only 1.6.2, 1.6.6 and 1.7.0)"
    "Install Bigger Console (Only 1.6.6 and 1.7.0)"
    "Install Files In Editor (Only 1.6.6 and 1.7.0)"
    "Install PhpMyAdmin"


    "Cancel Installation"
  )

  actions=(
    "Backup"
    "More_Buttons"
    "More_Server_Info"
    "Server_Router_Icons"
    "PMA_Button_NavBar"
    "PMA_Button_Database_Tab"
    "MC_Paste"
    "Bigger_Console"
    "Files_In_Editor"
    "PhpMyAdmin"


    "cancel"
  )

  echo "* Which addon do you want to install?"
  echo

  for i in "${!options[@]}"; do
    echo "[$i] ${options[$i]}"
  done

  echo
  echo -n "* Input 0-$((${#actions[@]} - 1)): "
  read -r action

  [ -z "$action" ] && error "Input is required" && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Invalid option"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && eval "${actions[$action]}"
done
