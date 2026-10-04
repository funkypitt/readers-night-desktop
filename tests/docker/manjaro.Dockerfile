# KWin as Manjaro ships it, run on its virtual backend for tests/plasma_test.sh.
FROM manjarolinux/base:latest
RUN pacman -Syu --noconfirm --needed kwin kconfig qt6-declarative qt6-wayland mesa libnotify \
        python python-pillow python-gobject ttf-dejavu && pacman -Scc --noconfirm
# A notification service, so that the notifications the command sends have somewhere to go.
RUN pacman -Sy --noconfirm --needed dunst && pacman -Scc --noconfirm
