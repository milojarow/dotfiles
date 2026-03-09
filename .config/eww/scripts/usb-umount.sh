#!/usr/bin/env bash
# usb-umount.sh <partition_name>
# Unmounts a USB partition via udisksctl.
udisksctl unmount -b "/dev/$1"
