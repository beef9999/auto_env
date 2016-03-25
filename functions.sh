# functions - Common functions used by OpenStack

function requires_root {
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: You need sudo to run the program" 2>&1
        exit
    fi
}

function requires_user {
    if [[ $EUID -eq 0 ]]; then
        echo "ERROR: You should run the program as ordinary user" 2>&1
        exit
    fi
}

function get_ip {
    if [ -z $1 ]; then
        IF=eth0
    else
        IF=$1
    fi
    /sbin/ip addr show $IF > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        return
    fi
    /sbin/ip addr show $IF | grep -w inet | awk '{print $2}' | cut -f1 -d'/'
}

function masklen2mask {
    case "$1" in
        32) echo "255.255.255.255";;
        31) echo "255.255.255.254";;
        30) echo "255.255.255.252";;
        29) echo "255.255.255.248";;
        28) echo "255.255.255.240";;
        27) echo "255.255.255.224";;
        26) echo "255.255.255.192";;
        25) echo "255.255.255.128";;
        24) echo "255.255.255.0";;
        23) echo "255.255.254.0";;
        22) echo "255.255.252.0";;
        21) echo "255.255.248.0";;
        20) echo "255.255.240.0";;
        19) echo "255.255.224.0";;
        18) echo "255.255.192.0";;
        17) echo "255.255.128.0";;
        16) echo "255.255.0.0";;
        15) echo "255.254.0.0";;
        14) echo "255.252.0.0";;
        13) echo "255.248.0.0";;
        12) echo "255.240.0.0";;
        11) echo "255.224.0.0";;
        10) echo "255.192.0.0";;
        9)  echo "255.128.0.0";;
        8)  echo "255.0.0.0";;
        7)  echo "254.0.0.0";;
        6)  echo "252.0.0.0";;
        5)  echo "248.0.0.0";;
        4)  echo "240.0.0.0";;
        3)  echo "224.0.0.0";;
        2)  echo "192.0.0.0";;
        1)  echo "128.0.0.0";;
        0)  echo "0.0.0.0";;
        *)  exit 1;;
    esac
}

function get_mask {
    if [ -z $1 ]; then
        IF=eth0
    else
        IF=$1
    fi
    /sbin/ip addr show $IF > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        return
    fi
    MASKLEN=$(/sbin/ip addr show $IF | grep -w inet | awk '{print $2}' | cut -f2 -d'/')
    masklen2mask $MASKLEN
}

function genpasswd {
    local l=$1
    [ "$l" == "" ] && l=16
    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}

function screen_it {
    NL=`echo -ne '\015'`
    SESSION=$(screen -ls | awk '/[0-9].'$1'/ { print $1 }')
    if [ ! -n "$SESSION" ]; then
        screen -d -m -s /bin/bash -S $1
        sleep  1.5
    fi
    screen -S $1 -p 0 -X stuff "$2$NL"
}

function quit_screen {
    SESSION=$(screen -ls | awk '/[0-9].'$1'/ { print $1 }')
    if [ -n "$SESSION" ]; then
        screen -X -S $SESSION quit
    fi
    SESSION=$(screen -ls | awk '/[0-9].'$1'/ { print $1 }')
    if [ -n "$SESSION" ]; then
        echo "Start to kill session $SESSION"
        SESSION_PID=$(echo $SESSION | grep -o "^[0-9]\+")
        kill -s SIGKILL $SESSION_PID > /dev/null 2>&1
        screen -wipe $SESSION > /dev/null 2>&1
        # screen wipe return value is not zero, use echo to escape
        echo "Finish killing and wiping session $SESSION"
    fi
}

function is_service_screen_running {
    SESSION=$(screen -ls | awk '/[0-9].'$1'/ { print $1 }')
    if [ -n "$SESSION" ]; then
        echo "$1:running"
    else
        echo "$1:stopped"
    fi
}

function stop_screen {
    SESSION=$(screen -ls | awk '/[0-9].'$1'/ { print $1 }')
    if [ -n "$SESSION" ]; then
        #screen -X -S $SESSION quit
        quit_screen $1
        return 1
    else
        return 0
    fi
}

function stop_service_screen {
    for serv in $@
    do
        stop_screen $serv
        if [ $? -eq "0" ]; then
            echo "No service $serv is running"
        else
            echo "Service $serv is stopped successfully"
        fi
    done
}

function is_dns_start {
    netstat -l -u -n | grep '\<0.0.0.0:53\>' > /dev/null
}

function is_service_running {
    local SERV_SCREEN=$1
    local PID_FILE=$2
    if [ -n "$PID_FILE" ]; then
        if [ -f $PID_FILE ]; then
            local PID=$(cat $PID_FILE)
            if ps -p $PID > /dev/null; then
                echo "$SERV_SCREEN:running"
                return
            fi
        fi
    fi
    is_service_screen_running $SERV_SCREEN
}

function stop_service {
    local PID_FILE=$1
    local MAX_TRIES=$2
    local SERV_SCREEN=$3
    if [ -f $PID_FILE ]; then
        local PID=$(cat $PID_FILE)
        local TRIES=0
        while ps -p $PID > /dev/null; do
            TRIED=$((TRIED+1))
            if [ $TRIED -gt $MAX_TRIES ]; then
                SIGNAL=SIGKILL
            else
                SIGNAL=SIGTERM
            fi
            kill -s $SIGNAL $PID > /dev/null 2>&1
            sleep 1
        done
        rm -fr $PID_FILE
        echo "Stop $SERV_SCREEN successfully"
    fi
    stop_service_screen $SERV_SCREEN
}

function apt_get() {
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"
    $sudo DEBIAN_FRONTEND=noninteractive \
        http_proxy=$http_proxy https_proxy=$https_proxy \
        apt-get --option "Dpkg::Options::=--force-confold" --assume-yes "$@" || return 1
}


function yum_install() {
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"
    $sudo http_proxy=$http_proxy https_proxy=$https_proxy \
        no_proxy=$no_proxy \
        yum install -y "$@" || return 1
}


function yum_groupremove() {
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"
    $sudo yum groupremove -y "$1"
}


function pip_install {
    PIP_CACHE=$ORIGIN_DIR/pip_cache
    sudo mkdir -p $PIP_CACHE
    CMD_PIP=/usr/bin/pip
    sudo PIP_DOWNLOAD_CACHE=$PIP_CACHE \
        HTTP_PROXY=$http_proxy \
        HTTPS_PROXY=$https_proxy \
        $CMD_PIP install --use-mirrors $@
}


# Get an option from an INI file
# iniget config-file section option
function iniget() {
    local file=$1
    local section=$2
    local option=$3
    local line
    line=$(sed -ne "/^\[$section\]/,/^\[.*\]/ { /^$option[ \t]*=/ p; }" $file)
    echo ${line#*=}
}

function confget() {
    local file=$1
    local option=$2
    local line
    line=$(sed -ne "/^$option[ \t]*=/ p;" $file)
    echo ${line#*=}
}

# iniset config-file section option value
function iniset() {
    local file=$1
    local section=$2
    local option=$3
    local value=$4
    if ! grep -q "^\[$section\]" $file; then
        # Add section at the end
        echo -e "\n[$section]" >>$file
    fi
    if [[ -z "$(iniget $file $section $option)" ]]; then
        # Add it
        sed -i -e "/^\[$section\]/ a\\
$option = $value
" $file
    else
        # Replace it
        sed -i -e "/^\[$section\]/,/^\[.*\]/ s|^\($option[ \t]*=[ \t]*\).*$|\1$value|" $file
    fi
}

function confset() {
    local file=$1
    local option=$2
    local value=$3
    if [[ -z "$(confget $file $option)" ]]; then
        echo "$option = $value" >> $file
    else
        sed -i -e "s|^\($option[ \t]*=[ \t]*\).*$|\1$value|" $file
    fi
}

function initset() {
    local file=$1
    local option=$2
    local value=$3
    if [[ -z "$(confget $file $option)" ]]; then
        echo "$option=$value" >> $file
    else
        sed -i -e "s|^\($option[ \t]*=[ \t]*\).*$|\1$value|" $file
    fi
}

# Comment an option in an INI file
# inicomment config-file section option
function inicomment() {
    local file=$1
    local section=$2
    local option=$3
    sed -i -e "/^\[$section\]/,/^\[.*\]/ s|^\($option[ \t]*=.*$\)|#\1|" $file
}

function mysql_drop_db {
    mysql --user=root --password=$1 mysql -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "drop database if exists $2"
    if [ $? -ne 0 ]; then
        echo "Failed to drop database"
        return 0
    fi
}

#mysql_init root_pass db user pass
function mysql_init {
    mysql --user=root --password=$1 -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "show databases" | grep $2 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Database $2 exists, recreate?(yes/no)"
        read confirm
        if [ "$confirm" == "no" ]; then
            echo "Keep database ..."
            return 1
        fi
        echo "Create database ..."
    fi
    mysql --user=root --password=$1 mysql -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "drop database if exists $2"
    if [ $? -ne 0 ]; then
        echo "Failed to drop database"
        return 0
    fi
    mysql --user=root --password=$1 mysql -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "create database if not exists $2"
    if [ $? -ne 0 ]; then
        echo "Failed to create database"
        return 0
    fi
    mysql --user=root --password=$1 mysql -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "drop user '$3'@'%'"
    mysql --user=root --password=$1 mysql -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "drop user '$3'@'localhost'"
    mysql --user=root --password=$1 mysql -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "grant all on $2.* to '$3'@'%' identified by '$4'"
    mysql --user=root --password=$1 mysql -h $MYSQL_HOST --port=$MYSQL_PORT \
        -e "grant all on $2.* to '$3'@'localhost' identified by '$4'"
    if [ $? -ne 0 ]; then
        echo "Failed to create mysql account, please login as root into mysql at localhost machine"
        echo "Execute the following two SQL:"
        echo "      grant all on *.* to 'root'@'%' identified by '<your_mysql_root_password>' with grant option;"
        return 0
    fi
    return 1
}

# 0             1      2    3    4            5      6      7
# init_keystone tenant user pass service_name puburl inturl adminurl
function init_keystone {
    if [ ! -z $KEYSTONE_SSL ]; then
        KEYSTONE_PROTOCOL=https
    else
        KEYSTONE_PROTOCOL=http
    fi
    export OS_AUTH_TOKEN=$SERVICE_TOKEN
    export OS_AUTH_URL=$KEYSTONE_PROTOCOL://$KEYSTONE_HOST:$KEYSTONE_ADMIN_PORT/v2.0
    cd $CUSTOM_DIR/tools
    ./role-show admin > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        if ! ./role-create admin; then
            echo "Fail to create role admin"
            exit -1
        fi
    fi
    ./tenant-show $1 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        if ! ./tenant-create $1; then
            echo "Fail to create tenant $1"
            exit -1
        fi
    fi
    ./user-show $2 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        if ! ./user-create --tenant $1 --passwd $3 $2; then
            echo "Fail to create user $2"
            exit -1
        fi
        if ! ./user-role-add --role admin --tenant $1 $2; then
            echo "Fail to add $2 with admin role"
            exit -1
        fi
    fi
    if [ $# -ge 7 ]; then
        ./service-show $2 > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            if ! ./service-create --type $4 $2; then
                echo "Fail to create service $2"
                exit -1
            fi
            if ! ./endpoint-create --service $2 --region $REGION --public $5 --internal $6 --admin $7; then
                echo "Fail to create endpoint $2 $REGION"
                exit -1
            fi
        fi
    fi
}

function check_vars {
    for VAR in $@
    do
        if [ -z ${!VAR} ]; then
            echo "$VAR not present"
            exit -1
        fi
    done
}

function check_service {
    local URL=$1
    local TIMEOUT=$2
    #echo "Check service $URL"
    if [ -z $TIMEOUT ]; then
        TIMEOUT=300
    fi
    if [[ $1 == https* ]]; then
        OPT='-k'
    else
        OPT=''
    fi
    if ! timeout $TIMEOUT sh -c "while ! curl $OPT -s $1 >/dev/null; do sleep 1; done"; then
        #echo "Cannot reach!"
        return 1
    else
        #echo "Success!"
        return 0
    fi
}


function quick_check_service {
    if check_service $1 2; then
        return 0
    else
        return 1
    fi
}


GetOSVersion() {
    # Figure out which vendor we are
    if [[ -n "`which sw_vers 2>/dev/null`" ]]; then
        # OS/X
        os_VENDOR=`sw_vers -productName`
        os_RELEASE=`sw_vers -productVersion`
        os_UPDATE=${os_RELEASE##*.}
        os_RELEASE=${os_RELEASE%.*}
        os_PACKAGE=""
        if [[ "$os_RELEASE" =~ "10.7" ]]; then
            os_CODENAME="lion"
        elif [[ "$os_RELEASE" =~ "10.6" ]]; then
            os_CODENAME="snow leopard"
        elif [[ "$os_RELEASE" =~ "10.5" ]]; then
            os_CODENAME="leopard"
        elif [[ "$os_RELEASE" =~ "10.4" ]]; then
            os_CODENAME="tiger"
        elif [[ "$os_RELEASE" =~ "10.3" ]]; then
            os_CODENAME="panther"
        else
            os_CODENAME=""
        fi
    elif [[ -x $(which lsb_release 2>/dev/null) ]]; then
        os_VENDOR=$(lsb_release -i -s)
        os_RELEASE=$(lsb_release -r -s)
        os_UPDATE=""
        if [[ "Debian,Ubuntu" =~ $os_VENDOR ]]; then
            os_PACKAGE="deb"
        elif [[ "SUSE LINUX" =~ $os_VENDOR ]]; then
            lsb_release -d -s | grep -q openSUSE
            if [[ $? -eq 0 ]]; then
                os_VENDOR="openSUSE"
            fi
            os_PACKAGE="rpm"
        else
            os_PACKAGE="rpm"
        fi
        os_CODENAME=$(lsb_release -c -s)
    elif [[ -r /etc/redhat-release ]]; then
        # Red Hat Enterprise Linux Server release 5.5 (Tikanga)
        # CentOS release 5.5 (Final)
        # CentOS Linux release 6.0 (Final)
        # Fedora release 16 (Verne)
        os_CODENAME=""
        for r in "Red Hat" CentOS Fedora; do
            os_VENDOR=$r
            if [[ -n "`grep \"$r\" /etc/redhat-release`" ]]; then
                ver=`sed -e 's/^.* \(.*\) (\(.*\)).*$/\1\|\2/' /etc/redhat-release`
                os_CODENAME=${ver#*|}
                os_RELEASE=${ver%|*}
                os_UPDATE=${os_RELEASE##*.}
                os_RELEASE=${os_RELEASE%.*}
                break
            fi
            os_VENDOR=""
        done
        os_PACKAGE="rpm"
    elif [[ -r /etc/SuSE-release ]]; then
        for r in openSUSE "SUSE Linux"; do
            if [[ "$r" = "SUSE Linux" ]]; then
                os_VENDOR="SUSE LINUX"
            else
                os_VENDOR=$r
            fi

            if [[ -n "`grep \"$r\" /etc/SuSE-release`" ]]; then
                os_CODENAME=`grep "CODENAME = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_RELEASE=`grep "VERSION = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_UPDATE=`grep "PATCHLEVEL = " /etc/SuSE-release | sed 's:.* = ::g'`
                break
            fi
            os_VENDOR=""
        done
        os_PACKAGE="rpm"
    fi
    export os_VENDOR os_RELEASE os_UPDATE os_PACKAGE os_CODENAME
}


function GetDistro() {
    GetOSVersion
    if [[ "$os_VENDOR" =~ (Ubuntu) ]]; then
        # 'Everyone' refers to Ubuntu releases by the code name adjective
        DISTRO=$os_CODENAME
    elif [[ "$os_VENDOR" =~ (Fedora) ]]; then
        # For Fedora, just use 'f' and the release
        DISTRO="f$os_RELEASE"
    elif [[ "$os_VENDOR" =~ (openSUSE) ]]; then
        DISTRO="opensuse-$os_RELEASE"
    elif [[ "$os_VENDOR" =~ (SUSE LINUX) ]]; then
        # For SLE, also use the service pack
        if [[ -z "$os_UPDATE" ]]; then
            DISTRO="sle${os_RELEASE}"
        else
            DISTRO="sle${os_RELEASE}sp${os_UPDATE}"
        fi
    else
        # Catch-all for now is Vendor + Release + Update
        DISTRO="$os_VENDOR-$os_RELEASE.$os_UPDATE"
    fi
    export DISTRO
}


function is_ubuntu {
    if [[ -z "$os_PACKAGE" ]]; then
        GetOSVersion
    fi

    [ "$os_PACKAGE" = "deb" ]
}


function is_fedora {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "Fedora" ] || [ "$os_VENDOR" = "Red Hat" ] || [ "$os_VENDOR" = "CentOS" ]
}

function is_centos {
	if [[ -z "$os_VENDOR" ]]; then
		GetOSVersion
	fi
	[ "$os_VENDOR" = "CentOS" ]
}

function is_centos7 {
	if is_centos ; then
		[[ "$os_RELEASE" =~ "7." ]]
    else
        return 1
	fi
}

function exit_distro_not_supported {
    if [[ -z "$DISTRO" ]]; then
        GetDistro
    fi

    if [ $# -gt 0 ]; then
        echo "Support for $DISTRO is incomplete: no support for $@"
    else
        echo "Support for $DISTRO is incomplete."
    fi

    exit 1
}


function is_package_installed() {
    if [[ -z "$@" ]]; then
        return 1
    fi

    if [[ -z "$os_PACKAGE" ]]; then
        GetOSVersion
    fi

    if [[ "$os_PACKAGE" = "deb" ]]; then
        dpkg -l "$@" > /dev/null
        return $?
    elif [[ "$os_PACKAGE" = "rpm" ]]; then
        rpm --quiet -q "$@"
        return $?
    else
        exit_distro_not_supported "finding if a package is installed"
    fi
}


# Distro-agnostic package installer
# install_package package [package ...]
function install_package() {
    if is_ubuntu; then
        apt_get install "$@" || return 1
    elif is_fedora; then
        yum_install "$@" || return 1
        return 0
    #elif is_suse; then
    #    zypper_install "$@"
    else
        exit_distro_not_supported "installing packages"
        return 1
    fi
}


function uninstall_package() {
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"
    if is_ubuntu; then
        $sudo apt-get remove --purge --assume-yes "$@"
        $sudo apt-get autoremove --purge --assume-yes
    elif is_fedora; then
        $sudo yum erase -y "$@"
    else
        exit_distro_not_supported "uninstalling packages"
    fi
}

function get_screen_pid {
    screen -ls | awk '/[0-9].'$1'/ { print $1 }' | awk -F '.' '{print $1}'
}

function start_service () {
    local URL=$1
    local SERVICE=$2
    local CMD=$3
    local NO_CHECK=$4

    if [[ $NO_CHECK = "NO_CHECK" ]]; then
	screen_it $SERVICE "$CMD"
	echo "$SERVICE started successfully"
    return
    fi

    if ! quick_check_service $URL; then
        screen_it $SERVICE "$CMD"
        sleep 1
        MAX_TRIES=300
        TRIES=0
        while (( $TRIES < $MAX_TRIES ))
        do
            local PID=$(pgrep -P $(pgrep -P $(get_screen_pid $SERVICE)))
            if [[ -z "$PID" ]]; then
                echo "Failed to start $SERVICE"
                exit 1
            fi

            TRIES=$(( TRIES+1 ))
            if check_service $URL 1; then
                echo "$SERVICE started successfully"
                TRIES=$(( MAX_TRIES + 1))
            fi
        done
        if [ $TRIES -eq $MAX_TRIES ]; then
            echo "Failed to start $SERVICE"
            exit 1
        fi
    else
        echo "$SERVICE is running"
    fi
}

function super_restart_service {
    local URL=$1
    local SERVICE=$2
    local CMD=$3
    local PID_FILE=$4
    local NO_CHECK=$5

    MAX_TRIES=300
    TRIES=0
    while (( $TRIES < $MAX_TRIES ))
    do
        local PID=""
        if [ -f $PID_FILE ]; then
            PID=$(cat $PID_FILE)
        fi
        if [[ -z "$PID" ]]; then
            start_service $URL $SERVICE "$CMD" $NO_CHECK
        else
            SIGNAL=SIGUSR1
            kill -s $SIGNAL $PID > /dev/null 2>&1
        fi
        sleep 2
        TRIES=$(( TRIES + 1 ))
        if check_service $URL 1; then
            echo "$SERVICE restarted successfully"
            TRIES=$(( MAX_TRIES + 1 ))
        fi
    done
}

function get_conf_path() {
    local conf=$1
    DIR=~/mclouds
    if [ -f $DIR/$1 ]; then
        echo $DIR/$1
        return 0
    fi
    DIR=/usr/local/etc/mclouds
    if [ -f $DIR/$1 ]; then
        echo $DIR/$1
        return 0
    fi
    DIR=/etc/mclouds
    if [ -f $DIR/$1 ]; then
        echo $DIR/$1
        return 0
    fi
    echo "Failed to find config $conf"
    exit 1
}

function is_service_on() {
    local flag=$1
    if [ $flag == 'on' ] || [ $flag == 'yes' ] || [ $flag == 'YES' ] || [ $flag == 'ON' ]; then
        return 0
    else
        return 1
    fi
}

function install_command_usage {
    echo "Usage: PROG [-r ROLE] [-f]"
    echo "       -f: install by force"
    echo "       -r [host|controller|swiftstore|swiftproxy]: install for specific server role"
    exit 1
}

function parse_install_command {
    FORCE=
    SERVER_ROLE=

    while getopts "hfr:" opt; do
        case $opt in
            f)
                FORCE="force"
                ;;
            r)
                SERVER_ROLE=$OPTARG
                if [ "$SERVER_ROLE" != "host" ] && [ "$SERVER_ROLE" != "controller" ] && [ "$SERVER_ROLE" != "swiftstore" ] && [ "$SERVER_ROLE" != "swiftproxy" ] ; then
                    echo "Invalid role $SERVER_ROLE, must be either host, controller, swiftstore, swiftproxy"
                    exit 1
                fi
                ;;
            h)
                install_command_usage
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
        esac
    done

    if [ -z "$SERVER_ROLE" ]; then
        install_command_usage
    else
        echo "Set role to $SERVER_ROLE"
    fi
    if [ -n "$FORCE" ]; then
        echo "Process by FORCE"
    fi
}

function get_login_user {
    if [ -n "$SUDO_USER" ]; then
        echo $SUDO_USER
        return
    fi

    user=$(who is gaofushuai | awk '{print $1}')
    if [ ! -z "$user" ]; then
        echo $user
        return
    fi

}

function get_login_group {
    local LUSR=$(get_login_user)
    if [ -n "$LUSR" ]; then
        id -g -n "$LUSR"
    fi
}

function user_check {
    local USER=$(get_login_user)
    if [[ "x$USER" == "xroot" ]] || [[ $EUID -eq 0 ]]; then
        echo "ERROR: You should run the script as an ordinary user" 2>&1
        exit
    fi
    sudo /sbin/ifconfig > /dev/null 2>&1
    if [ "$?" != "0" ]; then
        echo "ERROR: You should be able to execute sudo!" 2>&1
        exit
    fi
}

function enable_service {
    local SERVICE_NAME=$1
    local ONOFF=$2
    if is_ubuntu; then
        local INITFILE=/etc/default/mclouds
    elif is_fedora; then
        local INITFILE=/etc/sysconfig/mclouds
    else
        echo "Unsupported system"
        exit 1
    fi

    if ! test -f $INITFILE; then
        echo "Init $INITFILE not exists"
        exit 1
    fi

    local TEMPFILE=`mktemp`
    cp $INITFILE $TEMPFILE
    initset $TEMPFILE $SERVICE_NAME $ONOFF
    sudo cp $TEMPFILE $INITFILE
    rm -fr $TEMPFILE
}

function is_autosql_enabled {
    local SERVICE=$1
    local CONF_FILE=/etc/mclouds/autosql/$SERVICE.conf
    if test -f $CONF_FILE; then
        local service_trigger=$(cat $CONF_FILE | tr -d "['\" ]" | grep "service=on")
        if [[ -n "$service_trigger" ]]; then
            return 0
        fi
    fi
    return 1
}
