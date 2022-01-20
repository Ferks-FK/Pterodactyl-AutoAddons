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

SCRIPT_VERSION="v2.8"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"
PMA_VERSION="5.1.1"
MYSQL_DB="phpmyadmin"
MYSQL_USER="pma"
MYSQL_PASSWORD="$(openssl rand -base64 16)"
KEY="$(openssl rand -base64 32)"
CREATE_USER=false
USERNAME=""
PASSWORD=""
MYSQL_ROOT_PASS=false
MYSQL_PASS=""

#### Update Variables ####

update_variables() {
PMA_ARCH="$PTERO/public/pma_redirect.html"
PMA_BUTTON_NAVBAR="$PTERO/resources/scripts/routers/ServerRouter.tsx"
FILE="$PTERO/public/$MYSQL_DB/config.inc.php"
SQL="$PTERO/public/$MYSQL_DB/sql"
}


print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

print_warning() {
  YELLOW="\033[1;33m"
  reset="\e[0m"
  echo -e "* ${YELLOW}WARNING${reset}: $1"
  echo ""
}

print_error() {
  red='\033[0;31m'
  reset="\e[0m"

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

#### Find where pterodactyl is installed ####

find_pterodactyl() {
echo
print_brake 47
echo -e "* ${GREEN}Looking for your pterodactyl installation...${reset}"
print_brake 47
echo
sleep 2
if [ -d "/var/www/pterodactyl" ]; then
    PTERO_INSTALL=true
    PTERO="/var/www/pterodactyl"
  elif [ -d "/var/www/panel" ]; then
    PTERO_INSTALL=true
    PTERO="/var/www/panel"
  elif [ -d "/var/www/ptero" ]; then
    PTERO_INSTALL=true
    PTERO="/var/www/ptero"
  else
    PTERO_INSTALL=false
fi
# Update the variables after detection of the pterodactyl installation #
update_variables
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
VERSION="1.7.0"
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
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash - && apt-get install -y nodejs && apt-get install -y curl dirmngr apt-transport-https lsb-release ca-certificates
;;
centos)
[ "$OS_VER_MAJOR" == "7" ] && curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash - && sudo yum install -y nodejs yarn && yum install -y install -y curl dirmngr apt-transport-https lsb-release ca-certificates
[ "$OS_VER_MAJOR" == "8" ] && curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash - && sudo dnf install -y nodejs && dnf install -y curl dirmngr ca-certificates
;;
esac
}


#### Panel Backup ####

backup() {
echo
print_brake 32
echo -e "* ${GREEN}Performing security backup...${reset}"
print_brake 32
  if [ -d "$PTERO/PanelBackup[Auto-Addons]" ]; then
    echo
    print_brake 45
    echo -e "* ${GREEN}There is already a backup, skipping step...${reset}"
    print_brake 45
    echo
  else
    cd "$PTERO"
    if [ -d "$PTERO/node_modules" ]; then
        tar -czvf "PanelBackup[Auto-Addons].tar.gz" --exclude "node_modules" -- * .env
        mkdir -p "PanelBackup[Auto-Addons]"
        mv "PanelBackup[Auto-Addons].tar.gz" "PanelBackup[Auto-Addons]"
      else
        tar -czvf "PanelBackup[Auto-Addons].tar.gz" -- * .env
        mkdir -p "PanelBackup[Auto-Addons]"
        mv "PanelBackup[Auto-Addons].tar.gz" "PanelBackup[Auto-Addons]"
    fi
fi
}


#### Download Files ####

download_files() {
echo
print_brake 25
echo -e "* ${GREEN}Downloading files...${reset}"
print_brake 25
cd "$PTERO/public"
mkdir -p "$MYSQL_DB"
cd "$MYSQL_DB"
curl -sSLo phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz https://files.phpmyadmin.net/phpMyAdmin/"${PMA_VERSION}"/phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
tar -xzvf phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
cd phpMyAdmin-"${PMA_VERSION}"-all-languages
mv -- * "$PTERO/public/$MYSQL_DB"
cd "$PTERO/public/$MYSQL_DB"
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
;;
esac
chmod -R 660 /etc/phpmyadmin
}

#### Check that the mysql root user has a password ####

check_pass_mysql() {
echo
echo -e -n "* [${YELLOW}ATTENTION${reset}] Does the root user of your system have a password to access mysql? (y/N): "
read -r ASK_MYSQL_PASSWORD
if [[ "$ASK_MYSQL_PASSWORD" =~ [Yy] ]]; then
  password_input MYSQL_PASS "Please enter password now: " "Your password cannot be empty!"
  MYSQL_ROOT_PASS=true
  # Write the password to a file for the backup script to proceed later #
  echo "$MYSQL_PASS" >> "$PTERO/pass.txt"
fi
}

#### Configure PMA ####

configure() {
if [ -f "$FILE" ]; then
  sed -i -e "s@<key>@$KEY@g" "$FILE"
  sed -i -e "s@<password>@$MYSQL_PASSWORD@g" "$FILE"
fi
if [ "$MYSQL_ROOT_PASS" == true ]; then
    mysql -u root -p"$MYSQL_PASS" -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -u root -p"$MYSQL_PASS" -e "CREATE DATABASE ${MYSQL_DB};"
    mysql -u root -p"$MYSQL_PASS" -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1';"
    mysql -u root -p"$MYSQL_PASS" -e "FLUSH PRIVILEGES;"
    cd "$SQL"
    mysql -u root -p"$MYSQL_PASS" "$MYSQL_DB" < create_tables.sql
    mysql -u root -p"$MYSQL_PASS" "$MYSQL_DB" < upgrade_tables_mysql_4_1_2+.sql
    mysql -u root -p"$MYSQL_PASS" "$MYSQL_DB" < upgrade_tables_4_7_0+.sql
  elif [ "$MYSQL_ROOT_PASS" == false ]; then
    mysql -u root -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"
    mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    cd "$SQL"
    mysql -u root "$MYSQL_DB" < create_tables.sql
    mysql -u root "$MYSQL_DB" < upgrade_tables_mysql_4_1_2+.sql
    mysql -u root "$MYSQL_DB" < upgrade_tables_4_7_0+.sql
fi
sed -i -e "s@<pma>@$MYSQL_DB@g" "$PMA_ARCH"
# Write the result of the variable to a file for the backup script to proceed later #
echo "$MYSQL_ROOT_PASS" >> "$PTERO/check_variable.txt"
}

#### Check if the user you entered already exists in the database ####

create_user_check() {
if [ ! -e "$PTERO/check_user.txt" ]; then
  if [ "$MYSQL_ROOT_PASS" == true ]; then
      mysql -u root -p"$MYSQL_PASS" -e "SELECT User FROM mysql.user;" >> "$PTERO/check_user.txt"
    elif [ "$MYSQL_ROOT_PASS" == false ]; then
      mysql -u root -e "SELECT User FROM mysql.user;" >> "$PTERO/check_user.txt"
  fi
sed -i '1d' "$PTERO/check_user.txt"
fi
if grep "$USERNAME" "$PTERO/check_user.txt" &>/dev/null; then
    echo
    echo -e "* ${GREEN}$USERNAME ${red}It already exists in your database, try another one.${reset}"
    echo
  else
    rm -r "$PTERO/check_user.txt"
    return 1
fi
}

#### Ask the user if he wants to create the admin user ####

ask_create_user() {
echo
echo -e -n "* Do you want to create an administrator user for phpmyadmin access? (y/N): "
read -r ASK_CREATE_USER
if [[ "$ASK_CREATE_USER" =~ [Yy] ]]; then
  CREATE_USER=true
  while [ -z "$USERNAME" ] || create_user_check; do
    echo -e -n "* Username to be created: "
    read -r USERNAME
    [ -z "$USERNAME" ] && print_error "Your user cannot be empty!"
  done
  password_input PASSWORD "The password for access: " "Your password cannot be empty!"
  # Write the username to a file for the backup script to proceed later #
  echo "$USERNAME" >> "$PTERO/user.txt"
fi
}

#### Create the administrator user for phpmyadmin access ####

create_user() {
if [ "$CREATE_USER" == true ]; then
  echo
  print_brake 33
  echo -e "* ${GREEN}Creating administrator user...${reset}"
  print_brake 33
  echo
  if [ "$MYSQL_ROOT_PASS" == true ]; then
      mysql -u root -p"$MYSQL_PASS" -e "CREATE USER '${USERNAME}'@'%' IDENTIFIED BY '${PASSWORD}';"
      mysql -u root -p"$MYSQL_PASS" -e "GRANT ALL PRIVILEGES ON *.* TO '${USERNAME}'@'%';"
      mysql -u root -p"$MYSQL_PASS" -e "FLUSH PRIVILEGES;"
    elif [ "$MYSQL_ROOT_PASS" == false ]; then
      mysql -u root -e "CREATE USER '${USERNAME}'@'%' IDENTIFIED BY '${PASSWORD}';"
      mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${USERNAME}'@'%';"
      mysql -u root -e "FLUSH PRIVILEGES;"
  fi
  elif [ "$CREATE_USER" == false ]; then
    echo
    print_warning "You have chosen not to set up a user for phpmyadmin, please create one manually for access, or use one created by the panel (servers)."
    sleep 5
fi
}

#### Check if another conflicting addon is installed ####

check_conflict() {
echo
print_brake 66
echo -e "* ${GREEN}Checking if a similar/conflicting addon is already installed...${reset}"
print_brake 66
echo
sleep 2
if grep "<a href='/$MYSQL_DB' target='_blank'>PhpMyAdmin</a>" "$PMA_BUTTON_NAVBAR" &>/dev/null; then
    echo
    print_brake 70
    echo -e "* ${red}The addon ${YELLOW}PMA Button Navbar ${red}is already installed, aborting...${reset}"
    print_brake 70
    echo
    exit 1
fi
}

#### Check if it is already installed ####

verify_installation() {
  if [ -f "$PMA_ARCH" ]; then
      print_brake 61
      echo -e "* ${red}This addon is already installed in your panel, aborting...${reset}"
      print_brake 61
      exit 1
    else
      dependencies
      backup
      download_files
      set_permissions
      check_pass_mysql
      configure
      ask_create_user
      create_user
      production
      bye
  fi
}

#### Panel Production ####

production() {
echo
print_brake 25
echo -e "* ${GREEN}Producing panel...${reset}"
print_brake 25
echo
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
echo -e "${GREEN}* The addon ${YELLOW}PMA Button Database Tab${GREEN} was successfully installed."
echo -e "* A security backup of your panel has been created."
echo -e "* Thank you for using this script."
echo -e "* Support group: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${reset}"
echo
print_brake 50
}


#### Exec Script ####
check_distro
find_pterodactyl
if [ "$PTERO_INSTALL" == true ]; then
    echo
    print_brake 66
    echo -e "* ${GREEN}Installation of the panel found, continuing the installation...${reset}"
    print_brake 66
    echo
    compatibility
    check_conflict
    verify_installation
  elif [ "$PTERO_INSTALL" == false ]; then
    echo
    print_brake 66
    echo -e "* ${red}The installation of your panel could not be located, aborting...${reset}"
    print_brake 66
    echo
    exit 1
fi