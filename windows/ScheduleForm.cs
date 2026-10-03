// The schedule dialog: a box to tick and two times.

using System;
using System.Drawing;
using System.Globalization;
using System.Windows.Forms;

namespace ReadersNight
{
    class ScheduleForm : Form
    {
        readonly CheckBox follow = new CheckBox { AutoSize = true };
        readonly DateTimePicker on = Picker();
        readonly DateTimePicker off = Picker();

        public bool Follow => follow.Checked;
        public string On => on.Value.ToString("HH:mm", CultureInfo.InvariantCulture);
        public string Off => off.Value.ToString("HH:mm", CultureInfo.InvariantCulture);

        public ScheduleForm(Settings s)
        {
            Text = Strings.AppName;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = MinimizeBox = false;
            ShowInTaskbar = true;
            StartPosition = FormStartPosition.CenterScreen;
            AutoScaleMode = AutoScaleMode.Font;
            Font = SystemFonts.MessageBoxFont;
            AutoSize = true;
            AutoSizeMode = AutoSizeMode.GrowAndShrink;
            Padding = new Padding(12);
            TopMost = true;

            follow.Text = Strings.Tr("schedFollow");
            follow.Checked = s.Schedule;
            on.Value = Time(s.ScheduleOn);
            off.Value = Time(s.ScheduleOff);
            follow.CheckedChanged += (o, e) => on.Enabled = off.Enabled = follow.Checked;
            on.Enabled = off.Enabled = follow.Checked;

            var grid = new TableLayoutPanel { AutoSize = true, ColumnCount = 2, Dock = DockStyle.Fill };
            grid.Controls.Add(follow, 0, 0);
            grid.SetColumnSpan(follow, 2);
            grid.Controls.Add(Label(Strings.Tr("schedOn")), 0, 1);
            grid.Controls.Add(on, 1, 1);
            grid.Controls.Add(Label(Strings.Tr("schedOff")), 0, 2);
            grid.Controls.Add(off, 1, 2);

            var ok = new Button { Text = Strings.Tr("ok"), DialogResult = DialogResult.OK, AutoSize = true };
            var cancel = new Button { Text = Strings.Tr("cancel"), DialogResult = DialogResult.Cancel, AutoSize = true };
            var buttons = new FlowLayoutPanel
            {
                FlowDirection = FlowDirection.RightToLeft, AutoSize = true, Dock = DockStyle.Fill,
                Margin = new Padding(0, 12, 0, 0),
            };
            buttons.Controls.Add(cancel);
            buttons.Controls.Add(ok);
            grid.Controls.Add(buttons, 0, 3);
            grid.SetColumnSpan(buttons, 2);

            Controls.Add(grid);
            AcceptButton = ok;
            CancelButton = cancel;
        }

        static DateTimePicker Picker() => new DateTimePicker
        {
            Format = DateTimePickerFormat.Custom,
            CustomFormat = "HH:mm",
            ShowUpDown = true,
            Width = 90,
            Margin = new Padding(3, 6, 3, 3),
        };

        static Label Label(string text) => new Label
        {
            Text = text, AutoSize = true, Anchor = AnchorStyles.Left, Margin = new Padding(20, 8, 12, 3),
        };

        static DateTime Time(string hhmm) =>
            DateTime.Today.AddHours(int.Parse(hhmm.Substring(0, 2))).AddMinutes(int.Parse(hhmm.Substring(3, 2)));
    }
}
