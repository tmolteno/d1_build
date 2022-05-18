#/bin/sh
# Author. Tim Molteno tim@molteno.net
# (C) 2022.

ROOT_FS=/build/rv64-port

cp /etc/resolv.conf ${ROOT_FS}/etc/resolv.conf
chroot ${ROOT_FS} /multistrap_config.sh

# cp stage1.sh ${ROOT_FS}/stage1.sh
# chroot ${ROOT_FS} /stage1.sh

#  Move files we'll need from inside the container to the users directory /outport
#  These files will all be visible in ~/port/ after the script is finished.

cp -a ./ /outport/

# Run the script to create the disk image
/build/create_image.sh /outport
