# Will check if rsync is available and can be used on the data store drive.
# For rsync to work you have to manually copy the rsync binary to the .vst dir.
# (a copy can be found in the build dir)

STORE_DIR=.vst

# search for .internal on all attached disks (first one will be used)
while read device mountpoint fstype remainder; do
    echo "Checking $device at $mountpoint" >> /tmp/swapinfo
    if [ ${device:0:7} == "/dev/sd" -a -e "$mountpoint/$STORE_DIR" ];then
	$mountpoint/$STORE_DIR/rsync -help > /dev/null 2>&1 
	if [ $? -ne 0 ]; then
	    echo "could not execute rsync"
    	fi
    fi
done < /proc/mounts
