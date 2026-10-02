import Adw from 'gi://Adw';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';

import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

import {tr} from './strings.js';

export default class ReadersNightPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();
        const page = new Adw.PreferencesPage();
        const group = new Adw.PreferencesGroup({description: tr('prefLimits')});
        page.add(group);
        window.add(page);

        const switchRow = (key, title, subtitle) => {
            const row = new Adw.SwitchRow({title: tr(title), subtitle: tr(subtitle)});
            settings.bind(key, row, 'active', Gio.SettingsBindFlags.DEFAULT);
            group.add(row);
            return row;
        };

        switchRow('active', 'prefSwitch', 'prefSwitchSub');
        switchRow('grayscale', 'prefGray', 'prefGraySub');

        const brightness = new Adw.SpinRow({
            title: tr('prefBrightness'),
            subtitle: tr('prefBrightnessSub'),
            adjustment: new Gtk.Adjustment({lower: 15, upper: 100, step_increment: 5, page_increment: 10}),
        });
        settings.bind('brightness', brightness, 'value', Gio.SettingsBindFlags.DEFAULT);
        group.add(brightness);

        switchRow('notify', 'prefNotify', 'prefNotifySub');

        const [accelerator] = settings.get_strv('toggle-shortcut');
        const [, key, mods] = accelerator ? Gtk.accelerator_parse(accelerator) : [false, 0, 0];
        const shortcut = new Adw.ActionRow({title: tr('prefShortcut')});
        shortcut.add_suffix(new Gtk.Label({
            label: key ? Gtk.accelerator_get_label(key, mods) : '',
            css_classes: ['dim-label'],
        }));
        group.add(shortcut);
    }
}
