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
acbuild run -- apt-get install -y git \
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
acbuild run -- usermod -a -G www-data gopher

# Compile the PX4 SITL plugin
acbuild run -- mkdir -p /root/src
acbuild run -- git clone https://github.com/PX4/sitl_gazebo.git /root/src/sitl_gazebo
acbuild run -- mkdir /root/src/sitl_gazebo/Build
acbuild run -- /bin/sh -c 'echo "export GAZEBO_PLUGIN_PATH=${GAZEBO_PLUGIN_PATH}:/root/src/sitl_gazebo/Build" >> /root/.bashrc' 
acbuild run -- /bin/sh -c 'echo "export GAZEBO_MODEL_PATH=${GAZEBO_MODEL_PATH}:/root/src/sitl_gazebo/models" >> /root/.bashrc' 
acbuild run -- /bin/sh -c 'echo "export GAZEBO_MODEL_DATABASE_URI=\"\"" >> /root/.bashrc' 
acbuild run -- /bin/sh -c 'echo "export SITL_GAZEBO_PATH=/root/src/sitl_gazebo" >> /root/.bashrc' 
acbuild run -- /bin/sh -c "cd /root/src/sitl_gazebo; git submodule update --init --recursive .;"
#acbuild run -- /bin/sh -c "cd /root/src/sitl_gazebo/Build; cmake ..; make;"
#acbuild run -- /bin/sh -c "cp /root/src/sitl_gazebo/external/OpticalFlow/build/FindOpticalFlow.cmake /root/src/sitl_gazebo/Build;"
#acbuild run -- /bin/sh -c "cd /root/src/sitl_gazebo/Build; cpack -G DEB; dpkg -i *.deb;"
#acbuild run -- /bin/sh -c ". /usr/share/gazebo/setup.sh; . /usr/share/mavlink_sitl_gazebo/setup.sh; gazebo worlds/iris.world;"

# Write the result
acbuild --debug set-name sitl
acbuild --debug label add version 0.0.1

acbuild --debug write --overwrite sitl-0.0.1-linux-amd64.aci
