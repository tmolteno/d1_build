#/bin/sh
# Author. Tim Molteno tim@molteno.net
# (C) 2022.

cp /etc/resolv.conf /builder/rv64-port/etc/resolv.conf


#  Move files we'll need from inside the container to the users directory /outport
#  These files will all be visible in ~/port/ after the script is finished.


# Run the script to create the disk image
./create_image.sh /outport
