#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "This script uses functionality which requires root privileges"
    exit 1
fi

# Assign VNC password via env var
VNC_PASSWORD=secret

# base image 
acbuild --debug begin docker://px4io/px4-dev-simulation

# In the event of the script exiting, end the build
trap "{ export EXT=$?; acbuild --debug end && exit $EXT; }" EXIT

# Install dependencies
acbuild run -- apt-get update
acbuild run -- apt-get install -y \
            dbus-x11 x11-utils x11vnc xvfb supervisor \
            dwm suckless-tools stterm
acbuild run -- x11vnc -storepasswd $VNC_PASSWORD /etc/vncsecret
acbuild run -- chmod 444 /etc/vncsecret
acbuild run -- apt-get autoclean
acbuild run -- apt-get autoremove
acbuild run -- rm -rf /var/lib/apt/lists/* 

# Make the container's entrypoint the super
acbuild run -- mkdir -p /etc/supervisor/conf.d
acbuild copy supervisord.conf /etc/supervisor/conf.d/supervisord.conf
acbuild set-exec -- /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
acbuild port add vnc tcp 5900

# Choose the user to run-as inside the container
acbuild run -- adduser --system --home /home/gopher --shell /bin/bash --group --disabled-password gopher
acbuild run -- usermod -a -G www-data,sudo gopher
acbuild set-user gopher
acbuild set-working-directory /home/gopher


# Write the result
acbuild --debug set-name shrmpy/px4
acbuild --debug label add version 0.0.1

acbuild --debug write --overwrite px4-0.0.1-linux-amd64.aci
