FROM debian:bullseye as builder
MAINTAINER Tim Molteno "tim@molteno.net"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y eatmydata \
    && eatmydata apt-get install -y autoconf automake autotools-dev bc binfmt-support \
                                   bison build-essential cpio curl debian-ports-archive-keyring \
                                   dosfstools e2fsprogs fdisk flex gawk gcc-riscv64-linux-gnu \
                                   git gperf g++-riscv64-linux-gnu kmod kpartx libexpat-dev \
                                   libgmp-dev libmpc-dev libmpfr-dev libssl-dev \
                                   libtool mmdebstrap multistrap openssl parted \
                                   patchutils python3 python3-dev python3-distutils \
                                   python3-setuptools qemu-user-static swig \
                                   systemd-container texinfo zlib1g-dev

ENV CROSS="CROSS_COMPILE=riscv64-linux-gnu-"
RUN riscv64-linux-gnu-gcc --version | grep gcc | cut -d')' -f2


############################################################################################
#
# Build opensbi
#
FROM builder as build_opensbi
WORKDIR /build
RUN git clone --depth 1 https://github.com/riscv-software-src/opensbi
WORKDIR /build/opensbi
RUN eatmydata make $CROSS PLATFORM=generic FW_PIC=y FW_OPTIONS=0x2
# The binary is located here: /build/opensbi/build/platform/generic/firmware/fw_dynamic.bin


############################################################################################
#
# Now build the Linux kernel
#
FROM builder as build_kernel
ARG KERNEL_TAG
ARG KERNEL_COMMIT
WORKDIR /build
RUN eatmydata git clone --depth 1 --branch ${KERNEL_TAG} https://github.com/smaeul/linux
RUN cd linux && eatmydata git checkout ${KERNEL_COMMIT} && cd -
WORKDIR /build/linux/drivers/net/wireless
RUN eatmydata git clone --depth 1 https://github.com/YuzukiHD/Xradio-XR829.git
RUN echo 'obj-$(CONFIG_XR829_WLAN) += Xradio-XR829/' >> Makefile
WORKDIR /build/linux
#RUN git checkout riscv/d1-wip
#RUN git checkout d1-wip-v5.18-rc4
COPY kernel/update_kernel_config.sh .
RUN ./update_kernel_config.sh defconfig
WORKDIR /build
RUN eatmydata make ARCH=riscv -C linux O=../linux-build defconfig
RUN eatmydata make -j $(nproc) -C linux-build ARCH=riscv $CROSS V=0
# Files reside in /build/linux-build/arch/riscv/boot/Image.gz
# RUN make -j $(nproc) -C linux-build ARCH=riscv $CROSS INSTALL_MOD_PATH=/build/modules modules_install


#
# Build wifi modules
#
WORKDIR /build
RUN eatmydata git clone --depth 1 https://github.com/lwfinger/rtl8723ds.git
WORKDIR /build/rtl8723ds
RUN eatmydata make -j $(nproc) ARCH=riscv $CROSS KSRC=../linux-build modules
RUN ls -l
# Module resides in /build/rtl8723ds/8723ds.ko

## WORKDIR /build
## COPY kernel/xradio/ ./xradio/
## WORKDIR /build/xradio
## RUN make ARCH=riscv $CROSS -C /build/linux-build M=$PWD modules; exit 1
## RUN ls -l
# Module resides in /build/xr829/xr829.ko


############################################################################################
#
# Build u-boot
#
FROM builder as build_uboot
ARG UBOOT_TAG
ARG BOARD
WORKDIR /build
RUN eatmydata git clone --depth 1 --branch ${UBOOT_TAG} https://github.com/smaeul/u-boot.git
WORKDIR /build/u-boot

# Make sure we update the device tree and add the overlays
COPY kernel/update_uboot_config.sh .
COPY config/ov_lichee_rv_mini_lcd.dts ./arch/riscv/dts/ov_lichee_rv_mini_lcd.dts
RUN sed -i '3s/^/dtb-$(CONFIG_TARGET_SUN20I_D1) += ov_lichee_rv_mini_lcd.dtb\n/' ./arch/riscv/dts/Makefile
RUN cat ./arch/riscv/dts/Makefile

RUN if [ "$BOARD" = "lichee_rv_86" ] ; then \
      echo "Building for the RV_86_Panel"; \
      ./update_uboot_config.sh lichee_rv_86_panel_defconfig; \
      eatmydata make $CROSS lichee_rv_86_panel_defconfig; \
    elif [ "$BOARD" = "lichee_rv_dock" ] || [ "$BOARD" = "lichee_rv_lcd" ] ; then \
      echo "Building for Lichee RV Dock"; \
      ./update_uboot_config.sh lichee_rv_dock_defconfig; \
      eatmydata make $CROSS lichee_rv_dock_defconfig; \
    else \
      echo "ERROR: unknown board"; \
    fi
COPY --from=build_opensbi /build/opensbi/build/platform/generic/firmware/fw_dynamic.bin ./
RUN eatmydata make -j $(nproc) $CROSS all OPENSBI=fw_dynamic.bin V=1
RUN ls -l arch/riscv/dts/
# The binary is located here: u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-dock.dtb
# The binary is located here: u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-86-panel.dtb
# The binary is located here: u-boot/arch/riscv/dts/ov_lichee_rv_mini_lcd.dtb
#
# Create a boot script...
#
WORKDIR /build
RUN ls -l
COPY config/bootscr_${BOARD}.txt .
RUN eatmydata ./u-boot/tools/mkimage -T script -C none -O linux -A riscv -d bootscr_${BOARD}.txt boot.scr
# The boot script is here: boot.scr


############################################################################################
#
#   Build the root filesystem
#
FROM builder as build_rootfs
ARG BOARD

WORKDIR /build
COPY rootfs/multistrap_$BOARD.conf multistrap.conf

RUN ls
RUN eatmydata multistrap -f multistrap.conf

# Now install the kernel modules into the rootfs
WORKDIR /build
COPY --from=build_kernel /build/linux-build/ ./linux-build/
COPY --from=build_kernel /build/linux/ ./linux/
COPY --from=build_kernel /build/rtl8723ds/8723ds.ko .
WORKDIR /build/linux-build
RUN eatmydata make ARCH=riscv INSTALL_MOD_PATH=/port/rv64-port modules_install

RUN ls /port/rv64-port/lib/modules/ > /kernel_ver
RUN echo "export MODDIR=$(ls /port/rv64-port/lib/modules/)" > /moddef
RUN ls /port/rv64-port/lib/modules/
RUN . /moddef; echo "Creating wireless module in ${MODDIR}"
RUN . /moddef; install -v -D -p -m 644 /build/8723ds.ko /port/rv64-port/lib/modules/${MODDIR}/kernel/drivers/net/wireless/8723ds.ko

RUN . /moddef; rm /port/rv64-port/lib/modules/${MODDIR}/build
RUN . /moddef; rm /port/rv64-port/lib/modules/${MODDIR}/source

RUN . /moddef; depmod -a -b /port/rv64-port "${MODDIR}"
RUN echo '8723ds' >> /port/rv64-port/etc/modules
RUN echo 'xr829' >> /port/rv64-port/etc/modules

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

WORKDIR /builder
COPY --from=build_rootfs /kernel_ver /port/rv64-port ./
COPY --from=build_kernel /build/linux-build/arch/riscv/boot/Image.gz /build/linux/arch/riscv/configs/defconfig ./
COPY --from=build_uboot /build/boot.scr /build/u-boot/u-boot-sunxi-with-spl.bin /build/u-boot/arch/riscv/dts/ov_lichee_rv_mini_lcd.dtb ./

COPY rootfs/setup_rootfs.sh ./rv64-port/
COPY scripts/build.sh scripts/create_image.sh ./
RUN ls -l

CMD eatmydata /builder/build.sh
