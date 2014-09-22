#!/bin/bash
root_dir=`pwd`
project="auto_env"
target_user=$1

### add specified user into sudo group

function requires_root {
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: You need sudo to run the program" 2>&1
        exit
    fi
}

requires_root


if [ ! -n "$target_user" ]; then
    echo "Specify user"
    exit
fi

adduser $target_user


sed -i -e "/%sudo\s*ALL=(ALL:ALL)\s*ALL/ a $target_user ALL=(ALL:ALL) NOPASSWD:NOPASSWD:ALL\n" /etc/sudoers

chown -R $target_user:$target_user $root_dir

mv /root/$project /home/$target_user

cd /home/$target_user/$project

root_dir=`pwd`

su $target_user
