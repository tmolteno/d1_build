The following image files are in this repository:

* licheerv.img.7z : Compressed Debian disk image for the Lichee RV Dock

To flash this image use:

7z x licheerv.img.7z -so | less | sudo dd of=${DEVICE} status=progress

user: rv
passwd: lichee
root: licheerv
