#!/bin/bash
# Author Tim Molteno
# Update the mainline kernel nezha_defconfig

CONF_FILE=/build/linux/arch/riscv/configs/nezha_defconfig
function add_config() {
    grep $1 ${CONF_FILE}
    echo $1 >> ${CONF_FILE}
}

# enable WiFi
add_config 'CONFIG_WIRELESS=y'
add_config 'CONFIG_CFG80211=m'
# enable /proc/config.gz
add_config 'CONFIG_IKCONFIG_PROC=y'
# There is no LAN. so let there be USB-LAN
add_config 'CONFIG_USB_NET_DRIVERS=m'
add_config 'CONFIG_USB_CATC=m'
add_config 'CONFIG_USB_KAWETH=m'
add_config 'CONFIG_USB_PEGASUS=m'
add_config 'CONFIG_USB_RTL8150=m'
add_config 'CONFIG_USB_RTL8152=m'
add_config 'CONFIG_USB_LAN78XX=m'
add_config 'CONFIG_USB_USBNET=m'
add_config 'CONFIG_USB_NET_AX8817X=m'
add_config 'CONFIG_USB_NET_AX88179_178A=m'
add_config 'CONFIG_USB_NET_CDCETHER=m'
add_config 'CONFIG_USB_NET_CDC_EEM=m'
add_config 'CONFIG_USB_NET_CDC_NCM=m'
add_config 'CONFIG_USB_NET_HUAWEI_CDC_NCM=m'
add_config 'CONFIG_USB_NET_CDC_MBIM=m'
add_config 'CONFIG_USB_NET_DM9601=m'
add_config 'CONFIG_USB_NET_SR9700=m'
add_config 'CONFIG_USB_NET_SR9800=m'
add_config 'CONFIG_USB_NET_SMSC75XX=m'
add_config 'CONFIG_USB_NET_SMSC95XX=m'
add_config 'CONFIG_USB_NET_GL620A=m'
add_config 'CONFIG_USB_NET_NET1080=m'
add_config 'CONFIG_USB_NET_PLUSB=m'
add_config 'CONFIG_USB_NET_MCS7830=m'
add_config 'CONFIG_USB_NET_RNDIS_HOST=m'
add_config 'CONFIG_USB_NET_CDC_SUBSET_ENABLE=m'
add_config 'CONFIG_USB_NET_CDC_SUBSET=m'
add_config 'CONFIG_USB_ALI_M5632=y'
add_config 'CONFIG_USB_AN2720=y'
add_config 'CONFIG_USB_BELKIN=y'
add_config 'CONFIG_USB_ARMLINUX=y'
add_config 'CONFIG_USB_EPSON2888=y'
add_config 'CONFIG_USB_KC2190=y'
add_config 'CONFIG_USB_NET_ZAURUS=m'
add_config 'CONFIG_USB_NET_CX82310_ETH=m'
add_config 'CONFIG_USB_NET_KALMIA=m'
add_config 'CONFIG_USB_NET_QMI_WWAN=m'
add_config 'CONFIG_USB_NET_INT51X1=m'
add_config 'CONFIG_USB_IPHETH=m'
add_config 'CONFIG_USB_SIERRA_NET=m'
add_config 'CONFIG_USB_VL600=m'
add_config 'CONFIG_USB_NET_CH9200=m'
add_config 'CONFIG_USB_NET_AQC111=m'
add_config 'CONFIG_USB_RTL8153_ECM=m'
# enable systemV IPC (needed by fakeroot during makepkg)
add_config 'CONFIG_SYSVIPC=y'
add_config 'CONFIG_SYSVIPC_SYSCTL=y'
# enable swap
add_config 'CONFIG_SWAP=y'
add_config 'CONFIG_ZSWAP=y'

cat ${CONF_FILE}
