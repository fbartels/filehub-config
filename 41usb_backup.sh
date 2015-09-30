# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/udev/script/add_usb_storage.sh

# Delete exit from end of the file
sed -i '/^exit$/d' /etc/udev/script/add_usb_storage.sh

# Add call to usb backup script after drive mounts
cat <<'EOF' >> /etc/udev/script/add_usb_storage.sh
#START_MOD
# Run backup script
/etc/udev/script/usb_backup.sh &
exit
#END_MOD
EOF

cat <<'EOF' > /etc/udev/script/usb_backup.sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Kill an existing backup process if running 
# (this can happen if you insert two disks one after the other)
if [ -e /tmp/backup.pid ]; then
	kill $(cat /tmp/backup.pid)
	killall rsync
	sleep 1
fi
echo $$ > /tmp/backup.pid

SD_MOUNTPOINT=/data/UsbDisk1/Volume1
STORE_DIR=.vst
PHOTO_DIR=sd-import
MEDIA_REGEX=".*\.\(jpg\|gif\|png\|jpeg\|mov\|avi\|wav\|mp3\|aif\|wma\|wmv\|asx\|asf\|m4v\|mp4\|mpg\|3gp\|3g2\|crw\|cr2\|nef\|dng\|mdc\|orf\|sr2\|srf\)"

# Check if an SD card is inserted (always mounted at the same mount point on the Rav Filehub)
check_sdcard() {
	while read device mountpoint fstype remainder; do
		if [ "$mountpoint" == "$SD_MOUNTPOINT" ]; then
			# Get the UUID for the SD card. Create one if it doesn't already exist
			local uuid_file
			uuid_file="$SD_MOUNTPOINT"/.uuid
			if [ -e $uuid_file ]; then
				sd_uuid=`cat $uuid_file`
			else
				sd_uuid=`cat /proc/sys/kernel/random/uuid`
				echo "$sd_uuid" > $uuid_file
			fi
			return 1
		fi
	done < /proc/mounts
	return 0
}

# Check if a USB drive is attached which is initialize for storing monitoring data
check_storedrive() {
	while read device mountpoint fstype remainder; do
		if [ ${device:0:7} == "/dev/sd" -a -e "$mountpoint/$STORE_DIR"/rsync ];then
			# Add the store dir (containing rsync binary) to the PATH
			export PATH="$mountpoint/$STORE_DIR":$PATH
			store_mountpoint="$mountpoint"
			store_id=$(udevadm info -a -p  $(udevadm info -q path -n ${device:0:8}) | grep -m 1 "ATTRS{serial}" | cut -d'"' -f2)
			return 1
		fi
	done < /proc/mounts
	return 0
}

# If no SD card is inserted, just exit.
check_sdcard
sdcard=$?

check_storedrive
storedrive=$?

# If both a valid store drive and SD card are mounted,
# copy the SD card contents to the store drive
if [ $sdcard -eq 1 -a $storedrive -eq 1 ];then
	# Get the date of the latest file on the SD card
	last_file="$SD_MOUNTPOINT"/DCIM/`ls -1c "$SD_MOUNTPOINT"/DCIM/ | tail -1`
	last_file_date=`stat "$last_file" | grep Modify | sed -e 's/Modify: //' -e 's/[:| ]/_/g' | cut -d . -f 1`

	# Organize the photos in a folder for each SD card by UUID,
	# organize in subfolders by date of latest photo being imported
	target_dir="$store_mountpoint/$PHOTO_DIR"/"$sd_uuid"/"$last_file_date"
	incoming_dir="$store_mountpoint/$PHOTO_DIR"/incoming/"$sd_uuid"
	partial_dir="$store_mountpoint/$PHOTO_DIR"/incoming/.partial
	mkdir -p $target_dir
	mkdir -p $incoming_dir

	# Copy the files from the sd card to the target dir, 
	# Uses filename and size to check for duplicates
	echo "Copying SD card to $incoming_dir" >> /tmp/usb_add_info
	rsync -vrm --size-only --log-file /tmp/rsync_log --partial-dir "$partial_dir" --exclude ".?*" "$SD_MOUNTPOINT"/DCIM/ "$target_dir"
fi

# Write memory buffer to disk
sync

rm /tmp/backup.pid
exit
EOF

# Make executable
chmod +x /etc/udev/script/usb_backup.sh
