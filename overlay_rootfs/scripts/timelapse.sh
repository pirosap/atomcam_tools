#!/bin/sh

HACK_INI=/tmp/hack.ini
HOSTNAME=`hostname`
WEBHOOK=$(awk -F "=" '/WEBHOOK *=/ {print $2}' $HACK_INI)
WEBHOOK_URL=$(awk -F "=" '/WEBHOOK_URL *=/ {print $2}' $HACK_INI)

if [ "$1" = "finish" ] ; then
  STORAGE_CIFS=$(awk -F "=" '/STORAGE_CIFS *=/ { gsub(/^\/*/, "", $2);print $2}' $HACK_INI)
  STORAGE_CIFS_PATH=$(awk -F "=" '/STORAGE_CIFS_PATH *=/ { gsub(/^\/*/, "", $2);print $2}' $HACK_INI)
  STORAGE_SDCARD=$(awk -F "=" '/STORAGE_SDCARD *=/ {print $2}' $HACK_INI)
  WEBHOOK_TIMELAPSE_FINISH=$(awk -F "=" '/WEBHOOK_TIMELAPSE_FINISH *=/ {print $2}' $HACK_INI)
  (
    if [ "$STORAGE_CIFS" = "on" -o "$STORAGE_CIFS" = "record" ] && /scripts/mount_cifs.sh ; then
      CIFSFILE="time_lapse/${2##*/}"
      OUTFILE="/atom/mnt/$HOSTNAME/$CIFSFILE"
      DIR_PATH=${OUTFILE%/*}
      mkdir -p $DIR_PATH
      cp -f $2 $OUTFILE
      STORAGE=", \"cifsFile\":\"${CIFSFILE}\""
    fi

    if [ "$STORAGE_SDCARD" = "on" -o "$STORAGE_SDCARD" = "record" ]; then
      STORAGE="${STORAGE}, \"sdcardFile\":\"${2##*media/mmc/}\""
    else
      rm $2
      find /media/mmc/time_lapse -depth -type d -empty -delete
    fi
    if [ "$WEBHOOK" = "on" ] && [ "$WEBHOOK_URL" != "" ] && [ "$WEBHOOK_TIMELAPSE_FINISH" = "on" ]; then
      /usr/bin/curl -X POST -m 3 -H "Content-Type: application/json" -d "{\"type\":\"timelapseFinish\", \"device\":\"${HOSTNAME}\"${STORAGE}}" $WEBHOOK_URL > /dev/null 2>&1
    fi
  ) &
  exit 0
fi

if [ "$1" = "start" ] ; then
  TIMELAPSE=$(awk -F "=" '/TIMELAPSE *=/ {print $2}' $HACK_INI)
  [ "$TIMELAPSE" = "on" ] || exit 0

  WEBHOOK_TIMELAPSE_START=$(awk -F "=" '/WEBHOOK_TIMELAPSE_START *=/ {print $2}' $HACK_INI)
  TIMELAPSE_INTERVAL=$(awk -F "=" '/TIMELAPSE_INTERVAL *=/ {print $2}' $HACK_INI)
  TIMELAPSE_COUNT=$(awk -F "=" '/TIMELAPSE_COUNT *=/ {print $2}' $HACK_INI)
  TIMELAPSE_PATH=$(awk -F "=" '/TIMELAPSE_PATH *=/ {print $2}' $HACK_INI)
  TIMELAPSE_FILE=`date +"/media/mmc/time_lapse/$TIMELAPSE_PATH.mp4"`
  TIMELAPSE_DIR=${TIMELAPSE_FILE%/*}
  mkdir -p $TIMELAPSE_DIR

  res=`/scripts/cmd timelapse $TIMELAPSE_FILE $TIMELAPSE_INTERVAL $TIMELAPSE_COUNT`
  [ "$res" = "ok" ] || exit 1
  if [ "$WEBHOOK" = "on" ] && [ "$WEBHOOK_URL" != "" ] && [ "$WEBHOOK_TIMELAPSE_START" = "on" ]; then
    /usr/bin/curl -X POST -m 3 -H "Content-Type: application/json" -d "{\"type\":\"timelapseStart\", \"device\":\"${HOSTNAME}\"${STORAGE}}" $WEBHOOK_URL > /dev/null 2>&1
  fi
fi
