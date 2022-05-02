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
COPY licheerv_linux_defconfig linux-build/arch/riscv/configs/licheerv_defconfig
WORKDIR /kbuild/linux
# RUN git checkout 06b026a8b7148f18356c5f809e51f013c2494587

RUN apt-get install -y cpio
WORKDIR /kbuild
RUN make ARCH=riscv -C linux O=/kbuild/linux-build licheerv_defconfig
RUN make -j `nproc` -C /kbuild/linux-build ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- V=0

# Build oreboot

WORKDIR /uboot
RUN git clone https://github.com/smaeul/u-boot.git
WORKDIR /uboot/u-boot
RUN git checkout d1-wip
RUN make CROSS_COMPILE=riscv64-linux-gnu- nezha_defconfig
RUN make -j `nproc` ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- all V=1

# Build the root filesystem
WORKDIR /build
COPY multistrap.conf .
COPY multistrap_config.sh .
COPY multistrap_setup.sh .
COPY build.sh .



# RUN multistrap -f multistrap.conf
CMD /build/build.sh
# RUN multistrap -f multistrap.conf
# RUN
# RUN chroot /port/rv64-port /usr/bin/dpkg --configure -a
