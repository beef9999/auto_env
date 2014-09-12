#!/bin/bash
login_user=`whoami`
root_dir=`pwd`

login_user=$1

### add specified user into sudo group

if [ ! -n "$login_user" ]; then
    echo "Specify user"
    exit
fi

sed -i -e "/%sudo\s*ALL=(ALL:ALL)\s*ALL/ a $login_user ALL=(ALL:ALL) NOPASSWD:NOPASSWD:ALL\n" /etc/sudoers

