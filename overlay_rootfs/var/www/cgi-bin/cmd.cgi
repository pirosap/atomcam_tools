#!/bin/sh

[ -f /etc/environment ] && . /etc/environment

echo "Cache-Control: no-cache"
echo "Content-Type: plain/text"
echo ""

if [ "$REQUEST_METHOD" = "GET" ]; then
  NAME=${QUERY_STRING##name=}
  if [ "$NAME" = "" -o "$NAME" = "latest-ver" ] ; then
    latest=`curl -w "%{redirect_url}" -s -o /dev/null https://github.com/mnakada/atomcam_tools/releases/latest`
    echo LATESTVER=${latest##*Ver.}
  fi
  if [ "$NAME" = "" -o "$NAME" = "status" ] ; then
    echo TIMELAPSE=`echo "timelapse" | nc localhost:4000`
  fi
  if [ "$NAME" = "" -o "$NAME" = "status" ] ; then
    echo TIMESTAMP=`date +"%Y/%m/%d %X"`
  fi
  if [ "$NAME" = "" -o "$NAME" = "status" ] ; then
    res=`echo move | nc localhost:4000`
    [ "$res" = "error" ] || echo MOTORPOS=$res
  fi
fi

if [ "$REQUEST_METHOD" = "POST" ]; then
  PORT=${QUERY_STRING##port=}
  awk '
    BEGIN {
      RS="[{},]";
    }
    /^$/ { next; }
    /\"exec\":\"/ {
      gsub(/^[ \t]*\"exec\":\"/, "");
      gsub(/\"[ \t]*$/, "");
      print $0;
      fflush();
    }
  ' | (
    if [ "$PORT" = "socket" ]; then
      /usr/bin/nc localhost:4000
    else
      cat >> /var/run/webcmd
      read ack < /var/run/webres
      echo $ack
    fi
  )
fi
