# Arch Linux ARM Installation Documentation

**Date:** October 30, 2026  
**Computer:** M2 MacBook Air  
**Virtual Machine:** VMware Fusion  
**Operating System:** Arch Linux ARM

## 1. Setting Up the Virtual Machine

For this assignment, I installed Arch Linux ARM on my M2 MacBook Air using VMware Fusion. Since my Mac uses an ARM processor, I couldn't use the regular Arch Linux ISO. Instead, I downloaded the ARM version of Archboot that was linked in the assignment.

I created a new Linux ARM virtual machine with these settings:

- 4 CPU cores
- 8 GB RAM (originally 4 GB)
- 40 GB virtual hard drive
- NAT networking
- UEFI boot

I initially had trouble getting Archboot to start. The regular boot option kept getting stuck on a message saying the system was still booting. I tried restarting and increasing the RAM, but it didn't fix the issue. I eventually selected the iPXE network boot option, which downloaded the installation environment over the internet. This worked, and I was able to open the root terminal.

Once I was in the terminal, I ran these commands:

`uname -m` — Checked that the architecture was aarch64.

`ping -c 3 archlinux.org` — Made sure the VM had internet access.

`lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS` — Found my 40 GB virtual hard drive.

The drive was listed as /dev/nvme0n1.


## 2. Partitioning the Hard Drive

Next, I partitioned the virtual hard drive. I decided to use two partitions. The first was a 1 GB EFI partition for booting, and the second used the remaining space for the operating system.

Commands used:

`command -v sgdisk` — Checked that the partitioning tool was installed.

`sgdisk --zap-all /dev/nvme0n1` — Cleared the existing partition information.

`sgdisk -n 1:0:+1G -t 1:ef00 /dev/nvme0n1` — Created the EFI partition.

`sgdisk -n 2:0:0 -t 2:8300 /dev/nvme0n1` — Created the Linux partition.

`partx -u /dev/nvme0n1` — Updated the partition information.

`lsblk` — Checked that both partitions were created.

I originally tried using partprobe, but it wasn't installed. I used partx instead, which worked.

After creating the partitions, I formatted them.

`mkfs.fat -F 32 /dev/nvme0n1p1` — Formatted the EFI partition as FAT32.

`mkfs.ext4 /dev/nvme0n1p2` — Formatted the Linux partition as EXT4.

Then I mounted them:

`mount /dev/nvme0n1p2 /mnt` — Mounted the main Linux partition.

`mkdir -p /mnt/boot` — Created the boot directory.

`mount /dev/nvme0n1p1 /mnt/boot` — Mounted the EFI partition.

`lsblk -f` — Verified that everything was mounted correctly.


## 3. Installing Arch Linux

After partitioning the drive, I installed the base Arch Linux ARM system manually using pacstrap. I did not use archinstall or the automated Archboot installer.

Commands used:

`command -v pacstrap` — Checked that pacstrap was available.

`pacman -Sy` — Updated the package databases.

`pacstrap -K /mnt base linux-aarch64 sudo nano networkmanager openssh zsh git base-devel` — Installed the base operating system, ARM kernel, and programs I needed.

`genfstab -U /mnt >> /mnt/etc/fstab` — Created the filesystem configuration.

`cat /mnt/etc/fstab` — Checked the filesystem entries.

`arch-chroot /mnt` — Entered the installed Arch Linux system.

`cat /etc/os-release` — Verified that Arch Linux ARM was installed.

ls -lh /boot — Checked that the kernel and initramfs files were created.

The installation completed successfully. There were a few warnings while generating the initramfs, but it finished successfully.


## 4. Configuring the System and Users

Once Arch was installed, I configured the timezone, language, hostname, and user accounts.

Commands used:

`ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime` — Set the timezone to Central Time.

`hwclock --systohc` — Updated the hardware clock.

`nano /etc/locale.gen` — Opened the language configuration file.

I uncommented en_US.UTF-8 UTF-8.

`locale-gen` — Generated the language settings.

`echo "LANG=en_US.UTF-8" > /etc/locale.conf` — Set the default language.

`echo "arch-cooper" > /etc/hostname` — Set the computer's hostname.

`nano /etc/hosts` — Edited the hosts file.

I added the following entries to the hosts file:

`127.0.0.1 localhost`

`::1 localhost`

`127.0.1.1 arch-cooper.localdomain arch-cooper`

### Problem with Nano

When I first tried opening Nano, I got an error saying:

Error opening terminal: xterm-kmscon

I figured out that the terminal type wasn't supported inside the chroot environment. I fixed it by running:

`export TERM=xterm`

After that, Nano worked normally.

### Creating the User Accounts

The assignment required creating accounts for myself and Codi, both with sudo permissions.

Commands used:

`passwd` — Set the root password.

`useradd -m -G wheel -s /bin/zsh cooper` — Created my account with Zsh and added it to the wheel group.

`passwd cooper` — Set my account password.

`useradd -m -G wheel -s /bin/zsh codi` — Created Codi's account with the same permissions.

`passwd codi` — Set Codi's password.

`EDITOR=nano visudo` — Opened the sudoers file.

In the sudoers file, I uncommented this line to allow wheel group members to use sudo:

`%wheel ALL=(ALL:ALL) ALL`

I also enabled networking and SSH.

`systemctl enable NetworkManager` — Enabled networking at startup.

`systemctl enable sshd` — Enabled the SSH server at startup.

To verify everything, I ran:

`id cooper` — Checked my groups.

`id codi` — Checked Codi's groups.

`getent passwd cooper codi` — Displayed both accounts and their default shells.

`systemctl is-enabled NetworkManager` — Verified networking was enabled.

`systemctl is-enabled sshd` — Verified SSH was enabled.

Both users were members of the wheel group, and both services were enabled.


## 5. Installing the Desktop Environment

The base Arch installation does not include a graphical desktop, so I had to install one myself.

I decided to use LXQt because it is lightweight and doesn't require as many resources as some other desktop environments. I also installed Openbox as the window manager, SDDM for the login screen, QTerminal, and Firefox.

Commands used:

`pacman -Syu` — Updated installed packages.

`pacman -S --needed lxqt sddm xorg-server mesa openbox breeze-icons qterminal firefox` — Installed the desktop environment and other programs.

### Problem with Package Signatures

This was one of the bigger problems I ran into.

When I tried installing LXQt, Pacman kept reporting that packages had invalid signatures or unknown trust. It happened with a large number of packages, so I canceled the installation instead of continuing to delete them.

After checking the system, I found that the Arch Linux ARM signing-key package was missing.

Some commands I used to investigate and fix this were:

pacman-key --init — Initialized the Pacman keyring.

`pacman -Q archlinuxarm-keyring` — Checked whether the ARM keyring package was installed.

ls -l /usr/share/pacman/keyrings/ — Checked which signing-key files were available.

`pacman -Si archlinuxarm-keyring` — Checked the package information.

I then imported and verified the official Arch Linux ARM signing key, trusted it locally, and installed the missing keyring package.

`pacman -Sy archlinuxarm-keyring` — Installed the ARM keyring package.

pacman-key --populate archlinuxarm — Loaded the trusted ARM signing keys.

`pacman -Syu` — Updated the packages again.

After fixing the signing keys, I retried installing LXQt, and it worked. I did not disable signature verification.

### Enabling the GUI

Once everything was installed, I ran:

`systemctl enable sddm` — Enabled the graphical login screen.

`systemctl set-default graphical.target` — Configured the system to boot into the GUI.

`systemctl get-default` — Verified the default boot target.

`systemctl is-enabled sddm` — Verified SDDM was enabled.

`pacman -Q lxqt-session sddm xorg-server openbox firefox` — Verified that the packages were installed.

Everything checked out.


## 6. Configuring the Bootloader

Next, I needed to make sure the VM could boot from its virtual hard drive instead of the installation ISO.

I used systemd-boot since the VM uses UEFI.

Commands used:

ls /sys/firmware/efi/efivars — Checked the UEFI environment.

`bootctl install` — Installed systemd-boot onto the EFI partition.

`mkdir -p /boot/loader/entries` — Created the bootloader entries directory.

`nano /boot/loader/loader.conf` — Edited the bootloader settings.

I put these settings in loader.conf:

`default arch.conf`

`timeout 5`

`console-mode auto`

`editor no`

Next, I got the UUID of my Linux partition.

`blkid /dev/nvme0n1p2` — Displayed the partition UUID.

`ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)` — Saved the UUID to a variable.

I then created the Arch Linux boot entry by entering these lines:

`cat > /boot/loader/entries/arch.conf <<EOF`

`title Arch Linux ARM`

`linux /Image`

`initrd /initramfs-linux.img`

`options root=UUID=$ROOT_UUID rw`

`EOF`

I pressed Enter after the final EOF to finish writing the file.

Then I verified it:

`cat /boot/loader/entries/arch.conf` — Checked the boot entry.

`bootctl list` — Displayed the available boot entries.

`bootctl status` — Checked the bootloader status.

I did get a message saying the system was not booted with EFI or was running inside a container. This happened because I was still using chroot. The bootloader files were installed, and the boot entry appeared correctly.

Finally, I ran:

`exit` — Exited chroot.

`umount -R /mnt` — Unmounted the installed system.

`poweroff` — Shut down the VM.

I disconnected the ISO in VMware Fusion and started the virtual machine again.

This time, Arch Linux successfully booted from the virtual hard drive and brought me to the SDDM login screen.

Both user accounts appeared, and I was able to log into LXQt using my own account.



## 7. Configuring Zsh, Colors, and Aliases

After logging in, I opened QTerminal to finish customizing the shell.

Both user accounts already had Zsh configured as their default shell.

I edited my Zsh configuration file:

`nano ~/.zshrc` — Opened the Zsh configuration.

I added these settings for terminal colors:

`autoload -U colors && colors`

`PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '`

I also added aliases to make common Linux commands easier to use.

`alias ls='ls --color=auto'` — Enables colored directory listings.

`alias grep='grep --color=auto'` — Enables colored grep output.

`alias ll='ls -lah'` — Displays a detailed directory listing.

`alias la='ls -A'` — Lists files including hidden files.

`alias cls='clear'` — Clears the terminal.

`alias update='sudo pacman -Syu'` — Updates packages.

`alias myip='ip -br addr'` — Displays network addresses.

`alias ports='ss -tuln'` — Shows listening ports.

`alias ..='cd ..'` — Goes back one directory.

`alias ...='cd ../..'` — Goes back two directories.

After saving the file, I ran:

`source ~/.zshrc` — Reloaded the configuration.

I tested several aliases, including ll, myip, and ports. They all worked, and the terminal displayed different colors.


## 8. Testing the Installation

After finishing the setup, I tested the system to make sure the assignment requirements were working.

Commands used:

whoami — Checked the current username.

`echo $SHELL` — Verified that Zsh was the default shell.

`sudo whoami` — Tested sudo permissions.

`getent passwd cooper codi` — Displayed both user accounts.

`id cooper` — Checked my group membership.

`id codi` — Checked Codi's group membership.

`systemctl status sshd` — Checked the SSH service.

`systemctl get-default` — Checked the default boot mode.

ip -br addr — Displayed the VM's IP address.

ss -tuln — Checked listening ports.

SSH was active and running, and the system was configured to boot into graphical.target.

The VM's IP address was 192.168.116.143 during testing.

I also opened Firefox to verify that the graphical browser worked and that I could access the internet.


## 9. AUR Package

The assignment also requires installing a package from the Arch User Repository during the walkthrough video.

I already installed the development tools needed for this.

`sudo pacman -S --needed base-devel git` — Installs the tools needed to build AUR packages.

For the video, I will choose an AUR package that supports ARM64, check its PKGBUILD file, and install it using makepkg.

The general commands are:

`git clone https://aur.archlinux.org/PACKAGE.git` — Downloads the selected package's build files.

`cd PACKAGE` — Enters the package directory.

`less PKGBUILD` — Shows the build instructions so I can review them.

`makepkg -si` — Builds and installs the package.

I will complete this part during the walkthrough video.

## 10. Problems I Encountered

Overall, I ran into a few problems while installing Arch Linux.

**1. Archboot wouldn't start normally.**

The default boot option kept getting stuck. I eventually used the iPXE network boot option, which worked.

**2. The partprobe command wasn't available.**

I used partx -u instead to update the partition information.

**3. Nano wouldn't open inside chroot.**

I got an error related to xterm-kmscon. Running export TERM=xterm fixed it.

**4. Pacman wouldn't trust the LXQt packages.**

The Arch Linux ARM keyring package was missing. I installed the correct keyring and fixed the signing-key trust issue before retrying the installation.

**5. The bootloader displayed a warning about EFI.**

This happened because I was using chroot. The bootloader entry was still created, and the VM booted successfully afterward.

Even though I had a few issues, I was able to get Arch Linux installed and working. I also learned more about partitioning, package management, user permissions, bootloaders, and how the different parts of a Linux system work together.

## References

- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Archboot ARM64](https://release.archboot.com/aarch64/latest/iso/)
- [Arch Linux ARM](https://archlinuxarm.org/)
- [Arch Wiki - systemd-boot](https://wiki.archlinux.org/title/Systemd-boot)
- [Arch Wiki - LXQt](https://wiki.archlinux.org/title/LXQt)
- [Arch User Repository](https://aur.archlinux.org/)
