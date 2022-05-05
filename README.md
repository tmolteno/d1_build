# Build an Image for the Sipeed Lichee RV

An attempt to automate the build of an image, mostly to be able to learn how to do this.

Author: Tim Molteno (tim@molteno.net)

## How to use

This is intended to be used on a debian system with docker, and docker-compose installed.

    docker-compose build
    docker-compose up

The build stage does a lot of the work (compiling kernels e.t.c and takes quite a bit of time). Once this is done it will be cached by Docker, so should run faster. The execution stage (docker-compose up) runs a script that does more of the image building using a series of scripts (build.sh, create_image.sh).

This should produce a disk image in the directory ~/port/ of the user that ran the script.

There is a Makefile that automates this, and you can just type

    make

And the image will be built.

### Clean Build

Just issue,

    docker-compose build --no-cache

And everything will be rebulid (new kernel download e.t.c.). This is very slow (on my laptop)

## WORK-IN-PROGRESS

Caution. This is a work in progress and is not fully working yet. Help is appreciated.

## Links

* https://manpages.ubuntu.com/manpages/bionic/man1/multistrap.1.html
* https://linux-sunxi.org/Mainline_Debian_HowTo
* https://linux-sunxi.org/Allwinner_Nezha#U-Boot
* https://andreas.welcomes-you.com/boot-sw-debian-risc-v-lichee-rv
* https://github.com/sehraf/riscv-arch-image-builder/blob/main/1_compile.sh

## Old Thread from Telegram

Daniel Maslowski, [1/05/22 11:06 PM]
You can try this:
- take smaeul's kernel
- add memory config to the dts
- build with hardcoded cmdline
- copy the modules to your SD card
- build oreboot with that kernel and dtb
- run via xfel

Daniel Maslowski, [1/05/22 11:07 PM]
In the cmdline, provide the rootfs location, console, and what else you may need

Daniel Maslowski, [1/05/22 11:08 PM]
If all works, build smaeul's SPL and U-Boot and put those plus that kernek on an SD card (see the docs in sunxi-linux wiki on how that works) plus the Debian rootfs.

TIm Molteno, [1/05/22 11:10 PM]
OK. Following this...? https://linux-sunxi.org/Mainline_Debian_HowTo

Daniel Maslowski, [1/05/22 11:10 PM]
The other option is to take smaeul's U-Boot and run that from memory via xfel. I'm not sure if that requires loading to a specific address though.

Daniel Maslowski, [1/05/22 11:12 PM]
[In reply to TIm Molteno]
Not everything is upstream yet, it takes some time. You'll need to diverge from that a bit, but yes, that's the general procedure.

O GL, [1/05/22 11:12 PM]
[In reply to Michael]
among dependencies not found in doc (as I start system from scratch:  swig git base-devel

Daniel Maslowski, [1/05/22 11:12 PM]
[In reply to Daniel Maslowski]
see here https://linux-sunxi.org/Allwinner_Nezha#U-Boot

Daniel Maslowski, [1/05/22 11:14 PM]
Ah, someone should update that part on DRAM. It has been successfully translated to C already. :-)

Daniel Maslowski, [1/05/22 11:14 PM]
https://github.com/smaeul/sun20i_d1_spl/commit/9e207bd830155653af0fa2c37e368d6211e73188
this happened 🥳🥳

TIm Molteno, [1/05/22 11:18 PM]
Looking through the dts, the memory configuration seems to be included already via #include "sun20i-d1.dtsi" from #include "sun20i-d1-lichee-rv.dts".  What did you mean by add memory config to dts?

Daniel Maslowski, [1/05/22 11:19 PM]
(you'd only need it with oreboot because we don't have it yet 😅)

Daniel Maslowski, [1/05/22 11:19 PM]
I think loading U-Boot instead will be quicker for you

Daniel Maslowski, [1/05/22 11:21 PM]
it'd look like this:
https://github.com/orangecms/linux/commit/42363de415310c48cc4ed597fecfdabfc77402a1



## Full List of Packages


[DebianFull]
packages=dash pciutils autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev wpasupplicant htop net-tools wireless-tools ntpdate openssh-client openssh-server sudo e2fsprogs git man-db lshw dbus wireless-regdb libsensors5 lm-sensors swig libssl-dev python3-distutils python3-dev alien fakeroot dkms libblkid-dev uuid-dev libudev-dev libaio-dev libattr1-dev libelf-dev python3-setuptools python3-cffi python3-packaging libffi-dev libcurl4-openssl-dev python3-ply iotop tmux psmisc
source=http://ftp.ports.debian.org/debian-ports/
keyring=debian-ports-archive-keyring
suite=unstable
omitdebsrc=true

