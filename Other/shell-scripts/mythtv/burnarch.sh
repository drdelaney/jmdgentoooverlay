#!/bin/sh
ulimit -l unlimited
umount /dev/dvd -fl
/usr/bin/growisofs -Z /dev/dvd=/var/tmp/mythtv/work/mythburn.iso -use-the-force-luke=notray -use-the-force-luke=tty -dvd-compat -speed=4
eject /dev/dvd

