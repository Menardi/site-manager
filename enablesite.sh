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

availablefile="/etc/nginx/sites-available/$1"
enabledfile="/etc/nginx/sites-enabled/$1"

if [ -e "$enabledfile" ]
  then
    echo $1 is already enabled
    exit 0
fi

if ! [ -e "$availablefile" ]
  then
    echo There is no config to enable for $1
    exit 3
fi

ln -s $availablefile $enabledfile
echo Enabled $1
/etc/init.d/nginx reload

