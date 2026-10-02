#!/usr/bin/env bash
# Debug helper: KWin on its virtual backend with one colourful window, left running.
#   docker run -d --name rn-kde --cap-add SYS_NICE --device /dev/dri/renderD128 -v "$PWD":/src:ro -v "$PWD/tests/out":/out rn-manjaro bash /src/tests/plasma_debug_up.sh
#   docker exec rn-kde /shot name      docker exec rn-kde /rn on
export XDG_RUNTIME_DIR=/run/user/0 XDG_CURRENT_DESKTOP=KDE XDG_SESSION_TYPE=wayland LANG=C.UTF-8
export KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 QT_QPA_PLATFORM=wayland
mkdir -p "$XDG_RUNTIME_DIR" /out/kde /run/dbus && chmod 700 "$XDG_RUNTIME_DIR"
dbus-daemon --system --fork 2>/dev/null
eval "$(dbus-launch --sh-syntax)"
echo "export DBUS_SESSION_BUS_ADDRESS='$DBUS_SESSION_BUS_ADDRESS' XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP=KDE LANG=$LANG WAYLAND_DISPLAY=wayland-0 QT_QPA_PLATFORM=wayland PATH=$PATH:/usr/lib/qt6/bin" > /env
mkdir -p /scene; cat > /scene/Scene.qml <<'Q'
import QtQuick
import QtQuick.Window
Window {
    visible: true; visibility: Window.FullScreen; color: "white"; title: "scene"
    Row { x: 100; y: 100
        Rectangle { width: 200; height: 200; color: "#ff0000" }
        Rectangle { width: 200; height: 200; color: "#00ff00" }
        Rectangle { width: 200; height: 200; color: "#0000ff" }
        Rectangle { width: 200; height: 200; color: "#808080" }
    }
}
Q
cat > /shot <<'S'
#!/bin/bash
. /env
raw=/out/kde/$1.raw
exec 3>"$raw"
meta="$(busctl --user call org.kde.KWin /org/kde/KWin/ScreenShot2 org.kde.KWin.ScreenShot2 CaptureWorkspace 'a{sv}h' 0 3)"
exec 3>&-
sleep 0.7
python3 - "$raw" "/out/kde/$1.png" "$meta" <<'P'
import re, sys
from PIL import Image
raw, png, meta = sys.argv[1:4]
num = lambda k: int(re.search(r'"%s" u (\d+)' % k, meta).group(1))
w, h, stride = num("width"), num("height"), num("stride")
data = open(raw, "rb").read()
im = Image.frombuffer("RGBA", (w, h), data, "raw", "BGRA", stride, 1).convert("RGB")
im.save(png)
print(png.split("/")[-1], [im.getpixel(p) for p in ((200, 200), (400, 200), (600, 200), (800, 200), (1000, 600))])
P
rm -f "$raw"; chmod a+rw /out/kde/$1.png
S
printf '#!/bin/bash\n. /env\nexec "$HOME/.local/bin/readers-night" "$@"\n' > /rn
chmod +x /shot /rn
QT_FORCE_STDERR_LOGGING=1 kwin_wayland --virtual --width 1280 --height 800 --no-lockscreen --socket wayland-0 > /out/kde/kwin.log 2>&1 &
sleep 4
/usr/lib/qt6/bin/qml /scene/Scene.qml > /out/kde/scene.log 2>&1 &
sleep infinity
