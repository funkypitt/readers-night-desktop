# GNOME Shell as Ubuntu ships it, run headless for tests/gnome_test.sh.
ARG RELEASE=24.04
FROM ubuntu:${RELEASE}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        gnome-shell gnome-shell-extension-prefs gnome-settings-daemon ubuntu-wallpapers \
        libglib2.0-bin dbus-user-session dbus-x11 libnotify-bin systemd \
        mesa-utils libgl1-mesa-dri libegl1 python3 python3-pil python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 \
        fonts-ubuntu fonts-dejavu-core xvfb xauth \
    && rm -rf /var/lib/apt/lists/*
# The Shell refuses to start without a login manager on the system bus: a stand-in.
RUN apt-get update && apt-get install -y --no-install-recommends python3-dbusmock && rm -rf /var/lib/apt/lists/*
# For the Xorg session test: grab what the X server really shows.
RUN apt-get update && apt-get install -y --no-install-recommends imagemagick x11-utils && rm -rf /var/lib/apt/lists/*
