#!/bin/sh
# Author. Tim Molteno tim@molteno.net
# (C) 2022.

cp -av /etc/resolv.conf /builder/rv64-port/etc/resolv.conf


# Run the script to create the disk image
./create_image.sh /outport
