#!/bin/bash

# Find the name of the folder the scripts are in

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo -ne "
-------------------------------------------------------------------------
                Crummy Automated Arch Linux Installer
-------------------------------------------------------------------------
                Scripts are in directory named CrummyArch
"
    bash startup.sh
    source setup.conf
    bash 0-preinstall.sh
    arch-chroot /mnt /root/CrummyArch/1-setup.sh
    arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/CrummyArch/2-user.sh
    arch-chroot /mnt /root/CrummyArch/3-post-setup.sh

echo -ne "
-------------------------------------------------------------------------
                Crummy Automated Arch Linux Installer
-------------------------------------------------------------------------
                Done - Please Eject Install Media and Reboot
"
