// Reader's Night Filter for GNOME Shell.
//
// One effect on the group that holds everything the Shell draws (windows, panel,
// overview, lock screen): gray, then the amber tint, then dimmed. The switch is a
// GSettings key, so the quick-settings toggle, the keyboard shortcut and the
// `readers-night` command all go through the same place, and the notification is
// sent from there whoever flipped it.

import Clutter from 'gi://Clutter';
import Cogl from 'gi://Cogl';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as QuickSettings from 'resource:///org/gnome/shell/ui/quickSettings.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

import {tr} from './strings.js';

const EFFECT_NAME = 'readers-night';

// Amber: a black body at 1900 K, the coolest that has no blue (see tools/amber.py).
const TINT = [1.0, 0.5167, 0.0];

const AmberEffect = GObject.registerClass(
class AmberEffect extends Shell.GLSLEffect {
    vfunc_build_pipeline() {
        const declarations = 'uniform vec3 rn_tint;\nuniform float rn_gray;';
        // Colours arrive premultiplied by alpha; every step here is linear, so they
        // stay correct. The alpha is then set to 1: this effect's pipeline multiplies
        // by it once more when drawing, and the wallpaper arrives with an alpha of 0
        // (it is drawn opaque, without blending), so it would vanish. The group covers
        // the whole screen with nothing behind it; opaque is what it is.
        const code = `
            vec3 rn_c = cogl_color_out.rgb;
            float rn_l = dot(rn_c, vec3(0.2126, 0.7152, 0.0722));
            rn_c = mix(rn_c, vec3(rn_l), rn_gray);
            cogl_color_out = vec4(rn_c * rn_tint, 1.0);`;
        // The name of this constant moved from Shell to Cogl in later GNOME versions.
        const hook = (Shell.SnippetHook ?? Cogl.SnippetHook).FRAGMENT;
        this.add_glsl_snippet(hook, declarations, code, false);
    }

    // An offscreen effect keeps the picture it drew and reuses it while its actor has
    // not changed. But the windows and the wallpaper only draw the part of themselves
    // that the current frame needs, so a kept picture is whole only by luck: reused for
    // a larger area (a full redraw, a screenshot) it shows black where nothing was
    // drawn. Never reuse it: draw afresh for the area each frame asks for.
    vfunc_paint(node, paintContext, flags) {
        super.vfunc_paint(node, paintContext, flags | Clutter.EffectPaintFlags.ACTOR_DIRTY);
    }

    setLook(gray, brightness) {
        const dim = brightness / 100;
        this.set_uniform_float(this.get_uniform_location('rn_tint'), 3, TINT.map(v => v * dim));
        this.set_uniform_float(this.get_uniform_location('rn_gray'), 1, [gray ? 1.0 : 0.0]);
        this.queue_repaint();
    }
});

const NightToggle = GObject.registerClass(
class NightToggle extends QuickSettings.QuickToggle {
    constructor(settings, gicon) {
        super({title: tr('title'), gicon, toggleMode: true});
        settings.bind('active', this, 'checked', Gio.SettingsBindFlags.DEFAULT);
    }
});

const NightIndicator = GObject.registerClass(
class NightIndicator extends QuickSettings.SystemIndicator {
    constructor(settings, gicon) {
        super();
        this._icon = this._addIndicator();
        this._icon.gicon = gicon;
        settings.bind('active', this._icon, 'visible', Gio.SettingsBindFlags.GET);
        this.quickSettingsItems.push(new NightToggle(settings, gicon));
    }

    destroy() {
        this.quickSettingsItems.forEach(item => item.destroy());
        super.destroy();
    }
});

export default class ReadersNightExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._effect = null;

        const gicon = Gio.icon_new_for_string(`${this.path}/icons/readers-night-symbolic.svg`);
        this._indicator = new NightIndicator(this._settings, gicon);
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);

        Main.wm.addKeybinding('toggle-shortcut', this._settings,
            Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
            () => this._settings.set_boolean('active', !this._settings.get_boolean('active')));

        this._changed = this._settings.connect('changed', (_settings, key) => {
            if (key === 'active') {
                this._apply();
                this._announce();
            } else if (key === 'grayscale' || key === 'brightness') {
                this._apply();
            }
        });
        // No notification here: the filter coming back at login is not news.
        this._apply();
    }

    disable() {
        // Locking the screen does not come through here: the extension lists the unlock
        // dialog among its session modes, so that the lock screen stays filtered too.
        this._settings.disconnect(this._changed);
        Main.wm.removeKeybinding('toggle-shortcut');
        this._remove();
        this._indicator.destroy();
        this._indicator = null;
        this._settings = null;
    }

    _apply() {
        if (!this._settings.get_boolean('active')) {
            this._remove();
            return;
        }
        try {
            if (!this._effect) {
                this._effect = new AmberEffect();
                Main.uiGroup.add_effect_with_name(EFFECT_NAME, this._effect);
                // A full-screen window handed straight to the display would skip the filter.
                this._unredirect(false);
            }
            this._effect.setLook(
                this._settings.get_boolean('grayscale'),
                this._settings.get_int('brightness'));
        } catch (e) {
            console.error(`readers-night: ${e}`);
            this._remove();
            Main.notify(tr('failed'), tr('failedBody'));
        }
    }

    _remove() {
        if (!this._effect)
            return;
        Main.uiGroup.remove_effect(this._effect);
        this._effect = null;
        this._unredirect(true);
    }

    _unredirect(allowed) {
        try {
            if (global.compositor?.disable_unredirect) {
                if (allowed)
                    global.compositor.enable_unredirect();
                else
                    global.compositor.disable_unredirect();
            } else if (allowed) {
                Meta.enable_unredirect_for_display(global.display);
            } else {
                Meta.disable_unredirect_for_display(global.display);
            }
        } catch (e) {
            console.debug(`readers-night: unredirect: ${e}`);
        }
    }

    _announce() {
        if (!this._settings.get_boolean('notify'))
            return;
        if (!this._settings.get_boolean('active')) {
            Main.notify(tr('off'), '');
        } else if (this._effect) {
            const look = this._settings.get_boolean('grayscale') ? 'lookGray' : 'lookColour';
            Main.notify(tr('on'), tr(look, this._settings.get_int('brightness')));
        }
    }
}
