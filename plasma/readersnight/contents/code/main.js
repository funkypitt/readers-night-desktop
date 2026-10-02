/*
    Reader's Night Filter for KWin.

    This effect is the gray and the dimming: every window is drawn without colour
    and darker, through the two adjustments KWin's own window painting offers. The
    amber tint is not here: the `readers-night` command sets Plasma's Night Light to
    a constant 1900 K, which acts on the whole output (pointer, overview and lock
    screen included) and already has no blue.

    Loaded = on. The command loads and unloads the effect.
*/

"use strict";

var readersNight = {
    loadConfig: function () {
        readersNight.gray = effect.readConfig("Grayscale", true);
        const percent = Math.min(100, Math.max(15, effect.readConfig("Brightness", 70)));
        // KWin applies brightness to light itself, not to the stored pixel values
        // (gamma 2.2 between the two). The setting is meant on pixel values, like in
        // the browser and GNOME versions: 70 % turns white into 70 % gray.
        readersNight.brightness = Math.pow(percent / 100, 2.2);
    },
    cover: function (window) {
        readersNight.uncover(window);
        const animations = [];
        if (readersNight.gray) {
            animations.push({ type: Effect.Saturation, to: 0.0 });
        }
        if (readersNight.brightness < 1.0) {
            animations.push({ type: Effect.Brightness, to: readersNight.brightness });
        }
        if (animations.length === 0) {
            return;
        }
        // set() holds its end value until cancelled. The window must not be kept
        // alive by it, or a closed window would stay on the screen.
        window.readersNightAnimation = set({
            window: window,
            duration: 1,
            keepAlive: false,
            animations: animations
        });
        complete(window.readersNightAnimation);
    },
    uncover: function (window) {
        if (window.readersNightAnimation) {
            cancel(window.readersNightAnimation);
            delete window.readersNightAnimation;
        }
    },
    coverAll: function () {
        for (const window of effects.stackingOrder) {
            readersNight.cover(window);
        }
    },
    init: function () {
        readersNight.loadConfig();
        effect.configChanged.connect(function () {
            readersNight.loadConfig();
            readersNight.coverAll();
        });
        effects.windowAdded.connect(readersNight.cover);
        readersNight.coverAll();
    }
};

readersNight.init();
