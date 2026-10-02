#!/usr/bin/env bash
# Runs inside the rn-ubuntu image (see tests/docker): installs with the real installer,
# starts GNOME Shell, flips the filter with the real command and compares pictures of the
# screen pixel by pixel.
#
#   docker run --rm -e RN_SESSION=x11 -v "$PWD":/src:ro -v "$PWD/tests/out":/out rn-ubuntu:24.04 bash /src/tests/gnome_test.sh
#
# RN_SESSION=x11      the Shell as window manager of a virtual X server; pictures are what
#                     the X server really shows.
# RN_SESSION=wayland  (default) the Shell as a headless Wayland compositor; pictures are
#                     the Shell's own screenshots.
set -u
RN_SESSION="${RN_SESSION:-wayland}"
export RN_SESSION XDG_RUNTIME_DIR=/run/user/0 XDG_CURRENT_DESKTOP=ubuntu:GNOME XDG_SESSION_TYPE="$RN_SESSION" LANG=C.UTF-8
export LIBGL_ALWAYS_SOFTWARE=1 GSK_RENDERER=cairo NO_AT_BRIDGE=1
mkdir -p "$XDG_RUNTIME_DIR" /out /tmp/.X11-unix && chmod 700 "$XDG_RUNTIME_DIR" && chmod 1777 /tmp/.X11-unix
OUT=/out/gnome-$(gnome-shell --version | grep -o '[0-9]\+' | head -1)-$RN_SESSION
rm -rf "$OUT"; mkdir -p "$OUT" /run/dbus; dbus-daemon --system --fork 2>/dev/null
(python3 -m dbusmock --system --template logind >/dev/null 2>&1 &); sleep 1   # the Shell wants a system bus and a login manager on it

inner() {
    fail=0
    ok() { echo "ok   $*"; }
    bad() { echo "FAIL $*"; fail=1; }

    # A helper extension that opens the Shell's own test doors (screenshots, Eval).
    H="$HOME/.local/share/gnome-shell/extensions/rn-test@gallaz.ch"; mkdir -p "$H"
    cat > "$H/metadata.json" <<J
{"uuid":"rn-test@gallaz.ch","name":"rn test","description":"t","shell-version":["45","46","47","48","49","50"]}
J
    cat > "$H/extension.js" <<J
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
export default class T extends Extension { enable() { global.context.unsafe_mode = true; } disable() {} }
J
    gsettings set org.gnome.shell enabled-extensions "['rn-test@gallaz.ch']"
    gsettings set org.gnome.shell welcome-dialog-last-shown-version "'999'"
    gsettings set org.gnome.desktop.background picture-uri "'file:///usr/share/backgrounds/warty-final-ubuntu.png'" 2>/dev/null

    bash /src/dist/readers-night-install.sh > "$OUT/install.txt" 2>&1 || bad "installer exit $?"
    cat "$OUT/install.txt"
    RN="$HOME/.local/bin/readers-night"
    [ "$($RN status | head -1)" != "" ] && ok "command answers: $($RN status | head -1)" || bad "command silent"
    gsettings get org.gnome.shell enabled-extensions | grep -q readers-night && ok "extension listed as enabled" || bad "not enabled"

    # Start with the filter off, to have a reference picture.
    $RN notify off; $RN off
    if [ "$RN_SESSION" = x11 ]; then
        Xvfb :5 -screen 0 1280x800x24 >/dev/null 2>&1 &
        sleep 1; export DISPLAY=:5
        gnome-shell --x11 > "$OUT/shell.log" 2>&1 &
        shot() { sleep 0.5; import -silent -window root "$OUT/$1.png"; }
        dbus-update-activation-environment DISPLAY GSK_RENDERER LIBGL_ALWAYS_SOFTWARE
    else
        gnome-shell --headless --wayland --virtual-monitor 1280x800 > "$OUT/shell.log" 2>&1 &
        shot() { gdbus call --session -d org.gnome.Shell.Screenshot -o /org/gnome/Shell/Screenshot -m org.gnome.Shell.Screenshot.Screenshot false false "$OUT/$1.png" >/dev/null; sleep 0.5; }
        export WAYLAND_DISPLAY=wayland-0
        dbus-update-activation-environment WAYLAND_DISPLAY GSK_RENDERER LIBGL_ALWAYS_SOFTWARE
    fi
    ev() { gdbus call --session -d org.gnome.Shell -o /org/gnome/Shell -m org.gnome.Shell.Eval "$1"; }
    for i in $(seq 1 60); do ev 'Main.overview.hide(); 1' >/dev/null 2>&1 && break; sleep 1; done
    sleep 5; ev 'Main.overview.hide(); 1' >/dev/null; sleep 2

    state="$(ev "Main.extensionManager.lookup('readers-night@gallaz.ch')?.state")"
    case "$state" in *"'1'"*) ok "extension loaded by the Shell" ;; *) bad "extension not active: $state"; ev "Main.extensionManager.lookup('readers-night@gallaz.ch')?.error" ;; esac

    # A real window on the screen: the extension's own preferences.
    gnome-extensions prefs readers-night@gallaz.ch > "$OUT/prefs.log" 2>&1
    sleep 7; ev 'Main.messageTray._hideNotification?.(); 1' >/dev/null; sleep 4

    shot off
    $RN on; sleep 1.5; shot on
    $RN gray off; sleep 1; shot colour
    $RN gray on; $RN brightness 40; sleep 1; shot dim40
    $RN brightness 70; sleep 0.5
    ev 'Main.notify("Unrelated", "A banner drawn while the filter is on"); global.stage.queue_redraw(); 1' >/dev/null; sleep 2; shot on-after-redraws
    ev 'Main.panel.statusArea.quickSettings.menu.open(); 1' >/dev/null; sleep 1.5; shot quick-settings
    ev 'Main.panel.statusArea.quickSettings.menu.close(); Main.messageTray._hideNotification?.(); 1' >/dev/null; sleep 5
    $RN toggle; sleep 1.5; shot off-again
    # Notifications, for the eye.
    $RN notify on; $RN on; sleep 2; shot banner-on
    $RN off; sleep 2; shot banner-off
    $RN status

    python3 - "$OUT" <<'PY' || fail=1
import sys
from PIL import Image
out = sys.argv[1]
L = (0.2126, 0.7152, 0.0722); T = (1.0, 0.5167, 0.0)
def load(n): return Image.open(f"{out}/{n}.png").convert("RGB")
def amber(p, gray, dim):
    if gray:
        l = sum(c * w for c, w in zip(p, L)); p = (l, l, l)
    return tuple(c * t * dim for c, t in zip(p, T))
def compare(name, ref, got, gray, dim, skip_top=0):
    w, h = ref.size; worst = 0; total = 0; n = 0; blue = 0
    for y in range(skip_top, h, 7):
        for x in range(0, w, 7):
            if y < 150 and 370 < x < 910:      # where this container's own banners come and go
                continue
            want = amber(ref.getpixel((x, y)), gray, dim) if dim else ref.getpixel((x, y))
            g = got.getpixel((x, y))
            d = max(abs(a - b) for a, b in zip(want, g)); worst = max(worst, d); total += d; n += 1
            blue = max(blue, g[2])
    mean = total / n
    okay = mean < 1.5 and (dim == 0 or blue == 0)
    print(("ok   " if okay else "FAIL ") + f"{name}: mean error {mean:.2f}, worst {worst:.0f}, highest blue {blue}")
    return okay
off = load("off")
res = [
    compare("filter on = gray, amber, 70 %", off, load("on"), True, 0.7),
    compare("colours kept", off, load("colour"), False, 0.7),
    compare("brightness 40 %", off, load("dim40"), True, 0.4),
    compare("off again = the original picture", off, load("off-again"), None, 0),
]
checks = []
for name, label in (("on-after-redraws", "after a banner and a full redraw"), ("quick-settings", "quick settings open"), ("banner-on", "notification on")):
    im = load(name)
    blue = max(p[2] for p in im.getdata())
    lit = im.getpixel((100, 400))[0] > 0      # the wallpaper is still drawn, not black
    good = blue == 0 and lit
    checks.append(good)
    print(("ok   " if good else "FAIL ") + f"{label}: highest blue {blue}, wallpaper {'drawn' if lit else 'BLACK'}")
sys.exit(0 if all(res) and all(checks) else 1)
PY
    grep -i -E "readers-night|JS ERROR" "$OUT/shell.log" | head -20
    kill %1 2>/dev/null
    bash /src/dist/readers-night-install.sh --uninstall
    [ ! -e "$HOME/.local/share/gnome-shell/extensions/readers-night@gallaz.ch" ] && [ ! -e "$HOME/.local/bin/readers-night" ] \
        && ! gsettings get org.gnome.shell enabled-extensions | grep -q readers-night && ok "uninstall leaves nothing" || bad "uninstall left something"
    [ $fail = 0 ] && echo "ALL OK" || echo "FAILED"
    chmod -R a+rwX /out
    return $fail
}
export -f inner; export OUT
dbus-run-session -- bash -c inner
