#!/bin/bash
# Author Tim Molteno
# Update the mainline kernel nezha_defconfig
# TODO check this link... https://github.com/orangecms/linux/commit/1c493a6ef452189ae6820bb8282e8554e7527473#diff-21cd816c673272d3392dba0a524ec1a068e9229ee784cfb106c02aa89e26f7d1R179

CONF_FILE=./arch/riscv/configs/$1

function add_config() {
    fgrep -v $1 ${CONF_FILE} > tmp_conf
    echo "$1=$2" >> tmp_conf
    mv tmp_conf ${CONF_FILE}
}

add_config 'CONFIG_DEFAULT_HOSTNAME' '"lichee"'
# enable WiFi
add_config 'CONFIG_WIRELESS' 'y'
add_config 'CONFIG_CFG80211' 'y'
add_config 'CONFIG_MAC80211' 'y'
add_config 'CONFIG_XR829_WLAN' 'm'

# enable /proc/config.gz
add_config 'CONFIG_IKCONFIG_PROC' 'y'
# There is no LAN. so let there be USB-LAN
add_config 'CONFIG_USB_NET_DRIVERS' 'm'
add_config 'CONFIG_USB_CATC' 'm'
add_config 'CONFIG_USB_KAWETH' 'm'
add_config 'CONFIG_USB_PEGASUS' 'm'
add_config 'CONFIG_USB_RTL8150' 'm'
add_config 'CONFIG_USB_RTL8152' 'm'
add_config 'CONFIG_USB_LAN78XX' 'm'
add_config 'CONFIG_USB_USBNET' 'm'
add_config 'CONFIG_USB_NET_AX8817X' 'm'
add_config 'CONFIG_USB_NET_AX88179_178A' 'm'
add_config 'CONFIG_USB_NET_CDCETHER' 'm'
add_config 'CONFIG_USB_NET_CDC_EEM' 'm'
add_config 'CONFIG_USB_NET_CDC_NCM' 'm'
add_config 'CONFIG_USB_NET_HUAWEI_CDC_NCM' 'm'
add_config 'CONFIG_USB_NET_CDC_MBIM' 'm'
add_config 'CONFIG_USB_NET_DM9601' 'm'
add_config 'CONFIG_USB_NET_SR9700' 'm'
add_config 'CONFIG_USB_NET_SR9800' 'm'
add_config 'CONFIG_USB_NET_SMSC75XX' 'm'
add_config 'CONFIG_USB_NET_SMSC95XX' 'm'
add_config 'CONFIG_USB_NET_GL620A' 'm'
add_config 'CONFIG_USB_NET_NET1080' 'm'
add_config 'CONFIG_USB_NET_PLUSB' 'm'
add_config 'CONFIG_USB_NET_MCS7830' 'm'
add_config 'CONFIG_USB_NET_RNDIS_HOST' 'm'
add_config 'CONFIG_USB_NET_CDC_SUBSET_ENABLE' 'm'
add_config 'CONFIG_USB_NET_CDC_SUBSET' 'm'
add_config 'CONFIG_USB_ALI_M5632' 'y'
add_config 'CONFIG_USB_AN2720' 'y'
add_config 'CONFIG_USB_BELKIN' 'y'
add_config 'CONFIG_USB_ARMLINUX' 'y'
add_config 'CONFIG_USB_EPSON2888' 'y'
add_config 'CONFIG_USB_KC2190' 'y'
add_config 'CONFIG_USB_NET_ZAURUS' 'm'
add_config 'CONFIG_USB_NET_CX82310_ETH' 'm'
add_config 'CONFIG_USB_NET_KALMIA' 'm'
add_config 'CONFIG_USB_NET_QMI_WWAN' 'm'
add_config 'CONFIG_USB_NET_INT51X1' 'm'
add_config 'CONFIG_USB_IPHETH' 'm'
add_config 'CONFIG_USB_SIERRA_NET' 'm'
add_config 'CONFIG_USB_VL600' 'm'
add_config 'CONFIG_USB_NET_CH9200' 'm'
add_config 'CONFIG_USB_NET_AQC111' 'm'
add_config 'CONFIG_USB_RTL8153_ECM' 'm'
# enable systemV IPC (needed by fakeroot during makepkg)
# add_config 'CONFIG_SYSVIPC' 'y'
# add_config 'CONFIG_SYSVIPC_SYSCTL' 'y'
# enable swap
add_config 'CONFIG_SWAP' 'y'
add_config 'CONFIG_ZSWAP' 'y'
# Allow systemd getty service
# add_config 'CONFIG_FHANDLE' 'y'

# The following from https://github.com/DongshanPI/NezhaSTU-ReleaseLinux/blob/master/nezhastu_linux_defconfig
# add_config 'CONFIG_ARM_SUN50I_R329_MBUS_DEVFREQ' 'y'
# add_config 'CONFIG_PM_DEVFREQ' 'y'
#
# add_config 'CONFIG_SUN50I_CPUFREQ_NVMEM' 'y'
# add_config 'CONFIG_CPU_FREQ' 'y'
# add_config 'CONFIG_CPU_FREQ_STAT' 'y'
# add_config 'CONFIG_CPU_FREQ_GOV_ONDEMAND' 'y'
# add_config 'CONFIG_CPUFREQ_DT' 'y'
# add_config 'CONFIG_SUN50I_CPUFREQ_NVMEM' 'y'
# add_config 'CONFIG_CPU_IDLE' 'y'
# add_config 'CONFIG_RISCV_SBI_CPUIDLE' 'y'

add_config 'CONFIG_VIDEO_SUNXI' 'y'
add_config 'CONFIG_VIDEO_SUNXI_CEDRUS' 'y'

#
#   Modules for the SPI display
#   1.14" 135×240 SPI LCD screen.
#   Sitronix ST7789V controller
#
add_config 'CONFIG_DRM_PANEL_MIPI_DBI' 'y'
add_config 'CONFIG_CRYPTO' 'y'
add_config 'CONFIG_CRYPTO_LIB_ARC4' 'y'
add_config 'CONFIG_CRYPTO_AES' 'y'
add_config 'CONFIG_CRYPTO_CCM' 'y'
add_config 'CONFIG_CRYPTO_GCM' 'y'
add_config 'CONFIG_CRYPTO_CMAC' 'y'
add_config 'CONFIG_CRC32' 'y'

#
#   Enable device tree overlays
#
add_config 'CONFIG_USE_OF' 'y'
add_config 'CONFIG_OF_LIBFDT_OVERLAY' 'y'

echo "Config File Follows #####################"
cat ${CONF_FILE}
