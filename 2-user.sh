#!/usr/bin/env bash
echo -ne "
-------------------------------------------------------------------------
                Crummy Automated Arch Linux Installer
                        SCRIPTHOME: CrummyArch
-------------------------------------------------------------------------

Installing AUR Software
"
sleep 3
source /root/CrummyArch/setup.conf

cd ~
git clone "https://aur.archlinux.org/yay-git.git"
cd ~/yay
makepkg -si --noconfirm
cd ~
# Add Chris Titus's zsh config and powerlevel10k plugin for zsh
# touch "~/.cache/zshhistory"
# git clone "https://github.com/ChrisTitusTech/zsh"
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
# ln -s "~/zsh/.zshrc" ~/.zshrc

yay -S --noconfirm --needed - < ~/CrummyArch/pkg-files/aur-pkgs.txt

echo -ne "
Configuring the KDE Desktop
"
export PATH=$PATH:~/.local/bin
cp -r ~/CrummyArch/dotfiles/* ~/.config/
# KDE auto configuration section
# pip install konsave
# mkdir -p ~/.local/share/konsole/
# konsave -i ~/CrummyArch/brads_kde.knsv
# sleep 1
# konsave -a brads_kde

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
sleep 3
exit
