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

filetodisable="/etc/nginx/sites-enabled/$1"

if ! [ -L "$filetodisable" ]
  then
    echo $1 is not enabled
    exit 0
fi

rm $filetodisable
echo Disabled $1
/etc/init.d/nginx reload
