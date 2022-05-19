FROM debian:bookworm as builder
MAINTAINER Tim Molteno "tim@molteno.net"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev swig libssl-dev python3-distutils python3-dev git

WORKDIR /build
ARG GNU_TOOLS_TAG
RUN git config --global advice.detachedHead false
RUN git clone --recursive --depth 1 --branch ${GNU_TOOLS_TAG} https://github.com/riscv/riscv-gnu-toolchain
WORKDIR /build/riscv-gnu-toolchain
RUN git checkout ${GNU_TOOLS_TAG}
RUN ./configure --prefix=/opt/riscv64-unknown-linux-gnu --with-arch=rv64imafdc --with-abi=lp64d
RUN make linux -j `nproc`
ENV PATH="/opt/riscv64-unknown-linux-gnu/bin:$PATH"

# RUN apt-get install -y gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
# ARG CROSS="CROSS_COMPILE=riscv64-linux-gnu-"
# ARG CROSS=CROSS_COMPILE=/build/riscv64-unknown-linux-gnu/bin/riscv64-unknown-linux-gnu-
ENV CROSS=CROSS_COMPILE=riscv64-unknown-linux-gnu-

# Clean up
WORkDIR /build
RUN rm -rf riscv-gnu-toolchain



############################################################################################
#
# Build a BSP boot0 SPL
#
FROM builder as build_boot0
RUN echo $CROSS
RUN echo 'Gcc version:'
RUN riscv64-unknown-linux-gnu-gcc --version
WORKDIR /build
RUN git clone           --branch mainline https://github.com/smaeul/sun20i_d1_spl
WORKDIR /build/sun20i_d1_spl
RUN git checkout 0ad88bfdb723b1ac74cca96122918f885a4781ac
RUN echo make $CROSS p=sun20iw1p1 mmc
RUN make $CROSS p=sun20iw1p1 mmc
# The file resides in /build/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin



############################################################################################
#
# Build opensbi
#
FROM builder as build_opensbi
ARG OPENSBI_TAG
WORKDIR /build
RUN git clone --depth 1 --branch ${OPENSBI_TAG}  https://github.com/smaeul/opensbi
WORKDIR /build/opensbi
RUN make $CROSS PLATFORM=generic FW_PIC=y FW_OPTIONS=0x2
# The binary is located here: /build/opensbi/build/platform/generic/firmware/fw_dynamic.bin




############################################################################################
#
# Build u-boot
#
FROM builder as build_uboot
ARG UBOOT_TAG
RUN apt-get install -y python3-setuptools
WORKDIR /build
RUN git clone --depth 1 --branch ${UBOOT_TAG}  https://github.com/smaeul/u-boot.git
WORKDIR /build/u-boot
#RUN make $CROSS lichee_rv_86_panel_defconfig
RUN make $CROSS lichee_rv_defconfig
RUN make -j `nproc` $CROSS all V=1
RUN ls -l arch/riscv/dts/
# The binary is located here: u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-dock.dtb
# The binary is located here: u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-86-panel.dtb

#
# Generate u-boot TOC
#
WORKDIR /build
COPY --from=build_opensbi /build/opensbi/build/platform/generic/firmware/fw_dynamic.bin ./
COPY config/licheerv_toc1.cfg .
RUN ./u-boot/tools/mkimage -A riscv -T sunxi_toc1 -d licheerv_toc1.cfg u-boot.toc1
RUN ls -l
# The u-boot toc is here: u-boot.toc1
#
# Create a boot script...
#
COPY config/bootscr.txt .
RUN ./u-boot/tools/mkimage -T script -C none -O linux -A riscv -d bootscr.txt boot.scr
# The boot script is here: boot.scr


############################################################################################
#
# Now build the Linux kernel
#
FROM builder as build_kernel
RUN apt-get install -y cpio  # Required for kernel build
WORKDIR /build
RUN git clone --depth 1 --branch riscv/d1-wip https://github.com/smaeul/linux
WORKDIR /build/linux
RUN git checkout riscv/d1-wip
#RUN git checkout d1-wip-v5.18-rc4
COPY kernel/update_kernel_config.sh .
RUN ./update_kernel_config.sh
WORKDIR /build
RUN make ARCH=riscv -C linux O=../linux-build nezha_defconfig
RUN make -j `nproc` -C linux-build ARCH=riscv $CROSS V=0
# Files reside in /build/linux-build/arch/riscv/boot/Image.gz


#
# Build wifi modules
#
WORKDIR /build
RUN git clone --depth 1 https://github.com/lwfinger/rtl8723ds.git
WORKDIR /build/rtl8723ds
RUN make -j `nproc` ARCH=riscv $CROSS KSRC=../linux-build modules
RUN ls -l
# Module resides in /build/rtl8723ds/8723ds.ko



############################################################################################
#
#   Build the root filesystem
#
FROM builder as build_rootfs

RUN apt-get install -y mmdebstrap qemu-user-static binfmt-support debian-ports-archive-keyring
RUN apt-get install -y multistrap systemd-container
RUN apt-get install -y kpartx openssl fdisk dosfstools e2fsprogs kmod parted

WORKDIR /build
COPY rootfs/multistrap.conf .

RUN multistrap -f multistrap.conf

# Now install the kernel modules into the rootfs
WORKDIR /build
COPY --from=build_kernel /build/linux-build/ ./linux-build/
COPY --from=build_kernel /build/linux/ ./linux/
COPY --from=build_kernel /build/rtl8723ds/8723ds.ko .

WORKDIR /build/linux-build
RUN make ARCH=riscv INSTALL_MOD_PATH=/port/rv64-port modules_install

RUN echo "export MODDIR=$(ls /port/rv64-port/lib/modules/)" > /moddef
RUN ls /port/rv64-port/lib/modules/
RUN . /moddef; echo "Creating wireless module in ${MODDIR}"
RUN . /moddef; install -v -D -p -m 644 /build/8723ds.ko /port/rv64-port/lib/modules/${MODDIR}/kernel/drivers/net/wireless/8723ds.ko

RUN . /moddef; rm /port/rv64-port/lib/modules/${MODDIR}/build
RUN . /moddef; rm /port/rv64-port/lib/modules/${MODDIR}/source

RUN . /moddef; depmod -a -b /port/rv64-port "${MODDIR}"
RUN echo '8723ds' >> /port/rv64-port/etc/modules

# This may not be needed as it should be done by the networking setup.
# RUN cp /etc/resolv.conf /port/rv64-port/etc/resolv.conf



############################################################################################
#
#   Now Build the disk image
#
FROM builder as build_image

RUN apt-get install -y kpartx parted

WORKDIR /builder
COPY --from=build_rootfs /port/rv64-port/ ./rv64-port/

COPY --from=build_kernel /build/linux-build/arch/riscv/boot/Image.gz .
COPY --from=build_kernel /build/linux-build/arch/riscv/boot/Image .
COPY --from=build_kernel /build/linux/arch/riscv/configs/nezha_defconfig .

COPY --from=build_boot0 /build/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin .
COPY --from=build_uboot /build/u-boot.toc1 .
COPY --from=build_uboot /build/boot.scr .

RUN ls -l
RUN apt-get install -y kpartx openssl fdisk dosfstools e2fsprogs kmod parted

COPY rootfs/multistrap_config.sh ./rv64-port/multistrap_config.sh

COPY build.sh .
COPY create_image.sh .
COPY stage1.sh .
CMD /builder/build.sh
