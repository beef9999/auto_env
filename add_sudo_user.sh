#!/bin/bash
root_dir=`pwd`
project="auto_env"
target_user=$1

source ./functions.sh
requires_root

### add specified user into sudo group


if [ ! -n "$target_user" ]; then
    echo "Specify user"
    exit
fi

adduser $target_user
echo "$target_user:tester" | chpasswd


#sed -i -e "/%sudo\s*ALL=(ALL:ALL)\s*ALL/ a $target_user ALL=(ALL:ALL) NOPASSWD:NOPASSWD:ALL\n" /etc/sudoers
echo "$target_user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

chown -R $target_user:$target_user $root_dir

mv $root_dir /home/$target_user

cd /home/$target_user/$project

root_dir=`pwd`

sudo -iu $target_user
