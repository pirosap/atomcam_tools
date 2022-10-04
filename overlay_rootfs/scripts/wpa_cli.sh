#!/bin/sh
echo 'wpa_state=COMPLETED'
for i in `ls /sys/class/net`
do
  [ "$i" = "lo" ] && continue
  [ "$i" = "p2p0" ] && continue
  ADDR=`/bin/busybox ifconfig | awk '/inet / {gsub(/^.*:/, "", $2);if($2 !~ "^127.*") { print $2; exit 0;}}'`
  [ "$ADDR" = "" ] && continue;
  echo ip_addresss=$ADDR
  break
done
