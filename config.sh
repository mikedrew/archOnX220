#!/bin/bash

echo Mike\'s x220 install script
echo 
echo

echo step 1:
#dd if=/dev/zero of=/dev/sda bs=512 count=1

echo step 2:
yes | parted /dev/sda mklabel gpt
parted /dev/sda mkpart ESP fat32 1MiB 513MiB set 1 boot on
parted /dev/sda mkpart primary ext4 513MiB 20.5GiB
parted /dev/sda mkpart primary linux-swap 20.5GiB 24.5GiB
parted /dev/sda mkpart primary ext4 24.5GiB 100%

echo step 3:
yes | mkfs.fat -F32 /dev/sda1
yes | mkfs.ext4 /dev/sda2
yes | mkswap /dev/sda3
yes | swapon /dev/sda3
yes | mkfs.ext4 /dev/sda4

echo step 4:
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
mkdir -p /mnt/home
mount /dev/sda4 /mnt/home

echo step 5:
arch-chroot /mnt echo Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch > /etc/pacman.d/mirrorlist
pacstrap -i /mnt base base-devel

echo step 6: configure fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

echo step 7: language and location settings
arch-chroot /mnt echo en_US.UTF UTF-8 > locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo LANG=en_US.UTF-8 > /etc/locale.conf
#arch-chroot /mnt export LANG=en_US.UTF-8

echo step 8: time zone
arch-chroot /mnt ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
arch-chroot /mnt hwclock --systohc --utc
hostnamectl set-hostname beta

echo step 9: configure repositories
arch-chroot /mnt sed -i 's/# Include = //etc//pacman.d//mirrorlist/Include = //etc//pacman.d//mirrorlist/' /etc/pacman.conf
arch-chroot /mnt pacman -Sy

echo step 10: create users
arch-chroot /mnt pacman --noconfirm -S sudo bash-completion
arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

#arch-chroot /mnt echo root:test | chpasswd
#arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash mike
#arch-chroot /mnt echo mike:test | chpasswd

echo step 11: bootloader

arch-chroot /mnt pacman --noconfirm -S grub efibootmgr

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck

arch-chroot /mnt mkdir -p /boot/efi/EFI/boot
arch-chroot /mnt cp /boot/efi/EFI/arch_grub/grubx64.efi /boot/efi/EFI/boot/bootx64.efi

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo step 12: network

arch-chroot /mnt pacman --noconfirm -S networkmanager

arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl start NetworkManager.service

arch-chroot /mnt systemctl enable dhcpcd@enp0s25.service
arch-chroot /mnt systemctl start  dhcpcd@enp0s25.service

