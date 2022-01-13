#!/usr/bin/env bash
# This script will ask users about their prefrences 
# like disk, file system, timezone, keyboard layout,
# user name, password, etc.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# set up a config file
CONFIG_FILE=$SCRIPT_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists
    touch -f $CONFIG_FILE # create file if not exists
fi

# set options in setup.conf
set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}

logo () {
# This will be shown on every set as user is progressing through pre-setup
echo -ne "
------------------------------------------------------------------------
                Crummy Automated Arch Linux Installer
            Please select presetup settings for your system              
------------------------------------------------------------------------
"
}

# Select file system for the machine
filesystem () {
echo -ne "
    Please Select your file system for both boot and root
    1)      btrfs
    2)      ext4
    0)      exit
"
read FS
case $FS in
1) set_option FS btrfs;;
2) set_option FS ext4;;
0) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}

timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "System detected your timezone to be '$time_zone' \n"
echo -ne "Is this correct? yes/no:" 
read answer
case $answer in
    y|Y|yes|Yes|YES)
    set_option TIMEZONE $time_zone;;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read new_timezone
    set_option TIMEZONE $new_timezone;;
    *) echo "Wrong option. Try again";timezone;;
esac
}

keymap () {
set_option KEYMAP "us" #Set keymapping to US
}

drivessd () {
echo -ne "
Is this an ssd? yes/no:
"
read ssd_drive

case ${ssd_drive,,} in
    y|yes)
    echo "mountoptions=noatime,compress=zstd,ssd,commit=120" >> setup.conf;;
    n|no)
    echo "mountoptions=noatime,compress=zstd,commit=120" >> setup.conf;;
    *) echo "Invalid option. Try again";drivessd;;
esac
}

# selection for disk type
diskpart () {
# show disks present on system
echo -ne "
Available storage devices for installation:
"
lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print NR,"/dev/"$2" - "$3}' # show disks with /dev/ prefix and size
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK             
    Please make sure you know what you are doing because         
    after formating your disk there is no way to get data back      
------------------------------------------------------------------------

Please enter full path to disk: (example /dev/sda):
"
read option
echo "DISK=$option" >> setup.conf

drivessd
set_option DISK $option
}

userinfo () {
read -p "Please enter your desired username: " username
set_option USERNAME ${username,,} # convert to lower case
echo -ne "Please enter your desired password: \n"
read -s password # read password without echo
set_option PASSWORD $password
read -rep "Please enter your desired hostname: " MACHINENAME
set_option MACHINENAME $MACHINENAME
}

# Start running functions
clear
logo
userinfo
clear
logo
diskpart
clear
logo
filesystem
clear
logo
timezone
clear
logo
keymap