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

echo "Getting certificate"
if certbot certonly --webroot -w /srv/www/$1/public_html -d $1; then
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
cp templates/nginx-letsencrypt /etc/nginx/sites-available/$1
sed -i "s@_SITEURL_@$1@g" /etc/nginx/sites-available/$1

echo "Reloading nginx"
/etc/init.d/nginx reload
