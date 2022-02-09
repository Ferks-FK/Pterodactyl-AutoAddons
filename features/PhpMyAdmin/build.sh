#!/bin/bash
#shellcheck source=/dev/null

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

#### Fixed Variables ####

SCRIPT_VERSION="1.0-dev"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"

#### Functions for visual styles ####

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
red='\033[0;31m'
reset="\e[0m"

print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

print_warning() {
  echo -e "* ${YELLOW}WARNING${reset}: $1"
  echo ""
}

print_error() {
  echo ""
  echo -e "* ${red}ERROR${reset}: $1"
  echo ""
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

password_input() {
  local __resultvar=$1
  local result=''
  local default="$4"

  while [ -z "$result" ]; do
    echo -n "* ${2}"
    while IFS= read -r -s -n1 char; do
      [[ -z $char ]] && {
        printf '\n'
        break
      }
      if [[ $char == $'\x7f' ]]; then
        if [ -n "$result" ]; then
          [[ -n $result ]] && result=${result%?}
          printf '\b \b'
        fi
      else
        result+=$char
        printf '*'
      fi
    done
    [ -z "$result" ] && [ -n "$default" ] && result="$default"
    [ -z "$result" ] && print_error "${3}"
  done

  eval "$__resultvar="'$result'""
}


#### OS check ####

check_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "$ID" | awk '{print tolower($0)}')
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si | awk '{print tolower($0)}')
    OS_VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID" | awk '{print tolower($0)}')
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

  OS=$(echo "$OS" | awk '{print tolower($0)}')
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}

main() {
# Make sure phpmyadmin is already installed #
if [ -d "/var/www/phpmyadmin" ]; then
  print_warning "PhpMyAdmin is already installed, canceling installation..."
  exit 1
fi

# Exec Check Distro #
check_distro

# Ask which web server the user wants to use #
echo -e -n "* Which web server do you want to use (${YELLOW}Nginx${reset}): "
read -r WEB_SERVER
[ -z "$WEB_SERVER" ] && WEB_SERVER="nginx"

# Ask which user to log into the panel #
echo -e -n "* User to login to your panel (${YELLOW}phpmyadmin${reset}): "
read -r MYSQL_USER
[ -z "$MYSQL_USER" ] && MYSQL_USER="phpmyadmin"

# Ask the user password to log into the panel #
MYSQL_PASSWORD=""
password_input MYSQL_PASSWORD "Password for login to your panel: " "The password cannot be empty!"

}

main
