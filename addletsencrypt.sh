#!/bin/bash

if [ "$(whoami)" != "root" ]
  then
    echo This script needs sudo privileges
    exit 2
fi

if [ -z $1 ]
  then
    echo Usage: $0 URL
    exit 1
fi

if ! [ -x "$(command -v certbot --version)" ]; then
  echo "Error: certbot is not installed" >&2
  exit 1
fi

if ! [ -f /etc/nginx/sites-enabled/$1 ]; then
  echo "Error: Site $1 must be enabled to generate cert"
  exit 1
fi

domain=$1

echo "Getting certificate for $domain"
domainArgs="-d $domain"
domainDotCount=$(echo $domain | grep -o "\." | wc -l)

# Add a www certificate if this is the root domain (i.e. if it only has one dot, so doesn't work for .co.uk or others yet)
if [ $domainDotCount -eq 1 ]; then
  domainArgs="$domainArgs -d www.$domain"
  echo " - Including certificate for www.$domain"
fi

if certbot certonly --webroot -w /srv/www/$domain/public_html $domainArgs; then
  echo "Got certificate"
else
  echo "Failed to get certificate"
  exit 1
fi

if ! [ -f /etc/ssl/certs/dhparam.pem ]; then
  echo "Creating dhparam.pem"
  openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096
fi

echo "Setting new nginx config"
cp templates/nginx-letsencrypt /etc/nginx/sites-available/$domain

# Remove www if this is a subdomain (i.e. if it only has one dot, so doesn't work for .co.uk or others yet)
if [ $domainDotCount -gt 1 ]; then
  sed "s@ www\._SITEURL_@@g" -i /etc/nginx/sites-available/$domain
fi

sed -i "s@_SITEURL_@$domain@g" /etc/nginx/sites-available/$domain

echo "Reloading nginx"
/etc/init.d/nginx reload
