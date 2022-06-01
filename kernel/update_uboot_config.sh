#!/bin/bash
# Author Tim Molteno
# Update the mainline u-boot config
# TODO check this link... https://github.com/orangecms/linux/commit/1c493a6ef452189ae6820bb8282e8554e7527473#diff-21cd816c673272d3392dba0a524ec1a068e9229ee784cfb106c02aa89e26f7d1R179

CONF_FILE=./configs/$1

function add_config() {
    fgrep -v $1 ${CONF_FILE} > tmp_conf
    echo "$1=$2" >> tmp_conf
    mv tmp_conf ${CONF_FILE}
}

#
#   Enable device tree overlays
#
add_config 'CONFIG_OF_LIBFDT_OVERLAY' 'y'

echo "Config File Follows #####################"
cat ${CONF_FILE}
