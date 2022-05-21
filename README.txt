The following image files are in this repository:

* licheerv.img.xz : Compressed Debian disk image for the Lichee RV Dock

To flash this image use:

unxz --stdout lichee_rv_img.xz | sudo dd of=${DEVICE} bs=4M status=progress

user: rv
passwd: lichee
root: licheerv

INSTRUCTIONS

Use the nmtui to set up a wifi connection.
Then type:
    service systemd-resolved start
