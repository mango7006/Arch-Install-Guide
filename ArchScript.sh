#!/bin/bash

# Defining colors
RED="\e[31m"
ENDCOLOR="\e[0m"
GREEN="\e[32m"

# Color test (remove later)
echo -e "${RED}TEST${ENDCOLOR}"

echo "                    _       _           _        _ _                 _       _   ";
echo "     /\            | |     (_)         | |      | | |               (_)     | |  ";
echo "    /  \   _ __ ___| |__    _ _ __  ___| |_ __ _| | |  ___  ___ _ __ _ _ __ | |_ ";
echo "   / /\ \ | '__/ __| '_ \  | | '_ \/ __| __/ _\` | | | / __|/ __| '__| | '_ \| __|";
echo "  / ____ \| | | (__| | | | | | | | \__ \ || (_| | | | \__ \ (__| |  | | |_) | |_ ";
echo " /_/    \_\_|  \___|_| |_| |_|_| |_|___/\__\__,_|_|_| |___/\___|_|  |_| .__/ \__|";
echo "                                                                      | |        ";
echo "                                                                      |_|        ";
echo ''
echo 'Running Arch Install script created by mango7002'
echo ''

# Ask to start the script
read -r -p "Are you sure you want to run this unverified script? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    clear
    echo -e "${GREEN}Starting${ENDCOLOR}"
    sleep 1
    echo 'Please make sure you have already completed the "Pre-installation" step from the archlinux.org website'
    sleep 4
    clear

else
    clear
    echo -e "${RED}EXITING"
    sleep 2
    clear
fi


# Installing base pkgs
echo 'Installing packages'

pacstrap -K /mnt 
# TODO: Define packages

# Generate fstab
echo 'Generating filesystem table'
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot to OS
echo 'Chrooting into newly installed OS'
arch-chroot /mnt

# Timezone setup
echo 'Setting timezone'
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

# User chooses the locale
echo 'Setting locale and keyboard layout'
locale=en_US.UTF-8
sed -i "/^#$locale/s/^#//" /etc/locale.gen
echo "LANG=$locale" > /etc/locale.conf
echo "KEYMAP=$kblayout" > /etc/vconsole.conf
locale-gen

# Hostname
echo 'Setting hostname'
echo "arch" > /etc/hostname

# Root password
echo 'Settin root password'
echo "root:20070422" | chpasswd

# Making user account
echo 'Making a standard user'
useradd -m -g users -G wheel,storage,power,video,audio -s /bin/zsh mango

# Enabling services
echo 'Enabling services'
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable ntpd


echo 'Installing systemd bootloader'
bootctl --path=/boot install

# TODO: finish bootloader shit https://www.youtube.com/watch?v=FFXRFTrZ2Lk
