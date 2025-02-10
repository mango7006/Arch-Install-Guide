# Arch Linux Installation Guide

This guide details the installation of Arch Linux for a minimal dual-boot system, serving as a foundation for adding your preferred applications, desktop environments, or window managers. It is written to my personal preferences and assumes basic Linux knowledge and an already acquired install medium booted and ready to type.

Use this guide at your own risk. I am not responsible for any damage to your hardware, software, or data. The installation includes basic applications and security features.

SSH is recommended for this install to copy paste some of the longer commands.

## Wifi connection and SSH setup
```shell
# Connect to WiFi
iwctl
station wlan0 connect <wifi>  # Replace <wifi> with your WiFi SSID
exit
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
cfdisk /dev/nvme0n1  # Replace nvme0n1 with your target disk

# Create partitions:
1G EFI System
'xx'G Linux Filesystem # Replace xx with your desired root partition size
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
pacstrap -K /mnt base base-devel btop curl git neovim dosfstools efibootmgr fastfetch fuse3 grub linux linux-firmware linux-headers man man-db mtools networkmanager openssh os-prober pacman-contrib reflector sudo ufw intel-ucode zsh
```

## Fstab and Chroot
```shell
# Generate filesystem table
genfstab -U /mnt >> /mnt/etc/fstab  # Save the filesystem table to /etc/fstab

# Enter the new system
arch-chroot /mnt

# Confirm chroot environment
fastfetch  # Optional: Verify chroot with system info

# Set root password
passwd  # Create a password for the root user

# Set swapfile and enable it
dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress 
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile # Active swapfile
nvim /etc/fstab
# append at the bottom:
/swapfile none swap defaults 0 0

# Create a new user
useradd -m -g users -G wheel,storage,power,video,audio -s /bin/zsh <username>  # Replace <username> with your desired username
passwd <username>  # Set the password for the new user

# Grant sudo privileges
EDITOR=nvim visudo 
# Uncomment the line:
# %wheel ALL=(ALL:ALL) ALL

# Test the user and update system
su - <username>
sudo pacman -Syu  # Update packages
exit
```

## Timezone setup
```shell
# Set timezone
ln -sf /usr/share/zoneinfo/'<Region/City>' /etc/localtime  # Replace '<Region/City>' with your timezone
# For a list of timezones use
timedatectl list-timezones
hwclock --systohc  # Sync hardware clock
```

## Locale Setup
```shell
# Configure locale
nvim /etc/locale.gen
# Uncomment the line:
# en_US.UTF-8 UTF-8

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
grub-mkconfig -o /boot/grub/grub.cfg  # Generate GRUB configuration
```

## Enable services on startup
```shell
# Enable essential services
systemctl enable bluetooth.service
systemctl enable NetworkManager.service
systemctl enable sshd.service
systemctl enable ufw.service
systemctl enable systemd-timesyncd.service
systemctl enable sddm.service
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
nmcli dev wifi connect <wifi> password '<password>'  # Replace with your WiFi details
ping google.com  # Verify connectivity
sudo pacman -Syu  # Update system
```

## GRUB dualboot setup
```shell
# Configure GRUB for dual-boot with Windows
sudo nvim /etc/default/grub
# Uncomment the line:
GRUB_DISABLE_OS_PROBER=false

sudo grub-mkconfig -o /boot/grub/grub.cfg  # Update GRUB configuration
sudo reboot now  # Reboot system
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

sudo nvim /etc/pacman.conf
# Add the line:
'ILoveCandy'
# Uncomment these lines:
'ParallelDownloads'
'Color'
```

## SSH
```shell
# Secure SSH configuration
sudo nvim /etc/ssh/sshd_config
# Uncomment the line:
# PermitRootLogin
# Change its value to 'no'

# To allow ssh in ufw
sudo ufw enable
sudo ufw allow ssh

# Apply the changes
systemctl restart sshd  # Restart SSH service
```

## TODO
Add section for NVIDIA drivers install and management
Rewrite guide for encryption with LUKS
Make after install guide
Make install script based on this guide
