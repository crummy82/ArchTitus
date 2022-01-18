#!/usr/bin/env bash
echo -ne "
-------------------------------------------------------------------------
                Crummy Automated Arch Linux Installer
                        SCRIPTHOME: CrummyArch
-------------------------------------------------------------------------

Installing AUR Software
"
sleep 3
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.
source $HOME/CrummyArch/setup.conf

cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ~/yay
makepkg -si --noconfirm
cd ~
touch "~/.cache/zshhistory"
git clone "https://github.com/ChrisTitusTech/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
ln -s "~/zsh/.zshrc" ~/.zshrc

yay -S --noconfirm --needed - < ~/CrummyArch/pkg-files/aur-pkgs.txt

echo -ne "
Configuring the KDE Desktop
"
export PATH=$PATH:~/.local/bin
cp -r ~/CrummyArch/dotfiles/* ~/.config/
pip install konsave
mkdir -p ~/.local/share/konsole/
konsave -i ~/CrummyArch/brads_kde.knsv
sleep 1
konsave -a brads_kde

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
sleep 3
exit
