## Installation 
### WiFi connection and SSH setup
Setup WiFi with `iwctl` (disregard if using ethernet)
```shell
iwctl station wlan0 connect <SSID>
```
Check connectivity
```shell
ping -c 3 google.com  
```
Setup `ssh`, if you do not plan on using ssh for this guide, you can skip this step
```shell
passwd
ip addr
```
### Partitioning
Get the name of the disk to format/partition:
```shell
lsblk
```
The name should be something like `/dev/sda` or `/dev/nvme0n1`
Use common sense throughout this guide and swap them where necessary.
Now partition the disk using `cfdisk`:
```shell
cfdisk /dev/nvme0n1
```
Partition 1 should be an EFI boot partition of 1GB.  `/dev/nvme0n1p1`
Partition 2 should be a Linux LVM partition. `/dev/nvme0n1p2`
The 2nd partition can take up the full disk or only a part of it (this is up to you.)

Once partitioned you can format the boot partition (the LVM partition needs to be encrypted before it gets formatted)
```shell
mkfs.fat -F32 /dev/nvme0n1p1
```
### Encryption
Now, encrypt the disk and set a password, then open it and format it for use
A guideline for the password: 4-6 random words with no correlation to each other.
```shell
cryptsetup luksFormat /dev/nvme0n1p2

cryptsetup open --type luks /dev/nvme0n1p2 cryptlvm

pvcreate /dev/mapper/cryptlvm

vgcreate volume /dev/mapper/cryptlvm

lvcreate -l 100%FREE volume -n root

mkfs.ext4 /dev/volume/root
```
Mount the volumes and file systems:
```shell
mount /dev/volume/root /mnt
mount -m /dev/nvme0n1p1 /mnt/boot
```
### Installation
Install base package, linux, firmware, lvm2 and utilities:
```shell
pacstrap -K /mnt base base-devel cryptsetup dosfstools efibootmgr fuse3 git grub linux linux-firmware linux-headers lvm2 man man-db mtools networkmanager openssh pacman-contrib reflector sudo ufw zsh neovim btop fastfetch gdu curl intel-ucode btop fastfetch intel-media-driver
```
Change `intel-ucode` to `amd-ucode` if you have an AMD CPU, and remove `intel-media-driver` Feel free to add or remove any packages you might need/don't need.
Generate `fstab`:
```shell
genfstab -U /mnt >> /mnt/etc/fstab
```
`chroot` into system:
```shell
arch-chroot /mnt
```
Set a root password
```shell
passwd
```
### swapfile
```shell
dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress 
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' | tee -a /etc/fstab
```
### Create new user
Create a new user and set password. Change `<username>`
```shell
useradd -m -g users -G wheel,storage,power,video,audio -s /bin/zsh <username>
passwd <username>
```
Grant `sudo` privileges to created user; run `EDITOR=nvim visudo` and uncomment:
```text
%wheel ALL=(ALL:ALL) ALL
```
### Timezone setup
Set your timezone, replace `<Region/City>` with your timezone.
```shell
ln -sf /usr/share/zoneinfo/<Region/City> /etc/localtime
```
For a list of time zones. You can search for time zones with `/`
```shell
timedatectl list-timezones
```
Sync set timezone to hardware clock
```shell
hwclock --systohc
```
### Locale and host setup
Generate standard American English locale
```shell
sed -i '/^#en_US\.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
```
Set a hostname for your new system. Change `<hostname>` and `$host` accordingly.
```Shell
echo '<hostname>' >> /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$host.localdomain $host" | tee -a /etc/hosts
```
### mkinitcpio hooks
Because the filesystem is on LVM we will need to enable the correct `mkinitcpio` hooks.
Edit `/etc/mkinitcpio.conf`. Look for the HOOKS variable and add the `encrypt` and `lvm2` hooks at the end: (ORDER DOES MATTER)
```text
HOOKS=(... ... ... ... encrypt lvm2)
```
Regenerate the `initramfs:
```shell
mkinitcpio -P linux
```
### Install GRUB
Install a bootloader:
```shell
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```
In `/etc/default/grub` change `GRUB_CMDLINE_LINUX_DEFAULT` to look like this:
(don't forget to change the disk paths!)
```shell
GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=/dev/nvme0n1p2:luks root=/dev/volume/root loglevel=3 quiet"
```
If you want to dual-boot in this setup, you should install `os-prober` and uncomment another line in `/etc/grub/default`, like this:
```shell
pacman -S os-prober
sed -i '/^#GRUB_DISABLE_OS_PROBER=false/s/^#//' /etc/default/grub
```
You can also reduce or remove the timeout to immediately boot into arch by setting the timeout time to 0 like this:
```shell
sed -i 's/^GRUB_TIMEOUT=5$/GRUB_TIMEOUT=0/' /etc/default/grub
sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
```
If you want to see the GRUB menu again, hold the ESC key during boot.
After all that you will need to generate the GRUB config
```shell
grub-mkconfig -o /boot/grub/grub.cfg
```
### Enable services on startup
```shell
systemctl enable NetworkManager sshd ufw systemd-timesyncd reflector.timer
```
### Unmount and reboot
You  are now done with a minimal install. If you want to you can further customize your system, but otherwise run the following commands to shutdown:
```shell
exit
umount -lR /mnt
shutdown now
```
Don't forget to remove the install medium before rebooting into the new system.
## After install (optional)
### WiFi connection
Connect to WiFi using `nmcli` (disregard if using ethernet)
```shell
nmcli d wifi connect <SSID> password "<password>"
```
If you don't know what networks are around, you can run the following command to list networks:
```shell
nmcli d wifi list
```
### AUR helper install
Install the `paru` AUR helper to install packages from the Arch User Repository
```shell
mkdir -p ~/gits/; cd ~/gits
git clone https://aur.archlinux.org/paru.git; cd ~/gits/paru/
makepkg -si
```
### Pacman mirrors
Run reflector to sort the fastest mirrors for you. (This will take around 6-7 minutes and is optional.)
```shell
sudo reflector --verbose -l 200 -n 20 -p http,https --sort rate --save /etc/pacman.d/mirrorlist
```
### Enable UFW
```shell
sudo ufw enabale
sudo ufw default deny incoming
```
### Optional ssh security practices
Disable root login for ssh and change the ssh port from 22 to another port:
```shell
echo -e "PermitRootLogin no\nPort 2222" | sudo tee -a /etc/ssh/sshd_config
```
Whenever you would like to ssh into this device, use the `-p 2222` flag to specify the open port
You also need to open the port in UFW like this:
```shell
sudo ufw allow 2222
```
### Set pacman.conf
edit the `/etc/pacman.conf` file and under `[options]`, change/add the following:
```text
Color
ParallelDownloads = 15
ILoveCandy
```
If you also want steam games and other 32bit applications, uncomment the following near the bottom of the file:
```
[multilub]
Include = /etc/pacman.d/mirrorlist
```
Then run `sudo pacman -Syu` to refresh the database.
### Change logind.conf
This makes the poweroff key not immediately power down on accidental press.
```shell
sudo sed -i 's/^#\?HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
```
### Display manager
For the display manager you have a lot of options, like `gdm`, `lightdm`, `sddm`, `ly` and a lot more. To install one of these, just use the following commands and change their respective names:
```shell
sudo pacman -S <dmanager>
systemctl enable <dmanager>.service
```
e.g.
```shell
sudo pacman -S ly
systemctl enable ly.service
```
