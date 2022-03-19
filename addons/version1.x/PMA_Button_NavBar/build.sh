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

# Get the latest version before running the script #
get_release() {
curl --silent \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/Ferks-FK/Pterodactyl-AutoAddons/releases/latest |
  grep '"tag_name":' |
  sed -E 's/.*"([^"]+)".*/\1/'
}

# Fixed Variables #
SCRIPT_VERSION="$(get_release)"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"
PMA_VERSION="5.1.3"
MYSQL_DB="phpmyadmin"
MYSQL_USER="pma"
MYSQL_PASSWORD="$(openssl rand -base64 16)"
KEY="$(openssl rand -base64 32)"
CREATE_USER=false
USERNAME=""
MYSQL_ROOT_PASS=false
INFORMATIONS="/var/log/Pterodactyl-AutoAddons-informations"

# Update Variables #
update_variables() {
PMA_ARCH="$PTERO/resources/scripts/routers/ServerRouter.tsx"
PMA_BUTTON_DATABASE_TAB="$PTERO/public/pma_redirect.html"
FILE="$PTERO/public/phpmyadmin/config.inc.php"
SQL="$PTERO/public/phpmyadmin/sql"
CONFIG_FILE="$PTERO/config/app.php"
PANEL_VERSION="$(grep "'version'" "$CONFIG_FILE" | cut -c18-25 | sed "s/[',]//g")"
}

# Visual Functions #
print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

print_warning() {
  echo ""
  echo -e "* ${YELLOW}WARNING${RESET}: $1"
  echo ""
}

print_error() {
  echo ""
  echo -e "* ${RED}ERROR${RESET}: $1"
  echo ""
}

print() {
  echo ""
  echo -e "* ${GREEN}$1${RESET}"
  echo ""
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
RED='\033[0;31m'
RESET="\e[0m"

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

# OS check #
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

# Find where pterodactyl is installed #
find_pterodactyl() {
print "Looking for your pterodactyl installation..."

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

# Verify Compatibility #
compatibility() {
print "Checking if the addon is compatible with your panel..."

sleep 2
if [ "$PANEL_VERSION" == "1.6.6" ] || [ "$PANEL_VERSION" == "1.7.0" ]; then
    print "Compatible Version!"
  else
    print_error "Incompatible Version!"
    exit 1
fi
}

# Install Dependencies #
dependencies() {
print "Installing dependencies..."

if node -v &>/dev/null; then
    print "The dependencies are already installed, skipping this step..."
  else
    case "$OS" in
      debian | ubuntu)
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - && apt-get install -y nodejs
      ;;
      centos)
        [ "$OS_VER_MAJOR" == "7" ] && curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash - && sudo yum install -y nodejs yarn
        [ "$OS_VER_MAJOR" == "8" ] && curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash - && sudo dnf install -y nodejs
      ;;
    esac
fi
}

# Panel Backup #
backup() {
print "Performing security backup..."

if [ -d "$PTERO/PanelBackup[Auto-Addons]" ]; then
    print "There is already a backup, skipping step..."
  else
    cd $PTERO
    if [ -d "$PTERO/node_modules" ]; then
        tar -czvf "PanelBackup[Auto-Addons].tar.gz" --exclude "node_modules" -- * .env
        mkdir -p "$PTERO/PanelBackup[Auto-Addons]"
        mv "$PTERO/PanelBackup[Auto-Addons].tar.gz" "$PTERO/PanelBackup[Auto-Addons]"
      else
        tar -czvf "PanelBackup[Auto-Addons].tar.gz" -- * .env
        mkdir -p "$PTERO/PanelBackup[Auto-Addons]"
        mv "$PTERO/PanelBackup[Auto-Addons].tar.gz" "$PTERO/PanelBackup[Auto-Addons]"
    fi
fi
}

# Download Files #
download_files() {
print "Downloading files..."

mkdir -p $PTERO/public/phpmyadmin
mkdir -p $PTERO/public/phpmyadmin/tmp && chmod 777 $PTERO/public/phpmyadmin/tmp -R
curl -sSLo $PTERO/public/phpmyadmin/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz https://files.phpmyadmin.net/phpMyAdmin/"${PMA_VERSION}"/phpMyAdmin-"${PMA_VERSION}"-all-languages.tar.gz
tar -xzvf $PTERO/public/phpmyadmin/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz -C $PTERO/public/phpmyadmin
cp -rf -- $PTERO/public/phpmyadmin/phpMyAdmin-${PMA_VERSION}-all-languages/* $PTERO/public/phpmyadmin
rm -r $PTERO/public/phpmyadmin/phpMyAdmin-${PMA_VERSION}-all-languages $PTERO/public/phpmyadmin/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz $PTERO/public/phpmyadmin/config.sample.inc.php
curl -sSLo $PTERO/public/phpmyadmin/config.inc.php https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/"${SCRIPT_VERSION}"/addons/version1.x/PMA_Button_NavBar/config.inc.php
mkdir -p $PTERO/temp
curl -sSLo $PTERO/temp/PMA_Button_NavBar.tar.gz https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/"${SCRIPT_VERSION}"/addons/version1.x/PMA_Button_NavBar/PMA_Button_NavBar.tar.gz
tar -xzvf $PTERO/temp/PMA_Button_NavBar.tar.gz -C $PTERO/temp
cp -rf -- $PTERO/temp/PMA_Button_NavBar/* $PTERO
sed -i -e "s@<code>@<a href='/phpmyadmin' target='_blank'>PhpMyAdmin</a>@g" "$PMA_ARCH"
rm -rf $PTERO/temp
}

# Set Permissions #
set_permissions() {
mkdir -p "/etc/phpmyadmin/save"
mkdir -p "/etc/phpmyadmin/upload"
case "$OS" in
debian | ubuntu)
  chown -R www-data.www-data /etc/phpmyadmin
;;
centos)
  chown -R nginx.nginx /etc/phpmyadmin
esac
chmod -R 660 /etc/phpmyadmin
}

# Check that the mysql root user has a password #
check_pass_mysql() {
echo
echo -ne "* [${YELLOW}ATTENTION${RESET}] Does the root user of your system have a password to access mysql? (y/N): "
read -r ASK_MYSQL_PASSWORD
if [[ "$ASK_MYSQL_PASSWORD" =~ [Yy] ]]; then
  password_input MYSQL_PASS "Please enter password now: " "Your password cannot be empty!"
  MYSQL_ROOT_PASS=true
fi
}

# Configure PMA #
configure() {
sed -i -e "s@<key>@$KEY@g" "$FILE"
sed -i -e "s@<password>@$MYSQL_PASSWORD@g" "$FILE"

if [ "$MYSQL_ROOT_PASS" == true ]; then
    mysql -u root -p"$MYSQL_PASS" -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -u root -p"$MYSQL_PASS" -e "CREATE DATABASE ${MYSQL_DB};"
    mysql -u root -p"$MYSQL_PASS" -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1';"
    mysql -u root -p"$MYSQL_PASS" -e "FLUSH PRIVILEGES;"
    mysql -u root -p"$MYSQL_PASS" "$MYSQL_DB" < "$SQL/create_tables.sql"
    mysql -u root -p"$MYSQL_PASS" "$MYSQL_DB" < "$SQL/upgrade_tables_mysql_4_1_2+.sql"
    mysql -u root -p"$MYSQL_PASS" "$MYSQL_DB" < "$SQL/upgrade_tables_4_7_0+.sql"
  else
    mysql -u root -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -u root -e "CREATE DATABASE ${MYSQL_DB};"
    mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    mysql -u root "$MYSQL_DB" < "$SQL/create_tables.sql"
    mysql -u root "$MYSQL_DB" < "$SQL/upgrade_tables_mysql_4_1_2+.sql"
    mysql -u root "$MYSQL_DB" < "$SQL/upgrade_tables_4_7_0+.sql"
fi
sed -i -e "s@<pma>@$MYSQL_DB@g" "$PMA_ARCH"
}

# Check if the user you entered already exists in the database #
create_user_check() {
if [ ! -e "$INFORMATIONS/check_user.txt" ]; then
  if [ "$MYSQL_ROOT_PASS" == true ]; then
      mysql -u root -p"$MYSQL_PASS" -e "SELECT User FROM mysql.user;" >> "$INFORMATIONS/check_user.txt"
    elif [ "$MYSQL_ROOT_PASS" == false ]; then
      mysql -u root -e "SELECT User FROM mysql.user;" >> "$INFORMATIONS/check_user.txt"
  fi
sed -i '1d' "$INFORMATIONS/check_user.txt"
fi
if grep "$USERNAME" "$INFORMATIONS/check_user.txt" &>/dev/null; then
    print_error "${GREEN}$USERNAME${RESET} It already exists in your database, try another one."
  else
    rm -r "$INFORMATIONS/check_user.txt"
    return 1
fi
}

# Ask the user if he wants to create the admin user #
ask_create_user() {
echo
echo -ne "* Do you want to create an administrator user for phpmyadmin access? (y/N): "
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
  echo "$USERNAME" >> "$INFORMATIONS/user.txt"
fi
}

# Create the administrator user for phpmyadmin access #
create_user() {
if [ "$CREATE_USER" == true ]; then
  print "Creating administrator user..."

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

# Check if another conflicting addon is installed #
check_conflict() {
print "Checking if a similar/conflicting addon is already installed..."

sleep 2
if [ -f "$PMA_BUTTON_DATABASE_TAB" ]; then
    print_warning "The addon ${YELLOW}PMA Button Database Tab${RESET} is already installed, aborting..."
    exit 1
fi
}

# Check if it is already installed #
verify_installation() {
  if grep "<a href='/phpmyadmin' target='_blank'>PhpMyAdmin</a>" "$PMA_ARCH" &>/dev/null; then
      print_error "This addon is already installed in your panel, aborting..."
      exit 1
    else
      dependencies
      backup
      download_files
      set_permissions
      check_pass_mysql
      write_informations
      configure
      ask_create_user
      create_user
      production
      bye
  fi
}

# Write the informations to a file for a safety check of the backup script #
write_informations() {
mkdir -p $INFORMATIONS
# Write the password to a file for the backup script to proceed later #
echo "$MYSQL_PASS" >> "$INFORMATIONS/pass.txt"
# Write the result of the variable to a file for the backup script to proceed later #
echo "$MYSQL_ROOT_PASS" >> "$INFORMATIONS/check_variable.txt"
# Just one warning :D #
echo "Don't delete anything inside this folder, it is automatically deleted by the script later, so don't worry about that." >> "$INFORMATIONS/README.txt"
}

# Panel Production #
production() {
print "Producing panel..."
print_warning "This process takes a few minutes, please do not cancel it."

if [ -d "$PTERO/node_modules" ]; then
    yarn --cwd $PTERO build:production
  else
    npm i -g yarn
    yarn --cwd $PTERO install
    yarn --cwd $PTERO build:production
fi
}

bye() {
print_brake 50
echo
echo -e "${GREEN}* The addon ${YELLOW}PMA Button Navbar${GREEN} was successfully installed."
echo -e "* A security backup of your panel has been created."
echo -e "* Thank you for using this script."
echo -e "* Support group: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${RESET}"
echo
print_brake 50
}

# Exec Script #
check_distro
find_pterodactyl
if [ "$PTERO_INSTALL" == true ]; then
    print "Installation of the panel found, continuing the installation..."

    compatibility
    check_conflict
    verify_installation
  elif [ "$PTERO_INSTALL" == false ]; then
    print_warning "The installation of your panel could not be located."
    echo -e "* ${GREEN}EXAMPLE${RESET}: ${YELLOW}/var/www/mypanel${RESET}"
    echo -ne "* Enter the pterodactyl installation directory manually: "
    read -r MANUAL_DIR
    if [ -d "$MANUAL_DIR" ]; then
        print "Directory has been found!"
        PTERO="$MANUAL_DIR"
        echo "$MANUAL_DIR" >> "$INFORMATIONS/custom_directory.txt"
        update_variables
        compatibility
        check_conflict
        verify_installation
      else
        print_error "The directory you entered does not exist."
        find_pterodactyl
    fi
fi