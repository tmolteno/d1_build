# Build an Image for the Sipeed Lichee RV

We Docker to automate the building of a Debian image for the Sipeed Lichee RV Risc-V single board computer. This means that bootable disk images can be created on any kind of OS (windows, mac or Linux).

Author: Tim Molteno (tim@molteno.net)

## Pre-built images

These can be downloaded from [here](https://home.4i.nz/s/wF9mq5aZkn4JHxL), and installed using any standard disk imaging utility (dd on linux).

## How to use

This is intended to be used on a debian system with docker, and docker-compose installed.

    docker-compose build
    docker-compose up

The build stage does a lot of the work (compiling kernels e.t.c and takes quite a bit of time). Once this is done it will be cached by Docker, so should run faster. The execution stage (docker-compose up) runs a script that does more of the image building using a series of scripts (build.sh, create_image.sh).

This should produce a disk image in the directory ~/port/ of the user that ran the script.

There is a Makefile that automates this, and you can just type

    make

And the image will be built. This image can be transferred to an SD card using dd (on Linux)

    sudo dd if=licheerv.img of=/dev/sdX bs=4M

where /dev/sdX is the name of the sdcard device (check dmesg output).

### User & Password

The username is rv, with password lichee. The root password is licheerv. In these images you can use nmcli or nmtui command line tools to set up a wifi connection

    sudo nmcli dev wifi connect "MyWifi" password "my-password"

This will connect to a notwork called "MyWifi", with password "my-password"

### Clean Build

Just issue,

    docker-compose build --no-cache

And everything will be rebulid (new kernel download e.t.c.). This is very slow (on my laptop)

## NOTES

* Do NOT fix the GPT if you resize the root partition (second partition). This will cause boot errors.

## Links

* https://manpages.ubuntu.com/manpages/bionic/man1/multistrap.1.html
* https://linux-sunxi.org/Mainline_Debian_HowTo
* https://linux-sunxi.org/Allwinner_Nezha#U-Boot
* https://andreas.welcomes-you.com/boot-sw-debian-risc-v-lichee-rv
* https://github.com/sehraf/riscv-arch-image-builder/blob/main/1_compile.sh
* https://github.com/DongshanPI/NezhaSTU-ReleaseLinux/tree/master/.github/workflows

## Basic Flow

* Use a device tree which speficies the hardware
* Compile uboot & friends
* Then compile the kernel using the same device tree (kernel defconfig)

The device tree is first found in the U-boot compile, and the Kernel compile should use this same device tree. In our case there are two of interest. These are found in uboot/configs/xxx

    lichee_rv_86_panel_defconfig
    lichee_rv_defconfig

These are for the RV 86 Panel (with built-in screen) and the dock/board respectively.


## Full List of Packages


[DebianFull]
packages=dash pciutils autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev wpasupplicant htop net-tools wireless-tools ntpdate openssh-client openssh-server sudo e2fsprogs git man-db lshw dbus wireless-regdb libsensors5 lm-sensors swig libssl-dev python3-distutils python3-dev alien fakeroot dkms libblkid-dev uuid-dev libudev-dev libaio-dev libattr1-dev libelf-dev python3-setuptools python3-cffi python3-packaging libffi-dev libcurl4-openssl-dev python3-ply iotop tmux psmisc
source=http://ftp.ports.debian.org/debian-ports/
keyring=debian-ports-archive-keyring
suite=unstable
omitdebsrc=true

