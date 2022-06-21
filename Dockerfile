FROM debian:bullseye as builder
MAINTAINER Tim Molteno "tim@molteno.net"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev swig libssl-dev python3-distutils python3-dev git

RUN apt-get install -y gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
ENV CROSS="CROSS_COMPILE=riscv64-linux-gnu-"
RUN riscv64-linux-gnu-gcc --version | grep gcc | cut -d')' -f2
# WORKDIR /build
# ARG GNU_TOOLS_TAG
# RUN git config --global advice.detachedHead false
# RUN git clone --recursive --depth 1 --branch ${GNU_TOOLS_TAG} https://github.com/riscv/riscv-gnu-toolchain
# WORKDIR /build/riscv-gnu-toolchain
# RUN git checkout ${GNU_TOOLS_TAG}
# RUN ./configure --prefix=/opt/riscv64-unknown-linux-gnu --with-arch=rv64gc --with-abi=lp64d
# RUN make linux -j $(nproc)
# ENV PATH="/opt/riscv64-unknown-linux-gnu/bin:$PATH"

# ARG CROSS=CROSS_COMPILE=/build/riscv64-unknown-linux-gnu/bin/riscv64-unknown-linux-gnu-
# ENV CROSS=CROSS_COMPILE=riscv64-unknown-linux-gnu-

# Clean up
# WORKDIR /build
# RUN rm -rf riscv-gnu-toolchain



############################################################################################
#
# Build a BSP boot0 SPL
#
FROM builder as build_boot0
RUN echo $CROSS
WORKDIR /build
RUN git clone           --branch mainline https://github.com/smaeul/sun20i_d1_spl
WORKDIR /build/sun20i_d1_spl
# RUN git checkout 0ad88bfdb723b1ac74cca96122918f885a4781ac
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
# Now build the Linux kernel
#
FROM builder as build_kernel
ARG KERNEL_TAG
RUN apt-get install -y cpio  # Required for kernel build
WORKDIR /build
RUN git clone --depth 1 --branch ${KERNEL_TAG} https://github.com/smaeul/linux
WORKDIR /build/linux
#RUN git checkout riscv/d1-wip
#RUN git checkout d1-wip-v5.18-rc4
COPY kernel/update_kernel_config.sh .
RUN ./update_kernel_config.sh nezha_defconfig
WORKDIR /build
RUN make ARCH=riscv -C linux O=../linux-build nezha_defconfig
RUN make -j $(nproc) -C linux-build ARCH=riscv $CROSS V=0
# Files reside in /build/linux-build/arch/riscv/boot/Image.gz
RUN apt-get install -y kmod
# RUN make -j $(nproc) -C linux-build ARCH=riscv $CROSS INSTALL_MOD_PATH=/build/modules modules_install



#
# Build wifi modules
#
WORKDIR /build
RUN git clone --depth 1 https://github.com/lwfinger/rtl8723ds.git
WORKDIR /build/rtl8723ds
RUN make -j $(nproc) ARCH=riscv $CROSS KSRC=../linux-build modules
RUN ls -l
# Module resides in /build/rtl8723ds/8723ds.ko

WORKDIR /build
COPY kernel/xradio/ ./xradio/
WORKDIR /build/xradio
RUN make ARCH=riscv $CROSS -C /build/linux-build M=$PWD modules
RUN ls -l
# Module resides in /build/xr829/xr829.ko




############################################################################################
#
# Build u-boot
#
FROM builder as build_uboot
ARG UBOOT_TAG
ARG BOARD
RUN apt-get install -y python3-setuptools git
WORKDIR /build
RUN git clone --depth 1 --branch ${UBOOT_TAG}  https://github.com/smaeul/u-boot.git
WORKDIR /build/u-boot

# Make sure we update the device tree and add the overlays
COPY kernel/update_uboot_config.sh .
COPY config/ov_lichee_rv_mini_lcd.dts ./arch/riscv/dts/ov_lichee_rv_mini_lcd.dts
RUN sed -i '3s/^/dtb-$(CONFIG_TARGET_SUNXI) += ov_lichee_rv_mini_lcd.dtb\n/' ./arch/riscv/dts/Makefile
RUN cat ./arch/riscv/dts/Makefile

RUN if [ "$BOARD"  = "lichee_rv_86" ] ; then \
      echo "Building for the RV_86_Panel"; \
      ./update_uboot_config.sh lichee_rv_86_panel_defconfig; \
      make $CROSS lichee_rv_86_panel_defconfig; \
    elif [ "$BOARD"  = "lichee_rv_dock" ] ; then \
      echo "Building for Lichee RV Dock"; \
      ./update_uboot_config.sh lichee_rv_defconfig; \
      make $CROSS lichee_rv_defconfig; \
    else \
      echo "ERROR: unknown board"; \
    fi
RUN make -j $(nproc) $CROSS all V=1
RUN ls -l arch/riscv/dts/
# The binary is located here: u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-dock.dtb
# The binary is located here: u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-86-panel.dtb

#
# Generate u-boot TOC
#
WORKDIR /build
COPY --from=build_opensbi /build/opensbi/build/platform/generic/firmware/fw_dynamic.bin ./
COPY config/toc1_${BOARD}.cfg .
RUN ls -l
RUN ./u-boot/tools/mkimage -A riscv -T sunxi_toc1 -d toc1_${BOARD}.cfg u-boot.toc1
# The u-boot toc is here: u-boot.toc1
#
# Create a boot script...
#
COPY config/bootscr.txt .
RUN ./u-boot/tools/mkimage -T script -C none -O linux -A riscv -d bootscr.txt boot.scr
# The boot script is here: boot.scr

#
# Try device tree FIT format
#
# RUN apt-get install -y device-tree-compiler
COPY --from=build_kernel /build/linux-build/ ./linux-build/
COPY config/${BOARD}_boot.its .
RUN PATH=/build/linux-build/scripts/dtc:$PATH ./u-boot/tools/mkimage -f ${BOARD}_boot.its boot.scr
# RUN ./u-boot/tools/mkimage -f lichee_rv_boot.itb boot.scr




############################################################################################
#
#   Build the root filesystem
#
FROM builder as build_rootfs
ARG BOARD

RUN apt-get install -y mmdebstrap qemu-user-static binfmt-support debian-ports-archive-keyring
RUN apt-get install -y multistrap systemd-container
RUN apt-get install -y kmod

WORKDIR /build
COPY rootfs/multistrap_$BOARD.conf multistrap.conf

RUN multistrap -f multistrap.conf

# Now install the kernel modules into the rootfs
WORKDIR /build
COPY --from=build_kernel /build/linux-build/ ./linux-build/
COPY --from=build_kernel /build/linux/ ./linux/
COPY --from=build_kernel /build/rtl8723ds/8723ds.ko .
COPY --from=build_kernel /build/xradio/xradio_wlan.ko .

WORKDIR /build/linux-build
RUN make ARCH=riscv INSTALL_MOD_PATH=/port/rv64-port modules_install


RUN ls /port/rv64-port/lib/modules/ > /kernel_ver
RUN echo "export MODDIR=$(ls /port/rv64-port/lib/modules/)" > /moddef
RUN ls /port/rv64-port/lib/modules/
RUN . /moddef; echo "Creating wireless module in ${MODDIR}"
RUN . /moddef; install -v -D -p -m 644 /build/8723ds.ko /port/rv64-port/lib/modules/${MODDIR}/kernel/drivers/net/wireless/8723ds.ko
RUN . /moddef; install -v -D -p -m 644 /build/xradio_wlan.ko /port/rv64-port/lib/modules/${MODDIR}/kernel/drivers/net/wireless/xradio_wlan.ko



RUN . /moddef; rm /port/rv64-port/lib/modules/${MODDIR}/build
RUN . /moddef; rm /port/rv64-port/lib/modules/${MODDIR}/source

RUN . /moddef; depmod -a -b /port/rv64-port "${MODDIR}"
RUN echo '8723ds' >> /port/rv64-port/etc/modules
RUN echo 'xradio_wlan' >> /port/rv64-port/etc/modules

# This may not be needed as it should be done by the networking setup.
# RUN cp /etc/resolv.conf /port/rv64-port/etc/resolv.conf



############################################################################################
#
#   Now Build the disk image
#
FROM builder as build_image
ARG KERNEL_TAG
ARG GNU_TOOLS_TAG
ARG DISK_MB
ARG BOARD

ENV KERNEL_TAG=$KERNEL_TAG
ENV GNU_TOOLS_TAG=$GNU_TOOLS_TAG
ENV DISK_MB=$DISK_MB
ENV BOARD=$BOARD

RUN apt-get install -y kpartx parted

WORKDIR /builder
COPY --from=build_rootfs /kernel_ver ./kernel_ver
COPY --from=build_rootfs /port/rv64-port/ ./rv64-port/

COPY --from=build_kernel /build/linux-build/arch/riscv/boot/Image.gz .
COPY --from=build_kernel /build/linux/arch/riscv/configs/nezha_defconfig .

COPY --from=build_boot0 /build/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin .
COPY --from=build_uboot /build/u-boot.toc1 .
COPY --from=build_uboot /build/boot.scr .

RUN ls -l
RUN apt-get install -y kpartx openssl fdisk dosfstools e2fsprogs kmod parted

COPY rootfs/setup_rootfs.sh ./rv64-port/setup_rootfs.sh

COPY scripts/build.sh .
COPY scripts/create_image.sh .
CMD /builder/build.sh
