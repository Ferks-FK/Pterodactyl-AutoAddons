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

#### Variables ####
SCRIPT_VERSION="v1.7"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"
PTERO="/var/www/pterodactyl"
PMA_VERSION="5.1.1"
PMA_ARCH="$PTERO/public/pma_redirect.html"
PMA_NAME="phpmyadmin"


print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

print_warning() {
  COLOR_YELLOW='\033[1;33m'
  COLOR_NC='\033[0m'
  echo -e "* ${COLOR_YELLOW}WARNING${COLOR_NC}: $1"
  echo ""
}


hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}


#### Colors ####

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
red='\033[0;31m'
reset="\e[0m"


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

#### Verify Compatibility ####

compatibility() {
echo
print_brake 57
echo -e "* ${GREEN}Checking if the addon is compatible with your panel...${reset}"
print_brake 57
echo
sleep 2
DIR="$PTERO/config/app.php"
VERSION="1.6.6"
if [ -f "$DIR" ]; then
  CODE=$(cat "$DIR" | grep -n ^ | grep ^12: | cut -d: -f2 | cut -c18-23 | sed "s/'//g")
    if [ "$VERSION" == "$CODE" ]; then
        echo
        print_brake 23
        echo -e "* ${GREEN}Compatible Version!${reset}"
        print_brake 23
        echo
      else
        echo
        print_brake 24
        echo -e "* ${red}Incompatible Version!${reset}"
        print_brake 24
        echo
        exit 1
    fi
  else
    echo
    print_brake 26
    echo -e "* ${red}The file doesn't exist!${reset}"
    print_brake 26
    echo
    exit 1
fi
}


#### Install Dependencies ####

dependencies() {
echo
print_brake 30
echo -e "* ${GREEN}Installing dependencies...${reset}"
print_brake 30
echo
case "$OS" in
debian | ubuntu)
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - && apt-get install -y nodejs && sudo apt-get install -y zip && apt-get install -y curl dirmngr apt-transport-https lsb-release ca-certificates
;;
esac

if [ "$OS_VER_MAJOR" == "7" ]; then
curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash - && sudo yum install -y nodejs yarn && sudo yum install -y zip && yum install -y install -y curl dirmngr apt-transport-https lsb-release ca-certificates
fi

if [ "$OS_VER_MAJOR" == "8" ]; then
curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash - && sudo dnf install -y nodejs && sudo dnf install -y zip && dnf install -y install -y curl dirmngr apt-transport-https lsb-release ca-certificates
fi
}


#### Panel Backup ####

backup() {
echo
print_brake 32
echo -e "* ${GREEN}Performing security backup...${reset}"
print_brake 32
  if [ -f "$PTERO/PanelBackup/PanelBackup.zip" ]; then
    echo
    print_brake 45
    echo -e "* ${GREEN}There is already a backup, skipping step...${reset}"
    print_brake 45
    echo
  else
    cd "$PTERO"
    if [ -d "$PTERO/node_modules" ]; then
      rm -r "$PTERO/node_modules"
    fi
    mkdir -p PanelBackup
    zip -r PanelBackup.zip -- * .env
    mv PanelBackup.zip PanelBackup
fi
}


#### Download Files ####

download_files() {
print_brake 25
echo -e "* ${GREEN}Downloading files...${reset}"
print_brake 25
cd "$PTERO/public"
mkdir -p "$PMA_NAME"
cd "$PMA_NAME"
curl -sSLo phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz https://files.phpmyadmin.net/phpMyAdmin/"${PMA_VERSION}"/phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
tar -xzvf phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
cd phpMyAdmin-"${PMA_VERSION}"-all-languages
mv -- * "$PTERO/public/$PMA_NAME"
cd "$PTERO/public/$PMA_NAME"
rm -r phpMyAdmin-"${PMA_VERSION}"-all-languages phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
rm -r config.sample.inc.php
curl -sSLo config.inc.php https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/PMA_Button_Database_Tab/config.inc.php
cd "$PTERO"
mkdir -p temp
cd temp
curl -sSLo PMA_Button_Database_Tab.tar.gz https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/addons/version1.x/PMA_Button_Database_Tab/PMA_Button_Database_Tab.tar.gz
tar -xzvf PMA_Button_Database_Tab.tar.gz
cd PMA_Button_Database_Tab/public
mv -f pma_redirect.html "$PTERO/public"
cd "$PTERO/temp/PMA_Button_Database_Tab/resources/scripts/components/server/databases"
mv -f DatabaseRow.tsx "$PTERO/resources/scripts/components/server/databases"
cd "$PTERO"
rm -r temp
}


#### Set Permissions ####

set_permissions() {
cd /etc
mkdir -p phpmyadmin
cd phpmyadmin
mkdir save upload
case "$OS" in
debian | ubuntu)
  chown -R www-data.www-data /etc/phpmyadmin
;;
centos)
  chown -R nginx.nginx /etc/phpmyadmin
esac
chmod -R 660 /etc/phpmyadmin
}

#### Configure PMA ####

configure() {
FILE="$PTERO/public/$PMA_NAME/config.inc.php"
SQL="$PTERO/public/$PMA_NAME/sql"
MYSQL_DB="phpmyadmin"
MYSQL_USER="pma"
MYSQL_PASSWORD="$(openssl rand -base64 16)"
if [ -f "$FILE" ]; then
  KEY="$(openssl rand -base64 32)"
  sed -i -e "s@<key>@$KEY@g" "$FILE"
  sed -i -e "s@<password>@$MYSQL_PASSWORD@g" "$FILE"
fi
case "$OS" in
debian | ubuntu)

  mysql -u root -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
  mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"
  mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1';"
  mysql -u root -e "FLUSH PRIVILEGES;"
  cd "$SQL"
  mysql -u root "$MYSQL_DB" < create_tables.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_mysql_4_1_2+.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_4_7_0+.sql
;;
centos)
  [ "$OS_VER_MAJOR" == "7" ] && mariadb-secure-installation
  [ "$OS_VER_MAJOR" == "8" ] && mysql_secure_installation

  mysql -u root -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
  mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"
  mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1';"
  mysql -u root -e "FLUSH PRIVILEGES;"
  cd "$SQL"
  mysql -u root "$MYSQL_DB" < create_tables.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_mysql_4_1_2+.sql
  mysql -u root "$MYSQL_DB" < upgrade_tables_4_7_0+.sql
;;
esac
sed -i -e "s@<pma>@$PMA_NAME@g" "$PMA_ARCH"
#### Continue Script ####
production
bye
}

#### Check if it is already installed ####

verify_installation() {
  if grep '<a href="/pma" target="_blank">PhpMyAdmin</a>' "$PMA_ARCH" &>/dev/null; then
      print_brake 61
      echo -e "* ${red}This addon is already installed in your panel, aborting...${reset}"
      print_brake 61
      exit 1
    else
      dependencies
      backup
      download_files
      set_permissions
      configure
  fi
}

#### Panel Production ####

production() {
echo
print_brake 25
echo -e "* ${GREEN}Producing panel...${reset}"
print_brake 25
if [ -d "$PTERO/node_modules" ]; then
    cd "$PTERO"
    yarn build:production
  else
    npm i -g yarn
    cd "$PTERO"
    yarn install
    yarn build:production
fi
}


bye() {
print_brake 50
echo
echo -e "* ${GREEN}The addon ${YELLOW}PMA Button Database Tab${GREEN} was successfully installed."
echo -e "* A security backup of your panel has been created."
echo -e "* Thank you for using this script."
echo -e "* Support group: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${reset}"
echo
print_brake 50
}


#### Exec Script ####
check_distro
compatibility
verify_installation