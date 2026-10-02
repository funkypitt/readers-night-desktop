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

## Not tested

A real laptop panel, a real Plasma session (panel, Overview, lock screen), fractional
scaling, several monitors, the systemd timer actually firing, GNOME 47 to 49, Brave
itself (the tests drive Chromium).
