# Container image for running Vivado on Apple Silicon (Rosetta 2 via Docker).
#
# One Dockerfile covers all supported base images. gen_image.sh passes the
# Ubuntu base that best matches the detected Vivado version:
#   Vivado 2019.2        -> ubuntu:18.04
#   Vivado 2021.1-2022.1 -> ubuntu:20.04
#   Vivado 2022.2-2024.1 -> ubuntu:22.04
#   Vivado 2024.2+       -> ubuntu:24.04
# Each release uses the newest Ubuntu version that AMD officially supports for
# it. Override with --build-arg BASE_IMAGE=ubuntu:<version>.
ARG BASE_IMAGE=ubuntu:22.04
FROM --platform=linux/amd64 ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

# Packages available in every supported Ubuntu release (18.04 / 20.04 / 22.04 / 24.04).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg sudo nano \
        dbus dbus-x11 x11-utils xorg xvfb net-tools \
        libgl1-mesa-dri mesa-utils \
        lxde lxappearance lxterminal xterm arc-theme \
        gtk2-engines gtk2-engines-murrine gtk2-engines-pixbuf \
        fonts-droid-fallback \
        alsa-utils \
        python3-pip python3-dev build-essential git \
        gcc-multilib g++ \
        ocl-icd-opencl-dev libc6-dev-i386 \
        graphviz make unzip \
        libswt-gtk-4-jni \
        locales \
        tigervnc-standalone-server tigervnc-xorg-extension \
        x11-xserver-utils xfonts-base \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Packages and workarounds that differ between the Ubuntu releases.
RUN . /etc/os-release && \
    case "$VERSION_ID" in \
    18.04|20.04) \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            libtinfo5 libncurses5 libncursesw5 libjpeg62-dev libjpeg62 libssl1.1 \
            tigervnc-common && \
        apt-get clean && rm -rf /var/lib/apt/lists/* \
        ;; \
    22.04) \
        apt-get update && \
        echo 'deb http://archive.ubuntu.com/ubuntu focal main' > /etc/apt/sources.list.d/focal-libssl1.1.list && \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            libssl1.1 libtinfo5 libncurses5 libncursesw5 libjpeg62-dev libjpeg62 \
            tigervnc-tools && \
        rm -f /etc/apt/sources.list.d/focal-libssl1.1.list && \
        apt-get clean && rm -rf /var/lib/apt/lists/* \
        ;; \
    24.04) \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            libgtk2.0-0t64 libjpeg-dev libjpeg62 gnome-themes-extra libglu1-mesa \
            libtinfo6 libncurses6 libncursesw6 tigervnc-tools && \
        ln -sf /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5 && \
        ln -sf /lib/x86_64-linux-gnu/libncursesw.so.6 /lib/x86_64-linux-gnu/libncursesw.so.5 && \
        apt-get clean && rm -rf /var/lib/apt/lists/* \
        ;; \
    *) \
        echo "Unsupported Ubuntu release: $VERSION_ID" && exit 1 \
        ;; \
    esac

# vncpasswd is provided by tigervnc-common (18.04) or tigervnc-tools (22.04+)
# through update-alternatives; keep a symlink fallback.
RUN if [ ! -e /usr/bin/vncpasswd ] && [ -e /usr/bin/tigervncpasswd ]; then \
        ln -sf /usr/bin/tigervncpasswd /usr/bin/vncpasswd; \
    fi

# Create user "user" with password "password" (the VNC connection is local-only).
RUN useradd --create-home --shell /bin/bash --user-group --groups adm,sudo user && \
    echo "user:password" | chpasswd && \
    chown -R user:user /home/user

# Setup LXDE desktop configuration
RUN mkdir -p /home/user/.config/pcmanfm/LXDE/ && \
    if [ -f /usr/local/share/doro-lxde-wallpapers/desktop-items-0.conf ]; then \
        ln -sf /usr/local/share/doro-lxde-wallpapers/desktop-items-0.conf \
               /home/user/.config/pcmanfm/LXDE/; \
    fi && \
    if [ -f /usr/bin/lxpolkit ]; then mv /usr/bin/lxpolkit /usr/bin/lxpolkit.bak; fi

# Setup TigerVNC. Ubuntu 18.04 calls the session file Xvnc-session,
# 22.04/24.04 use Xtigervnc-session.
RUN if [ -f /etc/X11/Xtigervnc-session ]; then \
        sed -i 's/-iconic/-nowin/g' /etc/X11/Xtigervnc-session; \
    else \
        sed -i 's/-iconic/-nowin/g' /etc/X11/Xvnc-session; \
    fi && \
    mkdir -p /home/user/.vnc && \
    echo "password" | vncpasswd -f > /vncpasswd && \
    chown user /vncpasswd && \
    chmod 600 /vncpasswd

# Generate locale — Vivado crashes at startup without en_US.UTF-8
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Cap the JVM heap of the installer and Vivado.
ENV JAVA_TOOL_OPTIONS="-Xmx4096m -Xms512m"

# Without this, Vivado can crash when synthesizing; de_start.sh resolves libgdk
# dynamically as well. libgdk lives in /usr/lib on all three Ubuntu releases.
ENV LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libselinux.so.1 /lib/x86_64-linux-gnu/libz.so.1 /usr/lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0"
