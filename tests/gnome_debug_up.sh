#!/usr/bin/env bash
# Debug helper: a headless Shell with the extension installed, left running.
#   docker run -d --name rn-dbg -v "$PWD":/src:ro -v "$PWD/tests/out":/out rn-ubuntu:24.04 bash /src/tests/gnome_debug_up.sh
#   docker exec rn-dbg /ev 'Main.uiGroup.get_n_children()'
#   docker exec rn-dbg /shot name
export XDG_RUNTIME_DIR=/run/user/0 XDG_CURRENT_DESKTOP=ubuntu:GNOME XDG_SESSION_TYPE=wayland LANG=C.UTF-8 LIBGL_ALWAYS_SOFTWARE=1
mkdir -p "$XDG_RUNTIME_DIR" /out/dbg /tmp/.X11-unix /run/dbus && chmod 700 "$XDG_RUNTIME_DIR" && chmod 1777 /tmp/.X11-unix
dbus-daemon --system --fork; (python3 -m dbusmock --system --template logind >/dev/null 2>&1 &); sleep 1
eval "$(dbus-launch --sh-syntax)"; echo "export DBUS_SESSION_BUS_ADDRESS='$DBUS_SESSION_BUS_ADDRESS' XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP LANG=$LANG" > /env
H="$HOME/.local/share/gnome-shell/extensions/rn-test@gallaz.ch"; mkdir -p "$H"
echo '{"uuid":"rn-test@gallaz.ch","name":"rn test","description":"t","shell-version":["45","46","47","48","49","50"]}' > "$H/metadata.json"
cat > "$H/extension.js" <<J
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
export default class T extends Extension { enable() { global.context.unsafe_mode = true; } disable() {} }
J
gsettings set org.gnome.shell enabled-extensions "['rn-test@gallaz.ch']"
gsettings set org.gnome.shell welcome-dialog-last-shown-version "'999'"
bash /src/dist/readers-night-install.sh; "$HOME/.local/bin/readers-night" off
printf '#!/bin/bash\n. /env\ngdbus call --session -d org.gnome.Shell -o /org/gnome/Shell -m org.gnome.Shell.Eval "$1"\n' > /ev
printf '#!/bin/bash\n. /env\ngdbus call --session -d org.gnome.Shell.Screenshot -o /org/gnome/Shell/Screenshot -m org.gnome.Shell.Screenshot.Screenshot false false "/out/dbg/$1.png" >/dev/null; chmod a+rw /out/dbg/$1.png; python3 -c "from PIL import Image; im=Image.open(\\"/out/dbg/$1.png\\"); print(\\"$1\\", [im.getpixel(p) for p in ((640,16),(100,400),(640,400),(1200,780))])"\n' > /shot
printf '#!/bin/bash\n. /env\nexec "$HOME/.local/bin/readers-night" "$@"\n' > /rn
printf '#!/bin/bash\n. /env\nimport -silent -window root "/out/dbg/$1.png"; chmod a+rw /out/dbg/$1.png; python3 -c "from PIL import Image; im=Image.open(\\"/out/dbg/$1.png\\").convert(\\"RGB\\"); print(\\"$1\\", [im.getpixel(p) for p in ((640,16),(100,400),(640,400),(1200,780))])"\n' > /grab
chmod +x /ev /shot /rn /grab
if [ "${RN_X11:-}" = 1 ]; then
    # An Xorg session: the Shell as window manager of a virtual X server; /grab reads the
    # server's real output instead of asking the Shell for a screenshot.
    Xvfb :5 -screen 0 1280x800x24 >/dev/null 2>&1 &
    sleep 1
    echo "export DISPLAY=:5" >> /env
    DISPLAY=:5 XDG_SESSION_TYPE=x11 gnome-shell --x11 > /out/dbg/shell.log 2>&1 &
else
    gnome-shell --headless --wayland --virtual-monitor 1280x800 > /out/dbg/shell.log 2>&1 &
fi
sleep 8; /ev 'Main.overview.hide(); 1'
sleep infinity
