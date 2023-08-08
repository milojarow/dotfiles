
# Milo's guide to install archlinux
1. ### First things first, the **keyboard**
> `ls /usr/share/kbd/keymaps/**/*.map.gz`

Pick the one that suits your keyboard with 

> `loadkeys us-acentos.map.gz ` 

or whatever the map you choose.

---

2. ### Connect to the internet
If you're through ethernet then you should already be connected, check it running a ping
> `ping google.com`

to stop it just hit `ctrl+C`

To connect through wifi you'll use the **iwctl** utility
> `iwctl`

> `device list`

> `station DEVICE scan`

> `station DEVICE get-networks`

> `station DEVICE connect *SSID*`

It'll prompt for passwod and that's it.

---

3. ### Time system
> `timedatectl set-ntp true`

If you getting error with this line try restarting the daemon: `$ systemctl restart systemd-timesyncd`

---

4. ### Partition disk with fdisk (as arch wiki recommends)
> `fdisk -l`

to list devices
> `fdisk /dev/sda`

to select the main device.

First thing to do is to create a new label, usually a gpt one
> `g`

this creates a gpt label
> `n`

this creates a new partition.

Partition size can be set by `+550M` (boot partition), `+2G` (swap partition).
>`t`

to set the type of each partition

> `w`

to write changes.

---

5. ### Format the partitions you just created
> `mkfs.fat -F32 /dev/sda1`

> `mkswap /dev/sda2`

> `swapon /dev/sda2`

> `mkfs.ext4 /dev/sda3`

---

6. ### Montar el sistema en la partición linux filesystem
> `mount /dev/sda3 /mnt`

---

7. ### Instalar el kernel
> `pacstrap /mnt base linux linux-firmware`

---


8. ### Generate filesystem table
> `genfstab -U /mnt >> /mnt/etc/fstab`


---

9. ### Entrar a nuestro recién creado sistema como root
> `arch-chroot /mnt`

---

10. ### Set timezone
> `ln -sf /usr/share/zoneinfo/America/Monterrey /etc/localtime`

---

11. ### Set hardware clock
> `hwclock --systohc`

---

12. ### Set your locale
To do this you need a text editor so install vim
> `pacman -S vim`

Now to edit the file run:
> `vim /etc/locale.gen`

Usually the one line you have to uncomment is `en_US.UTF-8 UTF-8` save the changes with `ZZ` and run the following:
> `locale-gen`

>`localectl set-locale LANG=en_US.UTF-8`

---

13. ### Set the hostname (name of your computer)
> `vim /etc/hostname`

Write in small caps whatever name you want to give to your pc, let's say for example that we named our pc `athenea`

---

14. ### Set the local domain ip address
> `vim /etc/hosts`

in here you'll have to add this lines:
````bash
127.0.0.1   localhost
::1         localhost
127.0.1.1   athenea.localdomain athenea
````

---

15. ### Set your root password
> `passwd`

---

16. ### Create your user and give it a password
> `useradd -m youruser`

Replace *youruser* with the actual user
> `passwd youruser`

Run the following command to add your user to the basic groups
> `usermod -aG wheel,audio,video,optical,storage,lp youruser`

---

17. ### Give your user access to sudo
> `pacman -S sudo `

this installs sudo
> `visudo`

this opens the sudo config file, you have to search for two lines and uncomment those lines, well if you want for sudo to ask for password everytime leave the second line commented.
> `%wheel ALL=(ALL) ALL`

this is the first line
> `%wheel ALL=(ALL) NOPASSWD: ALL`

this is the second line.

---

18. ### Now to install grub
> `pacman -S grub`

---

19. ### Install EFI
> `pacman -S efibootmgr dosfstools os-prober mtools`

> `mkdir /boot/EFI`

> `mount /dev/sda1 /boot/EFI`

> `grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck`

> `grub-mkconfig -o /boot/grub/grub.cfg`

---

20. ### Make sure you'll have internet at the reboot
> `pacman -S networkmanager`

> `systemctl enable NetworkManager`

---

21. ### Exit the system and reboot
> `exit`

>  `umount -l /mnt`

> `reboot`

---

22. ### Now you can remove the usb

---

23. ### First login and connect to internet
> `nmcli device wifi list`

> `nmcli device wifi connect SSID password PASSWORD`

---

24. ### Install some basic things
> `sudo pacman -S git base-devel`

---

25. ### Install your video driver
First to identify your graphics card run
> `lspci -v | grep -A1 -e VGA -e 3D`

Then install the appropiate driver, i.e. if your graphic card is intel then run:

> `sudo pacman -S xf86-video-intel`

If you want to see some examples for AMD or nVidia cards then [click here](https://wiki.archlinux.org/title/Xorg#Installation)

---

28. ### Tweak your pacman.conf
> `vim /etc/pacman.conf`

in this file activate the **color** option for pacman to be colorized and under *misc* options write `ILoveCandy` to change the pacman progress bar to the atari game favorite dot eater.

---

27. ### Install an AUR helper
The one I recommend is the AUR helper written in RUST, its called **PARU**.
> `git clone https://aur.archlinux.org/paru.git`

> `cd paru`

> `makepkg -si`


---

28. ## From here on you can install whatever desktop you want.
Most common desktop environments are **KDE**, **GNOME**, [**XFCE4**](https://wiki.archlinux.org/title/Xfce). Being kde the heaviest and xfce4 the lightest of the three. If you prefer lighter options you can choose a *window manager* like **fluxbox**, **ICEwm**, **openbox**, etc.

**[Here](https://www.youtube.com/watch?v=FfGzL9zhPoU) is the two min video on how to install XFCE4*

The difference is, desktop environments are packages, they come with a lot of tools, some of those tools maybe you'll never use. With windows managers you just get that: the window manager. Withouth any extras, the extra things you need you'll have to install them through pacman.

[Window managers](https://wiki.archlinux.org/title/Window_manager) are classified by the way they manage windows, the types are: **stacking**, **tiling** and **dynamic**.

I'll be using a dynamic window manager, one of these three: **awesome**, **dwm** or **xmonad**.


---

29. ### Installing window manager [leftwm](https://wiki.archlinux.org/title/LeftWM)

Once you have your graphic interface you need to make sure you have 
1. Web browser (I'll be using **paru** to install *brave browser*)
1. Terminal emulator (I'll be using **paru** to install **alacritty**)
1. Nitrogen is for wallpapers
1. Picom compositor
1. Text editor (vim which we already installed)
1. The actual **W**indow **M**anager
>`sudo pacman -S xorg xorg-xinit nitrogen picom alacritty `

+ Fork says you should also include `libx11`, `libxinerama`, `libxft`, `webkit2gtk`.

Now let's download from the AUR
>`paru -S leftwm dmenu brave-bin`


---

30. ### Configure the xinit

You can find the sample file at /etc/X11/xinit/xinitrc
> `cp /etc/X11/xinit/xinitrc ~/.xinitrc`

>`vim .xinitrc`

Go to the end of that doc and add:
````bash
nitrogen --restore &
picom &
exec dbus-launch leftwm 
````
reboot > login > run `$ startx`


---

31. ### Adjust resolution
>`xrandr`

>`xrandr -s 1680x1050`


---

32. ### Script to automate the `startx`
>`vim ~/.bash_profile`

At the end of the doc insert:
>`[[ $(fgconsole 2>/dev/null) == 1 ]] && exec startx -- vt1`

reboot and it should automatically startx


---


# Archlinux configuraciones

---

# Trucos
