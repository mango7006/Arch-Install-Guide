# Arch Linux Installation Guide

This guide details the installation of Arch Linux for a minimal dual-boot system, serving as a foundation for adding your preferred applications, desktop environments, or window managers. It is written to my personal preferences and assumes basic Linux knowledge and an already acquired install medium booted and ready to type.

Use this guide at your own risk. I am not responsible for any damage to your hardware, software, or data. The installation includes basic applications and standard security features.

SSH is recommended for this install to copy and paste some of the longer commands.

## WiFi connection and SSH setup
```shell
# Connect to WiFi
iwctl station wlan0 connect '<wifi>'  # Replace <wifi> with your WiFi SSID
ping google.com  # Check internet connectivity

# Setup SSH
passwd # set a password to allow SSH
ip addr # Show ip for SSH
```

## Disk Partitions
```shell
# Check disk layout
lsblk  # View all block devices and partitions

# Partition the disk
cfdisk /dev/nvme0n1  # Replace nvme0n1 with your target disk like /dev/sda

# Create partitions:
800M EFI System
'xx'GiB Linux Filesystem # Replace xx with your desired root partition size
lsblk

# Format partitions
mkfs.fat -F32 /dev/nvme0n1p<X>  # Format EFI partition (replace <X>)
mkfs.ext4 /dev/nvme0n1p<Y>  # Format root partition (replace <Y>)

# Mount partitions
mount /dev/nvme0n1p<Y> /mnt  # Mount root partition
mount -m /dev/nvme0n1p<X> /mnt/boot  # Mount EFI partition

lsblk  # Verify mounted partitions
```

## Installing system
```shell
# Install essential packages
pacstrap -K /mnt base base-devel btop curl dosfstools efibootmgr fastfetch ffmpeg fuse3 git grub linux linux-firmware linux-headers man man-db mtools networkmanager openssh os-prober pacman-contrib reflector sudo ufw nvim intel-ucode amd-ucode
```

## Fstab and Chroot
```shell
# Generate filesystem table
genfstab -U /mnt >> /mnt/etc/fstab  # Save the filesystem table to /etc/fstab

# Enter the new system
arch-chroot /mnt

# Confirm chroot environment
fastfetch  # Verify chroot with system info

# Set root password
passwd  # Create a password for the root user

# Set swapfile to 4GiB and enable it
dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress 
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile # Active swapfile
echo '/swapfile none swap defaults 0 0' | tee -a /etc/fstab

# Create a new user
useradd -m -g users -G wheel,storage,power,video,audio -s /bin/bash <user>
passwd <user>  # Set the password for the new user

# Grant sudo privileges
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Test the user and update system
su - <user>
sudo pacman -Syu  # Update packages
exit
```

## Timezone setup
```shell
# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc  # Sync hardware clock

# For a list of timezones use
timedatectl list-timezones
```

## Locale Setup
```shell
# Configure locale
sed -i '/^#en_US\.UTF-8 UTF-8/s/^#//' /etc/locale.gen

locale-gen  # Generate the locales

# Set system locale
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf  # Use your chosen locale

# Set hostname
echo '<hostname>' >> /etc/hostname  # Replace <hostname> with your computer's name
```

## GRUB Bootloader setup
```shell
# Install GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# Configure GRUB for dual-boot with Windows
sed -i '/^#GRUB_DISABLE_OS_PROBER=false/s/^#//' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg  # Update GRUB configuration
```

## Enable services on startup
```shell
systemctl enable NetworkManager.service && \ systemctl enable sshd.service && \ systemctl enable ufw.service && \ systemctl enable systemd-timesyncd.service
```

## Unmount and shutdown
```shell
# Exit chroot and unmount
exit  # Leave the chroot environment
umount -lR /mnt  # Unmount all partitions
shutdown now  # Shutdown the system
```
# After Installation
## Wifi connection
```shell
# Connect to WiFi and update system after reboot
nmcli dev wifi connect '<SSID>' password '<password>'  # Replace with your WiFi details
ping google.com  # Verify connectivity
sudo pacman -Syu  # Update system
```

## AUR helper install
```shell
# Install an AUR helper (paru in this case)
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si  # Build and install the package
# If prompted, choose 'rustup' for Rust management
# If an error occurs, run:
rustup default stable
# Then retry:
makepkg -si
```

## Pacman mirrors and config
```shell
# Optimize Arch mirrors and configure pacman
sudo reflector --verbose -l 150 -n 20 -p http --sort rate --save /etc/pacman.d/mirrorlist
# Reflector will sort mirrors by speed and update the mirrorlist.

# Edit the /etc/pacman.conf file for speed and style
sudo echo 'ILoveCandy' >> /etc/pacman.conf && \
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf && \
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
```

## UFW and SSH
```shell
# To allow ssh in ufw
sudo ufw enable
sudo ufw allow ssh

# Apply the changes
systemctl restart sshd  # Restart SSH service
```

## GUI installation
```shell
# optional GUI apps if you want
sudo pacman -Syu pavucontrol blueman feh vlc nm-connection-editor network-manager-applet firefox
```


```shell
# These are optional packages because they technically go against a minimal install, but everyone uses them
bluez bluez-utils 
brightnessctl 
pipewire pipewire-audio pipewire-pulse wireplumber
```

```shell
systemctl enable bluetooth.service
```




## TODO
Rewrite for fdisk instead of cfdisk
Finish GUI install
