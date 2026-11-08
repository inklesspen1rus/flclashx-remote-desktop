#!/bin/sh

if [ "$VNC_PASSWORD" ]; then
    sed -i "s/^\(command.*x11vnc.*\)$/\1 -passwd '$VNC_PASSWORD'/" /etc/supervisord.conf
fi

dbus-run-session /usr/bin/supervisord -c /etc/supervisord.conf