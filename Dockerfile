FROM debian:bookworm
MAINTAINER Tim Molteno "tim@molteno.net"
ARG DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture riscv64

RUN apt-get update && apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev swig libssl-dev python3-distutils python3-dev git

RUN apt-get install -y gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
RUN apt-get install -y mmdebstrap qemu-user-static binfmt-support debian-ports-archive-keyring
RUN apt-get install -y multistrap systemd-container

# Build the kernel
WORKDIR /kbuild
RUN git clone https://github.com/smaeul/linux
RUN mkdir -p linux-build/arch/riscv/configs
# COPY licheerv_linux_defconfig linux-build/arch/riscv/configs/licheerv_defconfig


WORKDIR /kbuild/linux
RUN git pull
#RUN git checkout riscv/d1-wip
RUN git checkout  d1-wip-v5.18-rc4

COPY kernel/update_kernel_config.sh .
RUN ./update_kernel_config.sh

RUN apt-get install -y cpio
WORKDIR /kbuild
RUN make ARCH=riscv -C linux O=/kbuild/linux-build nezha_defconfig
RUN make -j `nproc` -C /kbuild/linux-build ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- V=0

# Build kernel modules
RUN git clone https://github.com/lwfinger/rtl8723ds.git
WORKDIR /kbuild/rtl8723ds
RUN make -j `nproc` ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- KSRC=/kbuild/linux-build modules
RUN ls -l
# Module resides in /kbuild/rtl8723ds/8723ds.ko

# Build u-boot

WORKDIR /uboot
RUN git clone https://github.com/smaeul/u-boot.git
WORKDIR /uboot/u-boot
RUN git checkout d1-wip
RUN apt-get install -y python3-setuptools
RUN make CROSS_COMPILE=riscv64-linux-gnu- nezha_defconfig
RUN make -j `nproc` ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- all V=1

# Build opensbi

WORKDIR /uboot
RUN git clone https://github.com/smaeul/opensbi
WORKDIR /uboot/opensbi
RUN git checkout d1-wip
RUN make CROSS_COMPILE=riscv64-linux-gnu- PLATFORM=generic FW_PIC=y FW_OPTIONS=0x2

WORKDIR /uboot
COPY licheerv_toc1.cfg .
RUN ./u-boot/tools/mkimage -T sunxi_toc1 -d licheerv_toc1.cfg u-boot.toc1

COPY bootscr.txt .
RUN ./u-boot/tools/mkimage -T script -C none -O linux -A "riscv" -d bootscr.txt boot.scr

# Create a BSP boot0 SPL

RUN git clone https://github.com/smaeul/sun20i_d1_spl -b mainline
WORKDIR /uboot/sun20i_d1_spl
RUN make CROSS_COMPILE=riscv64-linux-gnu- p=sun20iw1p1 mmc
# The copying needs to be done when the image is created
# sudo dd if=/uboot/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin of=/dev/sdX bs=8192 seek=1


# Build the root filesystem
WORKDIR /build
COPY multistrap.conf .
COPY multistrap_config.sh .
COPY multistrap_setup.sh .

RUN multistrap -f multistrap.conf

# Set everything up.

RUN apt-get install -y kpartx openssl fdisk dosfstools e2fsprogs kmod parted

COPY build.sh .
COPY create_image.sh .
COPY stage1.sh .
COPY disk_layout.sfdisk .
CMD /build/build.sh
