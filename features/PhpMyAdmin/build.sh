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

SCRIPT_VERSION="PhpMyAdmin-Installer"
PHPMYADMIN_VERSION="5.1.2"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"


#### Github URL's ####

GITHUB="https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/$SCRIPT_VERSION"


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
  echo ""
  echo -e "* ${YELLOW}WARNING${reset}: $1"
  echo ""
}

print_error() {
  echo ""
  echo -e "* ${red}ERROR${reset}: $1"
  echo ""
}

print_success() {
  echo ""
  echo -e "* ${GREEN}SUCCESS${reset}: $1"
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

# regex for email
regex="^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$"

valid_email() {
  [[ $1 =~ ${regex} ]]
}

email_input() {
  local __resultvar=$1
  local result=''

  while ! valid_email "$result"; do
    echo -n "* ${2}"
    read -r result

    valid_email "$result" || print_error "${3}"
  done

  eval "$__resultvar="'$result'""
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

# Ask which web server the user wants to use #

web_server_menu() {
WEB_SERVER="nginx"
echo -ne "
* CHOOSE YOUR WEB-SERVER
1) Nginx (${YELLOW}Default${reset})
2) Apache2
"
read -r WEB_SERVER
case "$WEB_SERVER" in
  "")
    WEB_SERVER="nginx"
    ;;
  1)
    WEB_SERVER="nginx"
    ;;
  2)
    WEB_SERVER="apache2"
    ;;
  *)
    print_error "This option does not exist!"
    web_server_menu
    ;;
  esac
}

ask_ssl() {
CONFIGURE_SSL=false
email=""
echo -n "* Do you want to generate SSL certificate for your domain? (y/N): "
read -r ASK_SSL
if [[ "$ASK_SSL" =~ [Yy] ]]; then
  CONFIGURE_SSL=true
  # Ask the email only if the SSL is true #
  email_input email "Enter an email address that will be used for the creation of the SSL certificate: " "The email address must not be invalid or empty"
  # Ask if you want to configure UFW only if SSL is true #
  ask_ufw
fi
}

ask_ufw() {
CONFIGURE_UFW=false
CONFIGURE_UFW_CMD=false
print_warning "If you want phpmyadmin to be accessed externally, allow the script to configure the firewall.
Otherwise you may have problems accessing it outside your local network."
echo -n "* Would you like to open the ports on the firewall for external access? (y/N): "
read -r ASK_UFW
if [[ "$ASK_UFW" =~ [Yy] ]]; then
  case "$OS" in
    debian | ubuntu)
    CONFIGURE_UFW=true
    ;;
    centos)
    CONFIGURE_UFW_CMD=true
  esac
fi
}

check_fqdn() {
echo -n "* Checking FQDN..."
echo
IP="$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has" | awk '{print $4}')"
CHECK_DNS="$(dig +short @8.8.8.8 "$FQDN" | tail -n1)"
if [[ "$IP" != "$CHECK_DNS" ]]; then
    print_error "Your FQDN (${YELLOW}$FQDN${reset}) is not pointing to the public IP (${YELLOW}$IP${reset}), please make sure your domain is set correctly."
    echo -n "* Would you like to check again? (y/N): "
    read -r CHECK_DNS_AGAIN
    [[ "$CHECK_DNS_AGAIN" =~ [Yy] ]] && check_fqdn
    [[ "$CHECK_DNS_AGAIN" = * ]] && print_error "Installation aborted!" && exit 1
  else
    print_success "DNS successfully verified!"
fi
}

configure_ufw() {
apt-get install -y ufw

echo "* Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"

ufw allow ssh >/dev/null
ufw allow http >/dev/null
ufw allow https >/dev/null

ufw --force enable
ufw --force reload
ufw status numbered | sed '/v6/d'
}

configure_ufw_cmd() {
[ "$OS_VER_MAJOR" == "7" ] && yum -y -q install firewalld >/dev/null
[ "$OS_VER_MAJOR" == "8" ] && dnf -y -q install firewalld >/dev/null

systemctl --now enable firewalld >/dev/null

echo "* Opening port 22 (SSH), 80 (HTTP) and 443 (HTTPS)"

firewall-cmd --add-service=http --permanent -q
firewall-cmd --add-service=https --permanent -q
firewall-cmd --add-service=ssh --permanent -q
firewall-cmd --reload -q
}

deps_ubuntu() {
echo "* Installing dependencies for Ubuntu 18/20..."

apt-get install -y software-properties-common curl apt-transport-https ca-certificates gnupg

[ "$OS_VER_MAJOR" == "18" ] && add-apt-repository universe

LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

apt-get update -y && apt-get upgrade -y

apt-get install -y php8.0 php8.0-{mbstring,fpm,cli,zip,gd,uploadprogress,xml,curl} "$WEB_SERVER" mariadb-server tar zip unzip
}

deps_debian() {
echo "* Installing dependencies for Debian 9/10/11..."

apt-get install -y dirmngr

apt-get install -y ca-certificates apt-transport-https lsb-release
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

[ "$OS_VER_MAJOR" == "9" ] && curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

apt-get update -y && apt-get upgrade -y

apt-get install -y php8.0 php8.0-{mbstring,fpm,cli,zip,gd,uploadprogress,xml,curl} "$WEB_SERVER" mariadb-server tar zip unzip
}

deps_centos() {
if [ "$OS_VER_MAJOR" == "7" ]; then
    echo "* Installing dependencies for CentOS 7.."
    yum install -y policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setroubleshoot-server setools setools-console mcstrans

    yum install -y epel-release http://rpms.remirepo.net/enterprise/remi-release-7.rpm
    yum install -y yum-utils
    yum-config-manager -y --disable remi-php54
    yum-config-manager -y --enable remi-php80
    yum update -y

    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

    [ "$WEB_SERVER" == "nginx" ] && yum install -y epel-release && yum install -y nginx
    [ "$WEB_SERVER" == "apache2" ] && yum install -y httpd

    yum install -y php php-mbstring php-fpm php-cli php-zip php-gd php-uploadprogress php-xml php-curl mariadb-server tar zip unzip
  elif [ "$OS_VER_MAJOR" == "8" ]; then
    echo "* Installing dependencies for CentOS 8.."

    dnf install -y policycoreutils selinux-policy selinux-policy-targeted setroubleshoot-server setools setools-console mcstrans

    dnf install -y epel-release http://rpms.remirepo.net/enterprise/remi-release-8.rpm
    dnf module enable -y php:remi-8.0
    dnf upgrade -y

    dnf install -y php php php-mbstring php-fpm php-cli php-zip php-gd php-uploadprogress php-xml php-curl

    dnf install -y mariadb mariadb-server

    dnf install -y "$WEB_SERVER" tar zip unzip
fi
}

download_files() {
echo "* Downloading files from phpmyadmin..."

mkdir -p "/var/www/phpmyadmin"
curl -sSLo phpMyAdmin-"${PHPMYADMIN_VERSION}"-all-languages.tar.gz https://files.phpmyadmin.net/phpMyAdmin/"${PHPMYADMIN_VERSION}"/phpMyAdmin-"${PHPMYADMIN_VERSION}"-all-languages.tar.gz
tar -xzvf phpMyAdmin-"${PHPMYADMIN_VERSION}"-all-languages.tar.gz
cd phpMyAdmin-"${PHPMYADMIN_VERSION}"-all-languages
mv -- * "/var/www/phpmyadmin"
cd "/var/www/phpmyadmin"
rm -r phpMyAdmin-"${PHPMYADMIN_VERSION}"-all-languages phpMyAdmin-"${PHPMYADMIN_VERSION}"-all-languages.tar.gz config.sample.inc.php
curl -sSLo config.inc.php https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoAddons/${SCRIPT_VERSION}/features/configs/config.inc.php
}

configure_phpmyadmin() {
echo "* Configuring phpmyadmin..."

PHPMYADMIN_PASSWORD="$(openssl rand -base64 32)"
KEY="$(openssl rand -base64 32)"

mysql -u root -e "CREATE USER 'pma'@'127.0.0.1' IDENTIFIED BY '${PHPMYADMIN_PASSWORD}';"
mysql -u root -e "CREATE DATABASE phpmyadmin;"
mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'127.0.0.1';"
mysql -u root -e "FLUSH PRIVILEGES;"
cd "/var/www/phpmyadmin/sql"
mysql -u root "phpmyadmin" < create_tables.sql
mysql -u root "phpmyadmin" < upgrade_tables_mysql_4_1_2+.sql
mysql -u root "phpmyadmin" < upgrade_tables_4_7_0+.sql

sed -i -e "s@<key>@$KEY@g" "/var/www/phpmyadmin/config.inc.php"
sed -i -e "s@<password>@$PHPMYADMIN_PASSWORD@g" "/var/www/phpmyadmin/config.inc.php"

#curl -o /etc/php-fpm.d/www-phpmyadmin.conf $GITHUB/features/configs/www-phpmyadmin.conf
}

set_permissions() {
cd /etc
mkdir -p phpmyadmin
cd phpmyadmin
mkdir save upload
case "$OS" in
  debian | ubuntu)
  [ "$WEB_SERVER" == "nginx" ] && chown -R www-data:www-data /var/www/phpmyadmin
  [ "$WEB_SERVER" == "apache2" ] && chown -R www-data:www-data /var/www/phpmyadmin
  ;;
  centos)
  [ "$WEB_SERVER" == "nginx" ] && chown -R nginx:nginx /var/www/phpmyadmin
  [ "$WEB_SERVER" == "apache2" ] && chown -R apache:apache /var/www/phpmyadmin

  ;;
esac
chmod -R 660 /etc/phpmyadmin
}

create_user_login() {
echo "* Creating user access for the panel..."

mysql -u root -e "CREATE USER '${USERNAME}'@'%' IDENTIFIED BY '${PASSWORD}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${USERNAME}'@'%';"
mysql -u root -e "FLUSH PRIVILEGES;"
}

configure_web_server() {
echo "* Configuring ${WEB_SERVER}..."

if [ "$WEB_SERVER" == "nginx" ]; then
    [ "$CONFIGURE_SSL" == true ] && WEB_FILE="nginx_ssl.conf"
    [ "$CONFIGURE_SSL" == false ] && WEB_FILE="nginx.conf"
  elif [ "$WEB_SERVER" == "apache2" ]; then
    [ "$CONFIGURE_SSL" == true ] && WEB_FILE="apache_ssl.conf"
    [ "$CONFIGURE_SSL" == false ] && WEB_FILE="apache.conf"
fi

case "$OS" in
  debian | ubuntu)
    if [ "$WEB_SERVER" == "nginx" ]; then
        rm /etc/nginx/sites-enabled/default

        curl -o /etc/nginx/sites-available/phpmyadmin.conf $GITHUB/features/configs/$WEB_FILE

        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-available/phpmyadmin.conf

        sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/sites-available/phpmyadmin.conf

        [ "$OS" == "debian" ] && [ "$OS_VER_MAJOR" == "9" ] && sed -i 's/ TLSv1.3//' /etc/nginx/sites-available/phpmyadmin.conf

        ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
      elif [ "$WEB_SERVER" == "apache2" ]; then
        rm /etc/apache/sites-enabled/000-default.conf

        curl -o /etc/apache2/sites-available/phpmyadmin.conf $GITHUB/features/configs/$WEB_FILE

        sed -i -e "s@<domain>@${FQDN}@g" /etc/apache2/sites-available/phpmyadmin.conf

        ln -s /etc/apache2/sites-available/phpmyadmin.conf /etc/apache2/sites-enabled/phpmyadmin.conf
    fi
  ;;
  centos)
    if [ "$WEB_SERVER" == "nginx" ]; then
        rm -rf /etc/nginx/conf.d/default

        curl -o /etc/nginx/conf.d/phpmyadmin.conf $GITHUB/features/configs/$WEB_FILE

        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/conf.d/phpmyadmin.conf

        sed -i -e "s@<php_socket>@${PHP_SOCKET}@g" /etc/nginx/conf.d/phpmyadmin.conf
      elif [ "$WEB_SERVER" == "apache2" ]; then
        rm -rf /usr/share/httpd
        rm -rf /etc/httpd/conf.d/*
        mkdir -p /etc/httpd/sites-available
        mkdir -p /etc/httpd/sites-enabled

        curl -o /etc/httpd/sites-available/phpmyadmin.conf $GITHUB/features/configs/$WEB_FILE

        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-available/phpmyadmin.conf

        ln -s /etc/httpd/sites-available/phpmyadmin.conf /etc/httpd/sites-enabled/phpmyadmin;.conf

    fi
  ;;
esac
}

install_phpmyadmin() {
echo "* Starting installation, this may take a few minutes, please wait."
sleep 3

case "$OS" in
  debian | ubuntu)
  apt-get update -y && apt-get upgrade -y

  [ "$CONFIGURE_UFW" == true ] && configure_ufw

  [ "$OS" == "ubuntu" ] && deps_ubuntu
  [ "$OS" == "debian" ] && deps_debian
  ;;

  centos)
  [ "$CONFIGURE_UFW_CMD" == true ] && configure_ufw_cmd

  deps_centos
  ;;
esac

download_files
configure_phpmyadmin
set_permissions
create_user_login
configure_web_server
}

main() {
# Make sure phpmyadmin is already installed #
if [ -d "/var/www/phpmyadmin" ]; then
  print_warning "PhpMyAdmin is already installed, canceling installation..."
  exit 1
fi

# Exec Check Distro #
check_distro

# Ask which user to log into the panel #
echo -e -n "* User to login to your panel (${YELLOW}phpmyadmin${reset}): "
read -r USERNAME
[ -z "$USERNAME" ] && USERNAME="phpmyadmin"

# Ask the user password to log into the panel #
password_input PASSWORD "Password for login to your panel: " "The password cannot be empty!"

# Set FQDN for phpmyadmin #
FQDN=""
while [ -z "$FQDN" ]; do
  echo -ne "* Set the FQDN for phpmyadmin (${YELLOW}mysql.example.com${reset}): "
  read -r FQDN
  [ -z "$FQDN" ] && print_error "FQDN cannot be empty"
done

# Verify the FQDN #
check_fqdn

# Run the web-server chooser menu #
web_server_menu

# Ask whether you want SSL or not #
ask_ssl

# Summary #
echo
print_brake 65
echo
echo -e "* PhpMyAdmin Version (${YELLOW}$PHPMYADMIN_VERSION${reset}) with web-server (${YELLOW}$WEB_SERVER${reset}) in OS (${YELLOW}$OS${reset})"
echo -e "* PhpMyAdmin Login: $USERNAME"
echo -e "* PhpMyAdmin Password: (censored)"
echo -e "* Email for ssl certificate: $email"
echo -e "* Hostname/FQDN: $FQDN"
echo -e "* Configure Firewall: $CONFIGURE_UFW"
echo -e "* Configure SSL: $CONFIGURE_SSL"
echo
print_brake 65
echo

# Confirm all the choices #
echo -n "* Initial settings complete, do you want to continue to the installation? (y/N): "
read -r CONTINUE_INSTALL
[[ "$CONTINUE_INSTALL" =~ [Yy] ]] && install_phpmyadmin
[[ "$CONTINUE_INSTALL" = * ]] && print_error "Installation aborted!" && exit 1
}

main
