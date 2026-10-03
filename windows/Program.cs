// Reader's Night Filter for Windows.
//
//   ReadersNight.exe                 starts the app; if it is already running, switches the filter
//   ReadersNight.exe --startup       what Windows runs at login; does nothing if already running
//   ReadersNight.exe --self-test F   checks the screen effect and writes what it found into F

using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Windows.Forms;

namespace ReadersNight
{
    static class Program
    {
        const string InstanceName = @"Local\ReadersNightFilter";
        const string ToggleName = @"Local\ReadersNightFilter.Toggle";

        [STAThread]
        static int Main(string[] args)
        {
            if (args.Length >= 2 && args[0] == "--self-test")
                return SelfTest(args[1]);

            using (var instance = new Mutex(true, InstanceName, out bool first))
            {
                if (!first)
                {
                    if (Array.IndexOf(args, "--startup") < 0 && EventWaitHandle.TryOpenExisting(ToggleName, out var other))
                        using (other) other.Set();
                    return 0;
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                var app = new TrayApp();

                using (var toggle = new EventWaitHandle(false, EventResetMode.AutoReset, ToggleName))
                {
                    var wait = ThreadPool.RegisterWaitForSingleObject(toggle,
                        (state, timedOut) => app.Invoker.BeginInvoke((Action)app.Toggle),
                        null, Timeout.Infinite, false);
                    Application.Run(app);
                    wait.Unregister(null);
                }
                GC.KeepAlive(instance);
            }
            return 0;
        }

        // Sets a few matrices, reads each back from Windows, and checks the schedule
        // arithmetic. Exit code 0 when everything held.
        static int SelfTest(string reportPath)
        {
            var report = new List<string>();
            bool ok = true;

            void Check(string what, bool result)
            {
                report.Add((result ? "ok   " : "FAIL ") + what);
                ok &= result;
            }

            report.Add("Windows " + Environment.OSVersion.Version + (Environment.Is64BitProcess ? ", 64-bit process" : ", 32-bit process"));
            Check("64-bit process", Environment.Is64BitProcess);
            Check("MagInitialize", Filter.Initialize());

            var cases = new (string, float[])[]
            {
                ("gray and amber at 70 %", Filter.Matrix(true, 70)),
                ("amber at 40 %", Filter.Matrix(false, 40)),
                ("identity", Filter.Identity()),
            };
            foreach (var (name, matrix) in cases)
            {
                Check("set " + name, Filter.Set(matrix));
                var back = Filter.Current();
                Check("read back " + name, Filter.Same(back, matrix));
                if (back != null) report.Add("     " + string.Join(" ", Array.ConvertAll(back, v => v.ToString("0.####"))));
            }

            // Gray and amber at 100 %: white stays (1, 0.5167, 0), pure blue becomes a dim amber.
            var m = Filter.Matrix(true, 100);
            float r = m[0] + m[5] + m[10], g = m[1] + m[6] + m[11], b = m[2] + m[7] + m[12];
            Check("white → amber", Math.Abs(r - 1f) < 1e-3 && Math.Abs(g - 0.5167f) < 1e-3 && b == 0f);
            Check("no blue out of any input", m[2] == 0f && m[7] == 0f && m[12] == 0f);

            var s = new Settings { ScheduleOn = "21:30", ScheduleOff = "07:00" };
            Check("schedule across midnight", s.InSpan(DateTime.Today.AddHours(23)) && s.InSpan(DateTime.Today.AddHours(6.9))
                && !s.InSpan(DateTime.Today.AddHours(12)) && !s.InSpan(DateTime.Today.AddHours(7)));
            s.ScheduleOn = "08:00"; s.ScheduleOff = "18:00";
            Check("schedule within a day", s.InSpan(DateTime.Today.AddHours(9)) && !s.InSpan(DateTime.Today.AddHours(19)));

            Filter.Shutdown();
            report.Add(ok ? "all good" : "something failed");
            File.WriteAllLines(reportPath, report);
            return ok ? 0 : 1;
        }
    }
}
