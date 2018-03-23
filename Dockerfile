FROM px4io/px4-dev-simulation

ARG VNC_PASSWORD=secret
ENV VNC_PASSWORD=${VNC_PASSWORD} \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update; apt-get install -y \
            dbus-x11 x11-utils x11vnc xvfb supervisor \
            dwm suckless-tools stterm; \
    adduser --system --home /home/gopher --shell /bin/bash --group --disabled-password gopher; \
    usermod -a -G www-data gopher; \
    mkdir -p /etc/supervisor/conf.d; \
    x11vnc -storepasswd $VNC_PASSWORD /etc/vncsecret; \
    chmod 444 /etc/vncsecret; \
    apt-get autoclean; \
    apt-get autoremove; \
    rm -rf /var/lib/apt/lists/*; 

COPY supervisord.conf /etc/supervisor/conf.d
EXPOSE 5900
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]

WORKDIR /home/gopher

RUN mkdir -p /home/gopher/src; \
    cd /home/gopher/src; \
    git clone https://github.com/PX4/Firmware; \
    cd /home/gopher/src/Firmware; 
####    make posix_sitl_default gazebo_none_ide;
