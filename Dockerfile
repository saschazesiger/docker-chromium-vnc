FROM alpine:3.17

LABEL maintainer="Don <novaspirit@novaspirit.com>"


RUN apk add --no-cache sudo git xfce4 faenza-icon-theme bash python3 tigervnc chromium cmake wget i3wm i3status rxvt-unicode \
    pulseaudio xfce4-pulseaudio-plugin pavucontrol pulseaudio-alsa alsa-plugins-pulse alsa-lib-dev nodejs npm \
    build-base \
    && adduser -h /home/alpine -s /bin/bash -S -D alpine && echo -e "alpine\nalpine" | passwd alpine \
    && echo 'alpine ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && git clone https://github.com/novnc/noVNC /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify 

COPY /novnc /opt/noVNC


RUN npm install --prefix /opt/noVNC ws
RUN npm install --prefix /opt/noVNC audify

USER alpine
WORKDIR /home/alpine

RUN mkdir -p /home/alpine/.vnc \
    && echo -e "-Securitytypes=none" > /home/alpine/.vnc/config \
    && echo -e "#!/bin/bash\ni3 &" > /home/alpine/.vnc/xstartup \
    && echo -e "alpine\nalpine\nn\n" | vncpasswd

USER root

RUN echo '\
#!/bin/bash \
/usr/bin/vncserver :99 2>&1 | sed  "s/^/[Xtigervnc ] /" & \
sleep 1 & \
/usr/bin/pulseaudio 2>&1 | sed  "s/^/[pulseaudio] /" & \
sleep 1 & \
/usr/bin/node /opt/noVNC/audify.js 2>&1 | sed "s/^/[audify    ] /" & \
/opt/noVNC/utils/novnc_proxy --vnc localhost:5999 2>&1 | sed "s/^/[noVNC     ] /"'\
>/entry.sh

USER alpine

ENTRYPOINT [ "/bin/bash", "/entry.sh" ]
