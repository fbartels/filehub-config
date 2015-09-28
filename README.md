# Ravpower WD03 enhancements

My very own EnterRouterMode.sh based on the work of [digidem](https://github.com/digidem/filehub-config) and [steve8x8](https://github.com/steve8x8/filehub-config). I will try to merge upstream changes, but focus on mobile file handling and usability.

## Nice to know:
- telnet login is possible after script run. Password for user root is 20080826. (Login is also possible with the admin user and password set from webinterface).
- password for the root user can be changed with ```ChangeRootPassword.sh```.
- all changes to /etc/ have to be made permanent through execution of ```/usr/sbin/etc_tools p```.
- the device has a "hidden" WebDAV service. It can be reached via ```http://10.10.10.254/data```. Credentials are like in the webinterface.

---
Following are the relevant parts of the original readme:


How to hack the Filehub embedded Linux
--------------------------------------

The RAVPower Filehub runs embedded Linux, which is a cut-down version of Linux with a low memory footprint. Most of the filesystem is read-only apart from the contents of `/etc` and `/tmp`, but changes are not persisted across reboots.

The easiest way to "hack" / modify the configuration of the embedded Linux is to create a script `EnterRouterMode.sh` on an SD card and put the card in the Filehub. The current firmware (2.000.004) will execute a script with this name with root permissions when the SD card is mounted.

The `EnterRouterMode.sh` script modifies scripts within `/etc` and persists changes by running `/usr/sbin/etc_tools p`.

To use, download the EnterRouterMode.sh script, copy it to the top-level folder of an SD card, and insert it into the filehub device.

Building from source
--------------------

```shell
git clone https://github.com/digidem/filehub-config.git
make
```

Change the default password
---------------------------

The default root password on RAVPower Filehub devices is 20080826. This is available on several online forums. Best change it. You can do this by telnet (username: root password: 20080826):

```shell
telnet 10.10.10.254
passwd
```

or create a file `EnterRouterMode.sh` on an SD card and insert it into the Filehub:

```shell
#!/bin/sh
passwd <<'EOF'
newpassword
newpassword
EOF
/usr/sbin/etc_tools p
```

Block external network access
-----------------------------

By default it is possible to telnet into the Filehub from an external network if you know what you are doing. This script adds iptables rules to `/etc/rc.local` ([source](https://web.archive.org/web/20141112135713/http://www.isartor.org/wiki/Securing_your_RavPower_Filehub_RP-WD01))

Copy files from SD card automatically
-------------------------------------

The script runs when any USB device is attached. It checks whether an SD card is present, and it looks for an external USB drive (can be a thumb drive or a USB disk drive) with a folder `.vst` which contains an [rsync](http://rsync.samba.org/) binary built for embedded linux. There is not enough memory on the filehub device to store the rsync binary on the device itself.

The script uses rsync to copy files, which should be resilient to interuption mid-copy and resume where it left off. Source files are removed from the SD card as they are copied to the external drive.

A folder is created for each SD card, identified by a [UUID](http://en.wikipedia.org/wiki/Universally_unique_identifier). It would be ideal to use the serial number for an SD card for the UUID, but unfortunately it is not possible to access this. `udevadm info -a -p  $(udevadm info -q path -n /dev/sda) | grep -m 1 "ATTRS{serial}" | cut -d'"' -f2` returns the serial number for the card reader, rather than the SD card. Instead we generate a UUID using `cat /proc/sys/kernel/random/uuid` and store that on the SD card. Bear in mind if an SD card is re-formatted in the camera then this UUID will be lost, so the card will appear as a new card next time it is inserted. Using a UUID allows for transfers to be interupted and resumed later.

If more than 9999 photos are taken with a camera, filenames will be reused. Similarly if an SD card is used in a different camera, filenames will be repeated. This would lead to overwriting files if we just stored all photos from each SD card in a single folder. Instead we create a subfolder for each import. Ideally this would be named with the date of the import, but the clock on the RavPower device cannot be relied upon without internet access. Instead we use the date of the most recent photo on the SD Card as the name of the subfolder.

When the SD card or USB drive is removed, we kill the rsync process, otherwise it hangs around.

Swap file
---------

The RavPower Filehub only has 28Mb of memory, and about 2Mb of free memory. Rsync needs around [100 bytes for each file](http://rsync.samba.org/FAQ.html#4). To avoid out of memory issues we create a 64Mb swapfile on the USB drive when it is connected. This appears to speed up rsync and *should* avoid memory issues. I have not yet tested with thousands of files.
