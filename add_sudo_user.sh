#!/bin/bash
login_user=`whoami`
root_dir=`pwd`

login_user=$1

### add specified user into sudo group

function requires_root {
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: You need sudo to run the program" 2>&1
        exit
    fi
}

requires_root

if [ ! -n "$login_user" ]; then
    echo "Specify user"
    exit
fi

sed -i -e "/%sudo\s*ALL=(ALL:ALL)\s*ALL/ a $login_user ALL=(ALL:ALL) NOPASSWD:NOPASSWD:ALL\n" /etc/sudoers

