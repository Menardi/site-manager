#!/bin/bash

set -e

if [ "$(whoami)" != "root" ]
  then
    echo "This script needs sudo privileges"
    exit 2
fi

if [ -z $1 ]
  then
    echo "Usage: $0 domain [username]"
    exit 1
fi

domain=$1
user=$2

echo "Creating server directories"

mkdir -p /srv/www/$domain/public_html
mkdir -p /srv/www/$domain/logs

if [ ! -z $user ]
then
  if id -u $user; then
    echo "User $user already exists"
  else
    echo "Adding user $user"
    adduser $user
  fi

  echo "Adding $user to sftponly group"
  usermod -g sftponly $user

  echo "Removing shell access for $user"
  usermod -s /bin/false $user

  echo "Changing ownership of /home/$user to root"
  chown root:root /home/$user

  echo "Creating /home/$user/www/$domain"
  mkdir -p /home/$user/www/$domain

  echo "Changing ownership of /home/$user/www/ to $user and group to www-data"
  chown -R $user:www-data /home/$user/www

  echo "Binding /home/$user/www to /srv/www/$domain/public_html"
  mountcommand="mount --bind /home/$user/www/$domain /srv/www/$domain/public_html"
  eval $mountcommand

  # Newer versions of Ubuntu don't come with a default rc.local file, so we copy one over
  if [ ! -f /etc/rc.local ]; then
    cp templates/rclocal /etc/rc.local
    chown root.root /etc/rc.local
    chmod 755 /etc/rc.local
  fi

  sed -i "s@exit 0@$mountcommand \nexit 0@g" /etc/rc.local
else
  echo "No user specified, skipping site-specific user creation and setting $(logname) as site owner"
  chown -R $(logname):www-data /srv/www/$domain/public_html
fi

echo "Setting up site for nginx"
cp templates/nginx-basic /etc/nginx/sites-available/$domain

# Remove www if this is a subdomain (i.e. if it only has one dot, so doesn't work for .co.uk or others yet)
domainDotCount=$(echo $domain | grep -o "\." | wc -l)
if [ $domainDotCount -gt 1 ]; then
  sed "s@ www\._SITEURL_@@g" -i /etc/nginx/sites-available/$domain
fi

sed "s@_SITEURL_@$domain@g" -i /etc/nginx/sites-available/$domain

echo "You'll need to run the enable script to complete this set up"
