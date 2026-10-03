# Notes

## The numbers

`tools/amber.py` holds them and generates the browser files. Tint = black body at
1900 K by Tanner Helland's fit: (1, 0.5167, 0). KWin's own table (read out of
`nightlight.so`, 6.7.4) gives (1, 0.5194, 0) at 1900 K and its first blue at 2000 K, so
Plasma's Night Light at 1900 K is the same amber to within a rounding.

Gray and brightness are applied to stored pixel values in the browser and on GNOME
(the same arithmetic as CSS `grayscale()` and `brightness()`). KWin works on light
itself: its gray is true luminance (a pure red comes out lighter than in the other
two), and the effect raises the brightness setting to the power 2.2 so that 70 % still
turns white into 70 % gray.

## Browser

- The filter is an SVG `feColorMatrix` referenced from CSS as a data URL, on the root
  element. On the root a filter covers frames, video and fixed elements.
- An SVG filter only covers a region around the element's box. The root box of a short
  page ends under its last line and Chromium leaves the rest of the window unfiltered,
  so the region is spelled out, far larger than any page.
- A page with no background at all is drawn on the bare canvas, which no filter reaches.
  The stylesheet gives the root the `Canvas` colour at zero specificity, and `content.js`
  lifts it when the body has its own background (which the browser only spreads over
  the window while the root has none).
- The stylesheet is registered by the background worker, so the browser injects it
  before a page's first paint. Settings other than the usual ones are written on the
  root's own style by `content.js`, a moment later.
- In headless Chromium, a tab behind another one keeps the area below a short page as
  it last drew it when the brightness changes. Not seen on the tab in front.

## GNOME

- One `Shell.GLSLEffect` on `Main.uiGroup`.
- The effect's pipeline multiplies by alpha when it draws, and the wallpaper arrives
  with an alpha of 0: the shader sets alpha to 1.
- An offscreen effect reuses the picture it drew while its actor is unchanged, but
  windows and wallpaper only draw the part a frame needs. Reused for a larger area
  (full redraw, screenshot) the kept picture shows black. The effect overrides `paint`
  to always redraw. Found with the Xorg test, which reads the X server's real output.
- `Shell.SnippetHook` is `Cogl.SnippetHook` in later versions (seen on GNOME 50).
- A new extension is only found by a running Shell at the next login.
- Tested on GNOME 46 (Ubuntu 24.04, Xorg and Wayland) and GNOME 50 (Ubuntu 26.04,
  Wayland).

## Plasma

- KWin 6.7 has no grayscale among its colour filters, and a scripted effect has no call
  to put its own shader on a window outside an animation. The effect therefore uses the
  two adjustments KWin's window painting offers, saturation and brightness, held with
  `set()`; the tint is left to Night Light, which acts on the whole output.
- `effect.readConfig()` returns the default unless the package has a
  `contents/config/main.xml`.
- `reconfigureEffect` makes a loaded effect reread its settings.
- `loadEffect` answers false while already loaded, and during the first seconds of a
  KWin started in a bare container.
- Night Light follows `kwinrc` when a key is written with `kwriteconfig6 --notify`; an
  unchanged value notifies nothing, so every key is written that way.
- Screenshots are taken before Night Light is applied: its colour cannot be tested
  that way, only its state over D-Bus.
- Tested on KWin 6.7.4 (Manjaro), virtual output, OpenGL through the host's Intel render
  device.

## Windows

- `MagSetFullscreenColorEffect`, the Magnification API's colour matrix over the whole
  screen: no administrator rights, no `uiAccess`. Gray, tint and dim are one 5×5 matrix
  on row vectors ([r g b a 1] × M), the same arithmetic as GNOME's shader.
- 64-bit process only: the API is not available to 32-bit programs on 64-bit Windows
  (AnyCPU with Prefer32Bit off).
- The effect belongs to the process: Windows removes it when the process ends, crash
  included. A timer sets it again every 2 s if what Windows reports differs.
- .NET Framework 4.8 (part of Windows 10 1903+ and 11): a 70 KB .exe, nothing to install.
  Built from Linux too, in the `mcr.microsoft.com/dotnet/sdk` image.
- Second instance: a named mutex; the second copy sets a named event and quits, the first
  toggles.
- On the runner (Windows Server 2025, 10.0.26100) the matrices set are read back exactly.

## macOS

- Tint and dim: `CGSetDisplayTransferByTable`, the system's own curves (read after
  `CGDisplayRestoreColorSyncSettings`) multiplied per channel. macOS restores them when
  the app quits. They are set again after a display change, a wake, and whenever a
  2-second check finds them gone.
- Gray: `CGDisplayForceToGray` / `CGDisplayUsesForceToGray`, private CoreGraphics
  functions looked up with `dlsym`; the same switch as Accessibility's grayscale. Accepted
  on the runners' macOS 15.7 and 26.6. It outlives the app, so `grayForcedByUs` is kept
  in the settings and a start after a crash turns it off again; a grayscale the user had
  on already is left alone.
- Which comes first on screen, the gray or the tables, is not visible from the runner
  (screenshots show neither). If the tables come first, the gray of amber is a plain gray.
- Shortcut through Carbon's `RegisterEventHotKey`, which needs no Accessibility permission.
- Universal binary (arm64 + x86_64) from one `swiftc` file, ad hoc signed.

## Not tested

Windows and macOS on a real screen (the runners have none: the self-tests prove the
system accepted the colours, not how they look), HDR on either, several monitors on
macOS. On Linux: a real laptop panel, a real Plasma session (panel, Overview, lock screen), fractional
scaling, several monitors, the systemd timer actually firing, GNOME 47 to 49, Brave
itself (the tests drive Chromium).
