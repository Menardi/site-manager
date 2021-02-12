#!/bin/bash

set -e

if [ "$(whoami)" != "root" ]
  then
    echo This script needs sudo privileges
    exit 2
fi

if [ -z $1 ] || [ -z $2 ]
  then
    echo Usage: $0 domain username
    exit 1
fi

domain=$1
user=$2

if id -u $user; then
  echo User $user already exists
else
  echo Adding user $user
  adduser $user
fi

echo Adding $user to sftponly group
usermod -g sftponly $user

echo Removing shell access for $user
usermod -s /bin/false $user

echo Changing ownership of /home/$user to root
chown root:root /home/$user

echo Creating /home/$user/www/$domain
mkdir -p /home/$user/www/$domain

echo Changing ownership of /home/$user/www/ to $user and group to www-data
chown $user:www-data /home/$user/www

echo Creating server directories
mkdir -p /srv/www/$domain/public_html
mkdir -p /srv/www/$domain/logs

echo Binding /home/$user/www to /srv/www/$domain/public_html
mountcommand="mount --bind /home/$user/www/$domain /srv/www/$domain/public_html"
eval $mountcommand

# Newer versions of Ubuntu don't come with a default rc.local file
if [ ! -f /etc/rc.local ]; then
  cp templates/rclocal /etc/rc.local
  chown root.root /etc/rc.local
  chmod 755 /etc/rc.local
fi

sed -i "s@exit 0@$mountcommand \nexit 0@g" /etc/rc.local

echo Setting up site for nginx
cp templates/nginx-basic /etc/nginx/sites-available/$domain
sed -i "s@_SITEURL_@$domain@g" /etc/nginx/sites-available/$domain

echo You will need to run the enable script to complete this set up
