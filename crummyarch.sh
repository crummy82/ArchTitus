#!/bin/bash

# Find the name of the folder the scripts are in

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -ne "
-------------------------------------------------------------------------
                Crummy Automated Arch Linux Installer
-------------------------------------------------------------------------
                https://github.com/crummy82/CrummyArch
"


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
    echo "${1}=${2}" >> $CONFIG_FILE # add option
}


# User enters their desired username, password, and hostname
clear
read -p "Please enter your desired username: " username
set_option USERNAME ${username,,} # convert to lower case
echo -ne "Please enter your desired password: \n"
read -s password # read password without echo
set_option PASSWORD $password
read -rep "Please enter your desired hostname: " machinename
set_option MACHINENAME $machinename


# User selection of disk and filesystem type
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
set_option DISK $option

# How the fstab mount options will be written depending on disk type
echo -ne "
Is this an ssd? yes/no:
"
read ssd_drive
case ${ssd_drive,,} in
    y|yes)
    set_option MOUNTOPTIONS "noatime,compress=zstd,ssd,commit=120";;
    n|no)
    set_option MOUNTOPTIONS "noatime,compress=zstd,commit=120";;
    *) echo "Invalid option. Try again";drivessd;;
esac

# Select btrfs or ext4 for the filesystem
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
    *) echo "Invalid option please select again"; filesystem;;
esac

# Fetch timezone from the net and ask to set it to that or make it something else
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "System detected your timezone to be '$time_zone' \n"
echo -ne "Is this correct? yes/no:" 
read answer
case ${answer,,} in
    y|yes)
    set_option TIMEZONE $time_zone;;
    n|no)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read new_timezone
    set_option TIMEZONE $new_timezone;;
    *) echo "Invalid option. Try again";timezone;;
esac

#Set keymapping to US
set_option KEYMAP "us"


##### All info received from user. Begin the setup process. #####

echo -ne "
-------------------------------------------------------------------------
                Thank you! Now installing Arch!
            Setting up mirrors for optimal download...
-------------------------------------------------------------------------
"
sleep 3
source $SCRIPT_DIR/setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
-------------------------------------------------------------------------
            Setting up $iso mirrors for faster downloads
-------------------------------------------------------------------------
"
sleep 3
reflector -c $iso -f 5 -l 10 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error messages if any
echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
sleep 3
pacman -S --noconfirm gptfdisk btrfs-progs
echo -ne "
-------------------------------------------------------------------------
                Formatting Disk and creating filesystems
-------------------------------------------------------------------------
"
sleep 3

# Set different disk label scheme if nvme disk
if [[ "${DISK}" =~ "nvme" ]]; then
    partition1=${DISK}p1
    partition2=${DISK}p2
else
    partition1=${DISK}1
    partition2=${DISK}2
fi

# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
if [[ ! -d "/sys/firmware/efi" ]]; then # Check for BIOS system and create BIOS boot partition 1 if true
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
    sgdisk -A 1:set:2 ${DISK} # Set BIOS bootable flag
    # Create partition 2 (Root, /), type Linux, using remaining space
    sgdisk -n 2::0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}

else # create EFI boot partition 1 instead
    sgdisk -n 1::+300M --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK}
    mkfs.vfat -F32 -n "EFIBOOT" ${partition1}
    # Create partition 2 (Root, /), type Linux, using remaining space
    sgdisk -n 2::0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}
    
fi

# Update system with new partitions
partprobe ${DISK}

if [[ "${FS}" == "btrfs" ]]; then
    mkfs.btrfs -L ROOT ${partition2} -f
    mount -t btrfs ${partition2} /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@.snapshots
    umount /mnt
    mount -t btrfs -o subvol=@ -L ROOT /mnt

elif [[ "${FS}" == "ext4" ]]; then
    mkfs.ext4 -L ROOT ${partition2}
    mount -t ext4 ${partition2} /mnt
fi

if [ -d "/sys/firmware/efi" ]; then
    # mount efi boot target
    mkdir -p /mnt/boot/efi
fi

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi
echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
sleep 3
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/CrummyArch
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
sleep 3
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
fi
echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <8G
-------------------------------------------------------------------------
"
sleep 3
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi
echo -ne "









    bash startup.sh
    source $SCRIPT_DIR/setup.conf
    bash 0-preinstall.sh
    arch-chroot /mnt /root/CrummyArch/1-setup.sh
    arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/CrummyArch/2-user.sh
    arch-chroot /mnt /root/CrummyArch/3-post-setup.sh

echo -ne "
-------------------------------------------------------------------------
                Crummy Automated Arch Linux Installer
-------------------------------------------------------------------------
           Done! - Please reboot and eject the install media 
"
