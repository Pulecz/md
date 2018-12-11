# Arch Linux

This guide should cover basic Arch Linux install without too much details (unless there will be issues with specific part) targeting both Native and QEMU/VirtualBox install.
Target device was [Lenovo T470s](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_T470s), but in other devices not much should be different.

# How to read

Code highlights with # means to run as root, $ as regular user.

***note*** - important note

***tip*** - optionals in current step.

***todo*** - parts to enhance

# Prepare

If you are not familiar with installation, you might wanna try it first in VM, qemu with virt-manager is expected, but these instructions should work for Virtual Box as well.

Download [archlinux iso](https://www.archlinux.org/download/), [dd it](https://wiki.archlinux.org/index.php/USB_flash_installation_media#Using_dd) on some flash drive or load it in virt-manager(QEMU frontend)/VirtualBox.
# Install

## UEFI or BIOS boot process
One of the first choices to make at this point is to consider the [boot process](https://wiki.archlinux.org/index.php/Arch_boot_process), either new UEFI (and GPT for disk) or BIOS (and MBR for disk).

Generally with latest hardware you most probably want to go the newer way with [UEFI](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface), with older hardware with early UEFI implementations, there might be unexpected issues. There are only few extra steps needed compared to BIOS and MBR way, however its important to prepare disk partitions properly with this thought.

Make sure to boot the iso in UEFI or BIOS mode based on your decisions.
Run:

```
$ efivar --list
```
which is something like: 
```
$ ls /sys/firmware/efi/efivars/
```
after archiso boots, to verify if efivars are accessible (UEFI mode) or not (BIOS).

## VM setup

I am using virt-manager to manage VM's using qemu, in there the new VM wizzard you just select the archlinux iso locally or from your images library.
Let the wizard auto-detect to Unknown version, I am not sure what effects other profiles have. VirtualBox should have ArchLinux type in it (also not sure what that affects).

1GB ram is enough even for setup with Desktop Manager, 2 cpus are recommended though and 8GB space for trying things out is also enough.
Make sure to Click 'Customize before install', then select 'Finish'. In overview you can select BIOS or UEFI firmware (boot process).
After 'Begin Installation', firmware and chipset Otherwise you have to edit the vm via virsh or start again

To boot in UEFI via QEMU, check how to do so on [fedora](https://fedoraproject.org/wiki/Using_UEFI_with_QEMU) or [arch](https://wiki.archlinux.org/index.php/libvirt#UEFI_Support), you might have to use ovmf packages from aur (omvf-git) and edit the nvram paths accordingly.

No idea about VirtualBox with this.

## Base

Follow official [Installation guide](https://wiki.archlinux.org/index.php/Installation_guide)(also install.txt on archiso)

***tip1***: to be able to read the install.txt and run commands a tmux session might be useful, sync repos and install tmux, the ramdisk has some space for few more programs.
```
# pacman -Syy
# pacman -S tmux
```

Then ctrl+b and c to create new window, ctrl+b and w to switch between or split the windows and ctrl+b arrows to navigate. See [tmux cheatsheet](https://tmuxcheatsheet.com/).

***tip2***: With VM you probably don't want to control everything via the spice display server and might wanna ssh. Just found on which ip on the default 192.168.122.0 network the VM runs, 
enable sshd, set some root password and connect.

```
# ip a # see e.g. 192.168.122.88
# passwd # some root password
# systemctl start sshd # you might want to check settings in /etc/ssh/sshd_config
```

then on your system:
```
$ ssh -l root 192.168.122.88
```

## Partitioning

Considering you are happy with keyboard layout, boot mode, internet works and clocks its time to prepare storage.

**Disk must be encrypted**, in this guide [LVM_on_LUKS](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS) encryption will be used, see the wiki page overview for more options.

If your disk is not empty see [Driver Preparation on wiki](https://wiki.archlinux.org/index.php/Dm-crypt/Drive_preparation) and zap the drive.

If you use GPT (which you probably should no matter the boot process) and grub, but using BIOS boot process,  note [this important fact](https://wiki.archlinux.org/index.php/GRUB#GUID_Partition_Table_.28GPT.29_specific_instructions) when partitioning the drive. At least +1MB partition with EF02 type code is needed.

Otherwise in UEFI mode you will need to create EFI partition, which should have at least 200MB with EF00 type code.

Since encryption is used the /boot can't be encrypted on boot, so that needs to be created as well. make it at least 256MB, if you plan to muse more kernels, make it larger since one can be around 60MB.
There is also option to make [/boot encrypted](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Encrypted_boot_partition_.28GRUB.29) as well.

I use gdisk for partitioning, make sure you are editing the correct drive.
* Make the +1M BIOS boot partition(ef02) (for BIOS boot) or +200M EFI system(ef00) (for UEFI boot).
* Make boot partition, at least +256M, can be regular Linux filesystem (8300).
* Then rest of the space is for Linux LVM (8e00).
* Save the changes and mkfs.vfat on EFI system (BIOS boot does not need a filesystem), mkfs.ext4 on boot partition.
* Then continue with [LVM_on_LUKS](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS) encryption how-to.
The *Configuring mkinitcpio* and *Configuring the boot loader* steps do after you can chroot to new system.

***todo1***: this might be tricky at first look and asciinema video of partitioning might be useful.

### Install packages

Mount /dev/mapper/smthing-root /mnt as root (smthing being the name of volume group) and unecrypted boot to /mnt boot and run swapon on /dev/mapper/smthing-swap.
For UEFI: make dir in /mnt/boot/efi and mount efi partition there.
Then verify internet connectivity and correct time with timedatectl (ntp is easy), you might also want to select closest mirrors in /etc/pacman.d/mirrorlist for bit more faster downloads.

Then sync the repos with:
```
# pacman -Syy
```

And do the main install with base and base-devel for making pkgs.

```
# pacstrap /mnt base base-devel
```

You will see optional dependencies for some packages, which you can always check later with pacman -Qi $pkg and some symlink creations for services when systemd installs, nothing super important. Everything is already logged in var/log/pacman.log on the /mnt.

***note1***: base-devel group is optional, but since you are probably going to build your own packages the gcc and other tools in base-devel group are required, see [groups overview](https://www.archlinux.org/groups/) for details which packages are in base and base-devel.

### Setting things up

#### Base

Now use genfstab script as Installation guide instructs and double check you have all root, boot, boot/efi, efivars and swap and other partitions ok in the /mnt/etc/fstab and run arch-chroot script to get into the installed system.

You might want to make sure the efivars are mounted as read only after you installed grub, see this [warning](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface#Mount_efivarfs).

You will probably want to edit pacman mirrors again and install basic stuff like so:

```
# pacman -S zsh zsh-grml-config vim tmux sudo mc htop grub efibootmgr
```
* zsh - smart shell
* grml-zsh-config - grml's zsh config (the one archiso uses)
* vim - improved vi
* tmux - better screen
* sudo - for "admin" stuff
* ranger - one way for file mght + installs python as dependency
* mc - other way for file mgmt, blue screen, midnight commander, m602!
* htop - better top
* grub - for booting
* efibootmgr - creates bootable .efi stub entries used by the GRUB installation scrip

Set timezone, edit locale.gen and run locale-gen, create locale.conf and setup network via [dhcpcd](https://wiki.archlinux.org/index.php/Dhcpcd) or [systemd-networkd](https://wiki.archlinux.org/index.php/systemd-networkd).

Before running mkinitcpio edit its config (/etc/mkinitcpio.conf) according to LVM_on_LUKS wiki so it opens the crypted partition on boot.

Then edit /etc/default/grub and add to GRUB_CMDLINE_LINUX:
"cryptdevice=UUID=*device-UUID*:cryptolvm root=/dev/mapper/MyVol-root"

**Note** the cryptolvm is the name of the container you used in cryptsetup open and MyVol-root is the logical volume name you used in the setup.

Replace the *device-UUID* with one from:

```
# ls /dev/disk/by-uuid/ -l
```

Use the physical UUID of the encrypted partition.

**tip**: save the output of ls to some file, edit it to be just the UUID of the physical drive you encrypted and then while editing /etc/default/grub use vim command :r *path_to_file_with_UUID* to *paste* in the UUID

Then run:
```
# mkinitcpio -p linux
```

Which select linux preset (only one in default) and creates initframs in /boot.

#### Boot
In UEFI mode make sure the EFI partiion is mounted in /boot/efi, if you forgot it to mount it before running genfstab script, run it again.

Then run:

```
# grub-install $dev
# grub-mkconfig -o /boot/grub/grub.cfg
```
Where $dev is /dev/sda or in Lenovo T470s case the ssd /dev/nvme0n1.
This will create configuration for grub based on those defaults with cryptdevice, you can ignore lvmetad warnings, this is normal for lvm.
If you wrote incorrect UUID in the defaults and system fails to boot, you will have to edit the defaults and make config again.

***note2***: there are more options for [grub-install](https://wiki.archlinux.org/index.php/GRUB#Installation_2) for this case defaults are ok.

Change root password, then [create regular user in wheel group](https://wiki.archlinux.org/index.php/users_and_groups#User_management), and allow wheels group in sudoers

```
# useradd -m -g wheel -G power,audio,games -s /usr/bin/zsh user
```

```
# EDITOR=vim visudo
```

so the user in group is "admin". 

Done, now logoff from chroot and reboot to test. If you fail to boot, boot archiso again, open crypted partition, mount and fix things.

# Installed, next steps

After logging in do a sync and update:

```
$ sudo pacman -Syu
```

Note that if linux (kernel) updates, the kernel modules will not work anymore and you will need to **reboot** or install the old linux kernel from /var/cache/pacman/pkg.

## X Server
For workstation you will probably need this for some clickity things.
note: (to be replaced with wayland and sway instead of i3)

Install:
* i3 - maybe too minimalistic window manager, feel free to install cinnamon, lxde or [whatever](https://wiki.archlinux.org/index.php/Desktop_environment), only difference will be in how its started in .xinitrc
* dmenu - application starter for i3
* xorg-server - main X
* xorg-xinit - for starting X
* terminator - cool terminal so i3-sensible-terminal can launch something when you hit modifier+Enter

```
# pacman -S i3 dmenu xorg-server xorg-xinit terminator
```

Select all the defaults (keep hitting enter)

Prepare .xinitrc, in your home folder:
```$ cp /etc/X11/xinit/xinitrc .xinitrc$ chmod u+x .xinitrc
```$ vim .xinitrc```

Remove the twm & stuff from the bottom and replace with programs that will get started when X starts:

for example:
```
terminator &
exec i3
```

Or just "exec i3" is enough if you don't want anything autostarting.


### Drivers

Drivers are required for X to work, 

#### VM
```
pacman -S xf86-video-vesa
```

#### Native

For Lenovos most probably xf86-video-intel

Test it
```
$ startx
```

If you don't like running startx after logging in, install some [Display manager](https://wiki.archlinux.org/index.php/Display_manager) or setup [autostart](https://wiki.archlinux.org/index.php/Xinit#Autostart_X_at_login).

## Recommended steps in VirtualBox guest

**tl;dr:** Install virtualbox-guest-utils and choose virtualbox-guest-modules-arch, because we use default linux kernel. Then enable vboxservice.service and reboot.

For running arch in VirtualBox and using shared clipboard and other features follow [this steps on wiki](https://wiki.archlinux.org/index.php/VirtualBox#Installation_steps_for_Arch_Linux_guests).

After that you should be able to select larger resolution from VirtualBox View > Virtual Screen option and launch VBoxClient for clipboard share and etc.

Add "VBoxClient --clipboard &&" to .xinitrc before exec i3 (or exec gnome-session or whatever), or choose an [alternative](https://wiki.archlinux.org/index.php/autostarting).

In VirtualBox main preferences(ctrl+g) create new Host-Only network, defaults are OK, unless 192.168.56.x network bothers you.
Then add the new network as another adapter to your machine, while its off.

## ssh

Rather then shared folders, easier is to setup sshfs

```
# pacman -S sshfs
```
Start or enable sshd, mkdir ~/share and on your system run:

```
sshfs $vm_ip:/home/$user/share ~/sharefs
```

To mount the remote share folder as sharefs in your homefolder.

# What is next

Read [General Recommendations](https://wiki.archlinux.org/index.php/general_recommendations)

Main recommendations:
* Install [polkit](https://wiki.archlinux.org/index.php/Polkit) - allows non-remote users to reboot or shutdown without sudo (works after reboot)
* ...

***todo2***: dotfiles, xbindkeys for i3, etc...

## Security
Having disk encrypted is first step, its expected to have nice and long password for encryption, root and your user(s), but you might want read more on [wiki](https://wiki.archlinux.org/index.php/Security).

## Fonts
Depending on your desktop environment you might already have something nice, but if not pick one from:
```
$ pacman -Ss ttf
```

ttf-dejavu is fine, change it in ~/.config/i3/config or in terminator's preferences if you need to.

