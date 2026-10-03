// The user's settings, one key=value per line in %APPDATA%\Readers Night Filter\settings.txt.
// Starting with Windows is the Run key of the registry, read and written where it lives.

using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Win32;

namespace ReadersNight
{
    class Settings
    {
        public bool Active = true;
        public bool Gray = true;
        public int Brightness = 70;
        public bool Notify = true;
        public bool Schedule = false;
        public string ScheduleOn = "21:30";
        public string ScheduleOff = "07:00";
        public bool Welcomed = false;

        public static readonly string Folder = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Readers Night Filter");
        static readonly string FilePath = Path.Combine(Folder, "settings.txt");

        public static Settings Load()
        {
            var s = new Settings();
            if (!File.Exists(FilePath)) return s;
            var d = new Dictionary<string, string>();
            foreach (var line in File.ReadAllLines(FilePath))
            {
                int eq = line.IndexOf('=');
                if (eq > 0) d[line.Substring(0, eq).Trim()] = line.Substring(eq + 1).Trim();
            }
            s.Active = Bool(d, "active", s.Active);
            s.Gray = Bool(d, "gray", s.Gray);
            s.Notify = Bool(d, "notify", s.Notify);
            s.Schedule = Bool(d, "schedule", s.Schedule);
            s.Welcomed = Bool(d, "welcomed", s.Welcomed);
            if (d.TryGetValue("brightness", out var b) && int.TryParse(b, out var n))
                s.Brightness = Math.Max(15, Math.Min(100, n));
            if (d.TryGetValue("schedule_on", out var on) && ValidTime(on)) s.ScheduleOn = on;
            if (d.TryGetValue("schedule_off", out var off) && ValidTime(off)) s.ScheduleOff = off;
            return s;
        }

        public void Save()
        {
            try
            {
                Directory.CreateDirectory(Folder);
                File.WriteAllLines(FilePath, new[]
                {
                    "active=" + Active.ToString().ToLowerInvariant(),
                    "gray=" + Gray.ToString().ToLowerInvariant(),
                    "brightness=" + Brightness,
                    "notify=" + Notify.ToString().ToLowerInvariant(),
                    "schedule=" + Schedule.ToString().ToLowerInvariant(),
                    "schedule_on=" + ScheduleOn,
                    "schedule_off=" + ScheduleOff,
                    "welcomed=" + Welcomed.ToString().ToLowerInvariant(),
                });
            }
            catch (Exception) { }  // a settings file that cannot be written is not worth a crash
        }

        static bool Bool(Dictionary<string, string> d, string key, bool fallback) =>
            d.TryGetValue(key, out var v) ? v == "true" : fallback;

        public static bool ValidTime(string t) =>
            t != null && t.Length == 5 && t[2] == ':'
            && int.TryParse(t.Substring(0, 2), out var h) && h >= 0 && h < 24
            && int.TryParse(t.Substring(3, 2), out var m) && m >= 0 && m < 60;

        static int Minutes(string t) => int.Parse(t.Substring(0, 2)) * 60 + int.Parse(t.Substring(3, 2));

        // Is the clock inside the "on" span? The span may cross midnight.
        public bool InSpan(DateTime now)
        {
            int n = now.Hour * 60 + now.Minute, on = Minutes(ScheduleOn), off = Minutes(ScheduleOff);
            return on <= off ? n >= on && n < off : n >= on || n < off;
        }

        // --- start with Windows ---------------------------------------------------

        const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
        const string RunName = "Readers Night Filter";

        static string Command => "\"" + System.Windows.Forms.Application.ExecutablePath + "\" --startup";

        public static bool StartsWithWindows
        {
            get
            {
                using (var key = Registry.CurrentUser.OpenSubKey(RunKey))
                    return key?.GetValue(RunName) is string;
            }
            set
            {
                using (var key = Registry.CurrentUser.CreateSubKey(RunKey))
                {
                    if (value) key.SetValue(RunName, Command);
                    else key.DeleteValue(RunName, false);
                }
            }
        }

        // The .exe may have been moved since the key was written: point it here again.
        public static void RefreshStartupPath()
        {
            if (StartsWithWindows) StartsWithWindows = true;
        }
    }
}
