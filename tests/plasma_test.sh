#!/usr/bin/env bash
# Runs inside the rn-manjaro image (see tests/docker): KWin on its virtual output with a
# test window, the real installer, the real command, and KWin's own screenshots read
# back pixel by pixel.
#
#   docker run --rm --cap-add SYS_NICE --device /dev/dri/renderD128 \
#       -v "$PWD":/src:ro -v "$PWD/tests/out":/out rn-manjaro bash /src/tests/plasma_test.sh
#
# KWin only composites with OpenGL (which its effects need) when it finds a render
# device, hence --device; SYS_NICE because its binary carries that capability.
# Night Light acts on the output after the point where screenshots are taken: its state
# is read back over D-Bus, its colour cannot be seen here.
set -u
export XDG_RUNTIME_DIR=/run/user/0 XDG_CURRENT_DESKTOP=KDE XDG_SESSION_TYPE=wayland LANG=C.UTF-8
export KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-0
OUT=/out/plasma-$(pacman -Q kwin | awk '{print $2}' | cut -d- -f1)
rm -rf "$OUT"; mkdir -p "$XDG_RUNTIME_DIR" "$OUT" /run/dbus /scene && chmod 700 "$XDG_RUNTIME_DIR"
dbus-daemon --system --fork 2>/dev/null

inner() {
    fail=0
    ok() { echo "ok   $*"; }
    bad() { echo "FAIL $*"; fail=1; }
    RN="$HOME/.local/bin/readers-night"

    cat > /scene/Scene.qml <<'Q'
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
    sed 's/visibility: Window.FullScreen; color: "white"; title: "scene"/width: 300; height: 200; color: "#00ffff"; title: "late"/' /scene/Scene.qml > /scene/Late.qml

    shot() {   # shot NAME -> prints five pixels: red, green, blue, gray boxes, white ground
        sleep 1
        exec 3>"$OUT/$1.raw"
        meta="$(busctl --user call org.kde.KWin /org/kde/KWin/ScreenShot2 org.kde.KWin.ScreenShot2 CaptureWorkspace 'a{sv}h' 0 3)"
        exec 3>&-
        sleep 0.7
        python3 - "$OUT/$1.raw" "$OUT/$1.png" "$meta" <<'P'
import re, sys
from PIL import Image
raw, png, meta = sys.argv[1:4]
num = lambda k: int(re.search(r'"%s" u (\d+)' % k, meta).group(1))
im = Image.frombuffer("RGBA", (num("width"), num("height")), open(raw, "rb").read(), "raw", "BGRA", num("stride"), 1).convert("RGB")
im.save(png)
print(" ".join("%d,%d,%d" % im.getpixel(p) for p in ((200, 200), (400, 200), (600, 200), (800, 200), (1000, 600))))
P
        rm -f "$OUT/$1.raw"
    }
    expect() {   # expect LABEL "got pixels" "wanted pixels"
        python3 - "$@" <<'P' && ok "$1: $2" || bad "$1: got $2, wanted $3"
import sys
got = [tuple(map(int, p.split(","))) for p in sys.argv[2].split()]
want = [tuple(map(int, p.split(","))) for p in sys.argv[3].split()]
sys.exit(0 if len(got) == len(want) and all(abs(a - b) <= 3 for g, w in zip(got, want) for a, b in zip(g, w)) else 1)
P
    }
    nl() { busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight enabled mode currentTemperature | tr '\n' ' '; }
    # What the user had: on, following the sun (mode 1), 4200 K at night. The temperature
    # in force depends on the hour of the test, so it is read from the settings instead.
    users_own() { [ "$(nl | cut -d' ' -f1-4)" = "b true u 1" ] && [ "$(kreadconfig6 --file kwinrc --group NightColor --key NightTemperature)" = 4200 ]; }

    QT_FORCE_STDERR_LOGGING=1 kwin_wayland --virtual --width 1280 --height 800 --no-lockscreen --socket wayland-0 > "$OUT/kwin.log" 2>&1 &
    sleep 4
    /usr/lib/qt6/bin/qml /scene/Scene.qml > "$OUT/scene.log" 2>&1 &
    dunst > "$OUT/dunst.log" 2>&1 &
    dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify'" > "$OUT/notifications.log" 2>&1 &
    sleep 20      # KWin refuses to load effects during its first seconds in this bare container
    busctl --user call org.kde.KWin /KWin org.kde.KWin supportInformation | tr '\\' '\n' | grep -q "^nCompositing Type: OpenGL" \
        && ok "KWin composites with OpenGL" || bad "KWin is not using OpenGL: the effect cannot run here"

    # The user's own Night Light before the filter: on, 4200 K, mode never touched.
    kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature 4200
    kwriteconfig6 --file kwinrc --group NightColor --key Active --notify true
    sleep 2
    users_own && ok "Night Light before: the user's own" || bad "test setup: Night Light is $(nl)"
    PLAIN="255,0,0 0,255,0 0,0,255 128,128,128 255,255,255"
    expect "before: plain colours" "$(shot before)" "$PLAIN"

    bash /src/dist/readers-night-install.sh > "$OUT/install.txt" 2>&1 || bad "installer exit $?"
    cat "$OUT/install.txt"
    sleep 2
    [ "$(busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects isEffectLoaded s readersnight)" = "b true" ] && ok "effect loaded by KWin" || bad "effect not loaded"
    # Gray is taken on light itself here (luminance), then 70 % of the pixel value.
    expect "on: gray, 70 %" "$(shot on)" "88,88,88 153,153,153 54,54,54 90,90,90 178,178,178"
    [ "$(nl)" = "b true u 0 u 1900 " ] && ok "Night Light: on, constant, 1900 K" || bad "Night Light state: $(nl)"
    $RN status

    /usr/lib/qt6/bin/qml /scene/Late.qml > /dev/null 2>&1 &
    late=$!; sleep 3
    busctl --user call org.kde.KWin /org/kde/KWin/ScreenShot2 org.kde.KWin.ScreenShot2 CaptureWorkspace 'a{sv}h' 0 1 >/dev/null 2>&1
    blue="$(shot late | tr ' ' '\n' | cut -d, -f3 | sort -n | tail -1)"
    python3 -W ignore - "$OUT/late.png" <<'P' && ok "a window opened while the filter is on is gray too" || bad "a new window kept its colours"
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
sys.exit(0 if all(abs(r - g) <= 2 and abs(g - b) <= 2 for r, g, b in im.getdata()) else 1)
P
    kill $late 2>/dev/null; sleep 1

    $RN brightness 40
    expect "brightness 40 %" "$(shot dim40)" "49,49,49 87,87,87 28,28,28 50,50,50 101,101,101"
    $RN gray off
    expect "colours kept, 40 %" "$(shot colour40)" "102,0,0 0,102,0 0,0,102 51,51,51 102,102,102"
    $RN gray on; $RN brightness 70

    $RN off; sleep 3
    expect "off: plain colours again" "$(shot off)" "$PLAIN"
    users_own && ok "Night Light given back: on, 4200 K, its own mode" || bad "Night Light after off: $(nl)"
    grep -q "^Mode=" <(sed -n '/^\[NightColor\]/,/^\[/p' ~/.config/kwinrc) && bad "Night Light mode left written" || ok "Night Light mode left unwritten, as found"

    # The launcher in the application menu runs this line.
    exec_line="$(sed -n 's/^Exec=//p' ~/.local/share/applications/readers-night.desktop)"
    $exec_line; sleep 2
    expect "launcher switches on" "$(shot launcher-on)" "88,88,88 153,153,153 54,54,54 90,90,90 178,178,178"
    $exec_line; sleep 2

    # Plasma's Night Light switch in the tray: an inhibition held by a client. The
    # watcher (a systemd service on a real desktop) is run by hand here. The holder must
    # stay connected: KWin drops an inhibition when its client leaves the bus.
    $RN watcher-run > "$OUT/watcher.log" 2>&1 &
    watcher=$!; sleep 3
    python3 - <<'P' > "$OUT/inhibitor.log" 2>&1 &
import gi, time
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib
bus = Gio.bus_get_sync(Gio.BusType.SESSION)
bus.call_sync("org.kde.KWin", "/org/kde/KWin/NightLight", "org.kde.KWin.NightLight", "inhibit", None, None, 0, -1)
print("inhibiting", flush=True)
time.sleep(8)
P
    holder=$!; sleep 4
    nli() { busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight inhibited; }
    [ "$(nli)" = "b true" ] && ok "test setup: Night Light inhibited" || bad "test setup: Night Light not inhibited"
    expect "tray switch off: plain colours" "$(shot tray-off)" "$PLAIN"
    [ -e ~/.config/readers-night/paused-by-plasma ] && ok "watcher marked the pause" || bad "no pause mark"
    users_own && ok "Night Light given back while paused" || bad "Night Light while paused: $(nl)"
    wait $holder; sleep 4
    [ "$(nli)" = "b false" ] && ok "test setup: inhibition released" || bad "test setup: still inhibited"
    expect "tray switch on again: gray, 70 %" "$(shot tray-on)" "88,88,88 153,153,153 54,54,54 90,90,90 178,178,178"
    [ "$(nl)" = "b true u 0 u 1900 " ] && ok "Night Light taken again: constant 1900 K" || bad "Night Light after resume: $(nl)"
    [ ! -e ~/.config/readers-night/paused-by-plasma ] && ok "pause mark cleared" || bad "pause mark left"
    # Paused while the filter is off: the user's own business, the filter stays off.
    $RN off; sleep 1
    python3 - <<'P' > /dev/null 2>&1 &
import gi, time
gi.require_version("Gio", "2.0")
from gi.repository import Gio
bus = Gio.bus_get_sync(Gio.BusType.SESSION)
bus.call_sync("org.kde.KWin", "/org/kde/KWin/NightLight", "org.kde.KWin.NightLight", "inhibit", None, None, 0, -1)
time.sleep(5)
P
    holder=$!; sleep 3
    [ "$(busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects isEffectLoaded s readersnight)" = "b false" ] && [ ! -e ~/.config/readers-night/paused-by-plasma ] \
        && ok "a pause while off is left alone" || bad "a pause while off switched something"
    wait $holder; sleep 3
    [ "$(busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects isEffectLoaded s readersnight)" = "b false" ] && ok "resume while off: still off" || bad "resume while off switched on"
    kill $watcher 2>/dev/null; wait $watcher 2>/dev/null
    $RN on; sleep 2

    grep -c 'string "Night filter on"' "$OUT/notifications.log" | grep -q '^[2-9]' && ok "notifications sent for on" || bad "no notification for on"
    grep -q 'string "Night filter off"' "$OUT/notifications.log" && ok "notification sent for off" || bad "no notification for off"
    grep -q 'string "Gray and amber, brightness 70 %"' "$OUT/notifications.log" && ok "notification says the look" || bad "notification body missing"

    # Schedule: there is no systemd in this container, so only what the command decides
    # and writes is checked; the unit files are checked on the host afterwards.
    now="$(date +%H:%M)"; h="$(date +%H)"
    inside_on="$(printf '%02d:00' $(( (10#$h + 23) % 24 )))"; inside_off="$(printf '%02d:00' $(( (10#$h + 2) % 24 )))"
    $RN schedule "$inside_on" "$inside_off" 2>/dev/null; sleep 1
    [ "$(busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects isEffectLoaded s readersnight)" = "b true" ] && ok "schedule $inside_on-$inside_off at $now: on" || bad "schedule should have switched on"
    $RN schedule "$inside_off" "$inside_on" 2>/dev/null; sleep 1
    [ "$(busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects isEffectLoaded s readersnight)" = "b false" ] && ok "schedule $inside_off-$inside_on at $now: off" || bad "schedule should have switched off"
    $RN status
    cp ~/.config/systemd/user/readers-night-schedule.* "$OUT/" 2>/dev/null
    $RN schedule off
    [ ! -e ~/.config/systemd/user/readers-night-schedule.timer ] && ok "schedule removed" || bad "timer left behind"

    $RN on; sleep 1
    bash /src/dist/readers-night-install.sh --uninstall
    sleep 2
    expect "after uninstall: plain colours" "$(shot uninstalled)" "$PLAIN"
    [ ! -e ~/.local/share/kwin/effects/readersnight ] && [ ! -e "$RN" ] && [ ! -e ~/.local/share/applications/readers-night.desktop ] && [ ! -e ~/.config/readers-night ] \
        && ! grep -q -i readersnight ~/.config/kwinrc && ok "uninstall leaves nothing" || { bad "uninstall left something"; grep -i -n readersnight ~/.config/kwinrc; }
    users_own && ok "Night Light as the user had it" || bad "Night Light after uninstall: $(nl)"

    grep -i -E "readersnight|script.*error" "$OUT/kwin.log" | head -5
    [ $fail = 0 ] && echo "ALL OK" || echo "FAILED"
    chmod -R a+rwX /out
    return $fail
}
export -f inner; export OUT
dbus-run-session -- bash -c inner
