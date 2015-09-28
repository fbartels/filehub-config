# Copy rsync to the data store drive

STORE_DIR=/.internal
CONFIG_DIR="$STORE_DIR"/donottouch

if [ -z "$ERM_ROOT" ]; then
    echo Environment ERM_ROOT unknown
elif [ ! -f $ERM_ROOT/rsync ]; then
    echo no rsync binary in $ERM_ROOT to copy to $CONFIG_DIR
elif [ -f $CONFIG_DIR/rsync ]; then
    echo rsync binary already exists in $CONFIG_DIR
fi

cp -p $ERM_ROOT/rsync $CONFIG_DIR/
echo copy rsync returned $?

# this may fail (e.g. on VFAT)
chmod 777 $CONFIG_DIR/rsync
#echo chmod rsync returned $?
