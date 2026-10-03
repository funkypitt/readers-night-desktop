// The app: a crescent in the notification area. A click switches the filter, a right
// click opens the settings. Win+Shift+N and launching the .exe a second time switch it
// too.

using System;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Win32;

namespace ReadersNight
{
    class TrayApp : ApplicationContext
    {
        static readonly int[] Levels = { 100, 90, 80, 70, 60, 50, 40, 30, 20, 15 };
        const string ShortcutName = "Win+Shift+N";

        readonly Settings settings = Settings.Load();
        readonly NotifyIcon icon = new NotifyIcon();
        readonly ContextMenuStrip menu = new ContextMenuStrip();
        readonly Icon onIcon = LoadIcon("on.ico"), offIcon = LoadIcon("off.ico");
        readonly HotkeyWindow hotkey;
        readonly Timer keep = new Timer { Interval = 2000 };
        readonly Timer clock = new Timer { Interval = 15000 };
        bool lastSpan;
        bool failureShown;
        ScheduleForm scheduleForm;

        // The control that the second instance's signal is marshalled through.
        public readonly Control Invoker = new Control();

        public TrayApp()
        {
            var _ = Invoker.Handle;  // created now, on this thread, so BeginInvoke has a window to post to
            Settings.RefreshStartupPath();

            hotkey = new HotkeyWindow(Toggle);

            icon.ContextMenuStrip = menu;
            menu.Opening += (o, e) => BuildMenu();
            icon.MouseClick += (o, e) => { if (e.Button == MouseButtons.Left) Toggle(); };

            if (settings.Schedule)
            {
                lastSpan = settings.InSpan(DateTime.Now);
                settings.Active = lastSpan;
            }
            Apply();
            UpdateIcon();
            icon.Visible = true;

            if (!settings.Welcomed)
            {
                settings.Welcomed = true;
                Settings.StartsWithWindows = true;
                settings.Save();
                icon.ShowBalloonTip(10000, Strings.Tr("welcome"), Strings.Tr("welcomeBody", ShortcutName), ToolTipIcon.None);
            }

            keep.Tick += (o, e) => Reassert();
            keep.Start();
            clock.Tick += (o, e) => FollowSchedule();
            clock.Start();

            SystemEvents.DisplaySettingsChanged += OnSystemChange;
            SystemEvents.SessionSwitch += OnSystemChange;
            SystemEvents.PowerModeChanged += OnPowerChange;
        }

        // --- the filter --------------------------------------------------------------

        float[] Wanted => settings.Active ? Filter.Matrix(settings.Gray, settings.Brightness) : Filter.Identity();

        void Apply()
        {
            bool ok = Filter.Set(Wanted);
            if (!ok && settings.Active && !failureShown)
            {
                failureShown = true;
                icon.ShowBalloonTip(8000, Strings.Tr("failed"), Strings.Tr("failedBody"), ToolTipIcon.Warning);
            }
            if (ok) failureShown = false;
        }

        // Windows sometimes drops the effect (the Magnifier, a display change, the lock
        // screen); it is set again when what is on screen is not what was asked.
        void Reassert()
        {
            if (!settings.Active) return;
            if (!Filter.Same(Filter.Current(), Wanted)) Apply();
        }

        void SwitchTo(bool active)
        {
            if (settings.Active == active) return;
            settings.Active = active;
            settings.Save();
            Apply();
            UpdateIcon();
            Announce();
        }

        public void Toggle() => SwitchTo(!settings.Active);

        void Announce()
        {
            if (!settings.Notify) return;
            string look = Strings.Tr(settings.Gray ? "lookGray" : "lookColour", settings.Brightness);
            // A balloon cannot have an empty text: when off, it names the app.
            icon.ShowBalloonTip(3000, Strings.Tr(settings.Active ? "on" : "off"),
                settings.Active ? look : Strings.AppName, ToolTipIcon.None);
        }

        void UpdateIcon()
        {
            icon.Icon = settings.Active ? onIcon : offIcon;
            string text = Strings.AppName + " — " + Strings.Tr(settings.Active ? "on" : "off");
            icon.Text = text.Length > 63 ? text.Substring(0, 63) : text;
        }

        // --- the schedule: on at the first time, off at the second -------------------

        void FollowSchedule()
        {
            if (!settings.Schedule) return;
            bool span = settings.InSpan(DateTime.Now);
            if (span != lastSpan)
            {
                lastSpan = span;
                SwitchTo(span);
            }
        }

        void OnSystemChange(object sender, EventArgs e)
        {
            Invoker.BeginInvoke((Action)(() => { if (settings.Active) Apply(); }));
        }

        void OnPowerChange(object sender, PowerModeChangedEventArgs e)
        {
            if (e.Mode != PowerModes.Resume) return;
            Invoker.BeginInvoke((Action)(() =>
            {
                if (settings.Active) Apply();
                FollowSchedule();
            }));
        }

        void EditSchedule()
        {
            if (scheduleForm != null) { scheduleForm.Activate(); return; }
            using (scheduleForm = new ScheduleForm(settings))
            {
                if (scheduleForm.ShowDialog() == DialogResult.OK)
                {
                    settings.Schedule = scheduleForm.Follow;
                    settings.ScheduleOn = scheduleForm.On;
                    settings.ScheduleOff = scheduleForm.Off;
                    settings.Save();
                    if (settings.Schedule)
                    {
                        lastSpan = settings.InSpan(DateTime.Now);
                        SwitchTo(lastSpan);
                    }
                }
            }
            scheduleForm = null;
        }

        // --- the menu ----------------------------------------------------------------

        void BuildMenu()
        {
            menu.Items.Clear();

            var main = new ToolStripMenuItem(Strings.Tr("switch")) { Checked = settings.Active };
            main.Font = new Font(main.Font, FontStyle.Bold);
            main.Click += (o, e) => Toggle();
            menu.Items.Add(main);
            menu.Items.Add(new ToolStripSeparator());

            var gray = new ToolStripMenuItem(Strings.Tr("gray")) { Checked = settings.Gray };
            gray.Click += (o, e) => { settings.Gray = !settings.Gray; Changed(); };
            menu.Items.Add(gray);

            var brightness = new ToolStripMenuItem(Strings.Tr("brightness"));
            foreach (int level in Levels)
            {
                int l = level;
                var item = new ToolStripMenuItem(l + " %") { Checked = settings.Brightness == l };
                item.Click += (o, e) => { settings.Brightness = l; Changed(); };
                brightness.DropDownItems.Add(item);
            }
            menu.Items.Add(brightness);

            var notify = new ToolStripMenuItem(Strings.Tr("notify")) { Checked = settings.Notify };
            notify.Click += (o, e) => { settings.Notify = !settings.Notify; settings.Save(); };
            menu.Items.Add(notify);

            string schedText = settings.Schedule
                ? Strings.Tr("scheduleSet", settings.ScheduleOn, settings.ScheduleOff)
                : Strings.Tr("schedule");
            var schedule = new ToolStripMenuItem(schedText);
            schedule.Click += (o, e) => EditSchedule();
            menu.Items.Add(schedule);

            var startup = new ToolStripMenuItem(Strings.Tr("startup")) { Checked = Settings.StartsWithWindows };
            startup.Click += (o, e) => Settings.StartsWithWindows = !Settings.StartsWithWindows;
            menu.Items.Add(startup);

            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add(new ToolStripMenuItem(
                Strings.Tr(hotkey.Registered ? "shortcut" : "shortcutTaken", ShortcutName)) { Enabled = false });
            menu.Items.Add(new ToolStripSeparator());

            var quit = new ToolStripMenuItem(Strings.Tr("quit"));
            quit.Click += (o, e) => ExitThread();
            menu.Items.Add(quit);
        }

        // A setting of the look changed: shown at once if the filter is on, announced if
        // notifications are on (the look is what the notification describes).
        void Changed()
        {
            settings.Save();
            if (!settings.Active) return;
            Apply();
            Announce();
        }

        protected override void ExitThreadCore()
        {
            SystemEvents.DisplaySettingsChanged -= OnSystemChange;
            SystemEvents.SessionSwitch -= OnSystemChange;
            SystemEvents.PowerModeChanged -= OnPowerChange;
            keep.Stop();
            clock.Stop();
            hotkey.Dispose();
            icon.Visible = false;
            icon.Dispose();
            Filter.Shutdown();
            base.ExitThreadCore();
        }

        static Icon LoadIcon(string name)
        {
            using (var stream = typeof(TrayApp).Assembly.GetManifestResourceStream(name))
                return new Icon(stream, SystemInformation.SmallIconSize);
        }
    }

    // A hidden window that receives the global keyboard shortcut.
    class HotkeyWindow : NativeWindow, IDisposable
    {
        [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
        static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint vk);

        [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
        static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        const int WM_HOTKEY = 0x0312;
        const uint MOD_SHIFT = 0x4, MOD_WIN = 0x8, MOD_NOREPEAT = 0x4000;
        const uint VK_N = 0x4E;

        readonly Action pressed;
        public readonly bool Registered;

        public HotkeyWindow(Action pressed)
        {
            this.pressed = pressed;
            CreateHandle(new CreateParams());
            Registered = RegisterHotKey(Handle, 1, MOD_WIN | MOD_SHIFT | MOD_NOREPEAT, VK_N);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WM_HOTKEY) pressed();
            base.WndProc(ref m);
        }

        public void Dispose()
        {
            if (Registered) UnregisterHotKey(Handle, 1);
            DestroyHandle();
        }
    }
}
