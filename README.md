# Build an Image for the Sipeed Lichee RV

Automatic building of a Debian image for the Sipeed Lichee RV Risc-V single board computer. This project uses Docker for the heavy lifting. This means that bootable disk images can be created on any kind of OS (windows, mac or Linux).

Author: Tim Molteno (tim@molteno.net)

## Pre-built images

These can be downloaded from [here](https://github.com/tmolteno/d1_build/releases), and installed using any standard disk imaging utility (dd on linux).

### Username, Password and WiFi

The username is rv, with password lichee. The root password is licheerv. In these images you can use nmcli or [nmtui](https://www.tecmint.com/nmtui-configure-network-connection/) command line tools to set up a wifi connection

    sudo nmcli dev wifi connect "MyWifi" password "my-password"

This will connect to a notwork called "MyWifi", with password "my-password"

## Ethernet

The builds currently contain a handful of standard USB Ethernet drivers, including those for Realtek 100M adapters. Upon connection, Debian will automatically configure the USB device and connect to the network, with no need for manual configuration.

## How to build your own image

This is intended to be used on a debian system with docker, and docker-compose installed. Modify the parameters of the build in the file docker-compose.yml such as kernel version and board target. Then issue.

    docker-compose build
    docker-compose up

The build stage does a lot of the work (compiling kernels e.t.c and takes quite a bit of time). Once this is done it will be cached by Docker, so should run faster. The execution stage (docker-compose up) runs a script that does more of the image building using a series of scripts (build.sh, create_image.sh).

This should produce a disk image in the directory ./lichee_rv_dock/ located in the same folder as the repository.

There is a Makefile that automates this, and you can just type

    make

And the image will be built. This image can be transferred to an SD card using dd (on Linux)

    sudo dd if=licheerv.img of=/dev/sdX bs=4M

where /dev/sdX is the name of the sdcard device (check dmesg output).


### Clean Build

Just issue,

    docker-compose build --no-cache

And everything will be rebulid (new kernel download e.t.c.). This is very slow (on my laptop)

## NOTES

* Do NOT fix the GPT if you resize the root partition (second partition). This will cause boot errors.
* WiFi on the RV 86 Panel does not work as the xr829 driver is missing. Issue here (https://github.com/tmolteno/d1_build/issues/7)
* The tiny LCD screen is not going yet. (https://github.com/tmolteno/d1_build/issues/8)
   

## Links

* https://manpages.ubuntu.com/manpages/bionic/man1/multistrap.1.html
* https://linux-sunxi.org/Mainline_Debian_HowTo
* https://linux-sunxi.org/Allwinner_Nezha#U-Boot
* https://andreas.welcomes-you.com/boot-sw-debian-risc-v-lichee-rv
* https://github.com/sehraf/riscv-arch-image-builder/blob/main/1_compile.sh
* https://github.com/DongshanPI/NezhaSTU-ReleaseLinux/tree/master/.github/workflows

## How Booting Works

### First Boot Stage
* The first sun20i_d1_spl code is loaded. It looks for a u-boot toc1 file from the mmc drive (sd-card reader). This file is written directly onto the first part of the SDcard (not in a filesystem)
* The TOC file contains a list of parts of the system. These are (in order) opensbi, dtb, u-boot.
These parts are loaded into memory.

### Second Boot stage

* The OpenSBI runs as the second boot stage. It is responsible for loading U-Boot

### Third boot stage

This is U-Boot. It mounts the boot partition on the mmc drive. Reads a file called 'boot.scr' and executes this script. This loads the kernel (Image.gz), uncompresses it and starts things running.


