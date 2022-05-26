The following image files are in this repository:

* lichee_rv_dock_XXX.img.xz : Compressed 8Gb Debian disk image for the Lichee RV Dock
* lichee_rv_86_XXX.img.xz : Compressed 8Gb Debian disk image for the Lichee RV 86 Panel

To flash this image (requires SDcard 8GB or larger) use:

unxz --stdout lichee_rv_img.xz | sudo dd of=${DEVICE} bs=4M status=progress

Credentials:
    root: licheerv
    user: rv
    passwd: lichee

INSTRUCTIONS

* Use the 'nmtui' command to set up a wifi connection.
* Connect using a serial port, or an HDMI monitor (takes about a minute to appear), or by ssh
