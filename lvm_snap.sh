#!/bin/bash

LVMPATH=/dev/vg1
MAPPERPATH=/dev/mapper
MOUNTPATH=/mnt/backup
IDENTIFIER="-snap"

CMD_LVDISPLAY=/sbin/lvdisplay
CMD_LVCREATE=/sbin/lvcreate
CMD_LVREMOVE=/sbin/lvremove
CMD_MOUNT=/bin/mount
CMD_UMOUNT=/bin/umount
CMD_GREP=/bin/grep
CMD_WC=/usr/bin/wc
CMD_KPARTX=/sbin/kpartx
CMD_AWK=/usr/bin/awk
CMD_CUT=/usr/bin/cut

function usage_info {
  cat <<USAGE
  
DESCRIPTION: 
  Automated creation and removal of LVM snapshots.
  
  LVM VG:         ${LVMPATH}
  MOUNT PATH:     ${MOUNTPATH}
      
USAGE:
    $ME <command> <lvmvolume> <rootpartition> [<additional partition>=<mount path>]
             
COMMANDS:
  create:     create a LVM snapshot and mount to MOUNT PATH
  remove:     remove a LVM snapshot
USAGE
}

if [ -z $1 ]; then
  echo "Please specify a command."
  echo
  usage_info
  exit 1
fi

if [ -z $2 ]; then
  echo "Please specify a LVM Volume name."
  echo
  usage_info
  exit 1
fi

if [ -z $3 ]; then
  echo "Please specify at least 1 partition"
  echo
  usage_info
  exit 1
fi

LVMVOLUME=$LVMPATH/$2
LVMSNAPSHOT=$2$IDENTIFIER
SNAPSHOTMOUNT=$MOUNTPATH/$2
SNAPSHOTSIZE=`lvdisplay $LVMVOLUME | $CMD_GREP "LV Size" | $CMD_AWK '{print $3}'`G

if [ $1 = "create" ]; then
	echo "Creating Snapshot.."
	$CMD_LVCREATE -L $SNAPSHOTSIZE -s -n $LVMSNAPSHOT $LVMVOLUME
	echo "Running KPARTX to it.."
	$CMD_KPARTX -a $LVMPATH/$LVMSNAPSHOT
	echo "Mounting.."
	if [ -d $SNAPSHOTMOUNT ]; then
		echo "Mount Dir exists.."
	else
		echo "Creating Mount Dir $SNAPSHOTMOUNT.."
		mkdir -p $SNAPSHOTMOUNT
	fi
	PARTNUM=$3
	PARTKPARTPATH=`$CMD_KPARTX -l $LVMPATH/$LVMSNAPSHOT | $CMD_GREP snap$PARTNUM | cut -d" " -f1`
	echo "Mounting Partition $PARTKPARTPATH to $SNAPSHOTMOUNT.."
	mount -o ro $MAPPERPATH/$PARTKPARTPATH $SNAPSHOTMOUNT
	echo "Checking for additional Partition to mount.."
	if [ -z $4 ]; then
		echo "No Second Partition defined"
	else
		PARTNUM=`echo $4 | $CMD_CUT -d"=" -f1`
		PARTPATH=`echo $4 | $CMD_CUT -d"=" -f2`
		PARTKPARTPATH=`$CMD_KPARTX -l $LVMPATH/$LVMSNAPSHOT | $CMD_GREP snap$PARTNUM | cut -d" " -f1`
		echo "Mounting Partition $PARTKPARTPATH to $SNAPSHOTMOUNT/$PARTPATH.."
		mount -o ro $MAPPERPATH/$PARTKPARTPATH $SNAPSHOTMOUNT/$PARTPATH
	fi
	echo "done."

elif [ $1 = "remove" ]; then
	echo "Checking for additional Partition to umount.."
	if [ -z $4 ]; then
		echo "No Second Partition defined"
	else
		PARTNUM=`echo $4 | $CMD_CUT -d"=" -f1`
		PARTKPARTPATH=`$CMD_KPARTX -l $LVMPATH/$LVMSNAPSHOT | $CMD_GREP snap$PARTNUM | cut -d" " -f1`
		echo "Umounting Partition $PARTKPARTPATH.."
		umount $MAPPERPATH/$PARTKPARTPATH
	fi
	PARTNUM=$3
	PARTKPARTPATH=`$CMD_KPARTX -l $LVMPATH/$LVMSNAPSHOT | $CMD_GREP snap$PARTNUM | cut -d" " -f1`
	echo "Umounting $PARTKPARTPATH.."
	umount $MAPPERPATH/$PARTKPARTPATH
	echo "Removing KPARTX crap.."
	$CMD_KPARTX -d $LVMPATH/$LVMSNAPSHOT
	echo "Removing LVM"
	$CMD_LVREMOVE -f $LVMPATH/$LVMSNAPSHOT
	echo "done."

fi
