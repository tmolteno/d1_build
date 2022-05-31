# xradio
Port Allwinner xradio driver to mainline Linux.

#Building

Something like this:

```
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C <PATH TO YOUR LINUX SRC> M=$PWD modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C <PATH TO YOUR LINUX SRC> M=$PWD INSTALL_MOD_PATH=<PATH TO INSTALL MODULE> modules_install
```

#How to use this

You need to specify one or two regulators for the xr819's 1.8v and 3.3v supplies in your device tree.
The orange pi zero only has control over the 1.8v regulator and a 3.3v fixed regulator is provided elsewhere
so we one need one there:

```
vdd_wifi: vdd_wifi {
	compatible = "regulator-fixed";
	regulator-name = "wifi";
	regulator-min-microvolt = <1800000>;
	regulator-max-microvolt = <1800000>;
	gpio = <&pio 0 20 GPIO_ACTIVE_HIGH>;
	startup-delay-us = <70000>;
	enable-active-high;
};
```

Next you need a pwrseq node that controls the reset pin of the xr819.

```
pwrseq_wifi: pwrseq_wifi@0 {
	compatible = "mmc-pwrseq-simple";
	pinctrl-names = "default";
	pinctrl-0 = <&wifi_rst>;
	reset-gpios = <&r_pio 0 7 GPIO_ACTIVE_LOW>;
	post-power-on-delay-ms = <50>;
};
```

Next you need to add some things to the mmc node that the xr819 is connected to.

```
&mmc1 {
	pinctrl-names = "default";
	pinctrl-0 = <&mmc1_pins_a>;
	vqmmc-supply = <&vdd_wifi>;
	vmmc-supply = <&reg_vcc3v3>;
	bus-width = <4>;
	mmc-pwrseq = <&pwrseq_wifi>;
	non-removable;
	status = "okay";

        xr819wifi: xr819wifi@1 {
                reg = <1>;
                compatible = "xradio,xr819";
                pinctrl-names = "default";
                pinctrl-0 = <&wifi_wake>;
                interrupt-parent = <&pio>;
                interrupts = <6 10 IRQ_TYPE_EDGE_RISING>;
                interrupt-names = "host-wake";
                local-mac-address = [dc 44 6d c0 ff ee];
        };
};
```


vqmmc-supply and vmmc-supply should reference the regulators that control the xr819 supplies.
The device tree for the SoC the orange pi zero is based on supplies a fixed 3.3v regulator
so we use that for vmmc-supply and provide the 1.8v controllable regulator as vqmmc-supply.
vqmcc-supply is apparently for the IO supply which is 3.3v for the orange pi zero but
swapping vqmmc and vmmc around results in the kernel complaining that the card's (the xr819)
required IO voltage isn't supported. The setup above might not be technically correct but
does work.
The xr819 node should be self explanatory. The compatible string is used by the driver
to find the node. The wake interrupt from the xr819 needs to be provided. 

Finally you can specify a MAC address to use. If you don't set one you will get a random one
on each boot. Instead of creating a new device tree file for every system you should
probably overwrite the address given after loading the device tree in u-boot. For the sunxi
uboot all you have to actually do is add something like "ethernet1 = &xr819wifi;" to the
aliases section of the device tree you give to the kernel and u-boot will update the mac
address to something based on the unique chip id for you.
# What works, what doesn't

Working:

Standard client station mode seems to work fine.
Master (AP) mode works with WPA/WPA2 enabled etc.
Dual role station and master mode.

#Issues

The firmware running on the xr819 is very crash happy and the driver is a bit
stupid. For example the driver can get confused about how many packets of data
the xr819 has for it to read and can try to read too many. The firmware on the
xr819 responds by triggering an assert and shutting down. The driver gets
a packet that tells it that the firmware is dead and shuts down the thread used
to push and pull data but the rest of the driver and the os has no idea and
if the os tries to interact with the driver everything starts to lock up.

Pings from the device to the network are faster than from the network to the device.
This seems to be because of latency between the interrupt and servicing RX reports
from the device.

#Fun stuff

The driver is based on the driver for the ST CW1100/CW1200 chips.
The XR819 is probably a clone, licensed version or actually a CW1100 family chip
that has been packaged by xradio/allwinner as the CW1100 is available as a raw
wafer. 

The silicon version from the XR819 and procedure for loading firmware
matches up with the CW1x60 chips which were apparently never released so
maybe Allwinner bought the design after the ST/Ericsson split?

If anyone wants to mainline support for the XR819 they should probably do it by
adding support for the XR819 to the existing CW1200 driver so they don't have to
get thousands and thousands of lines of code signed off.
