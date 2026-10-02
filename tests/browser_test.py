#!/usr/bin/env python3
"""Loads the extension in a real Chromium and reads pixels back.

    python3 tests/browser_test.py [--shots DIR]

Needs Playwright with its Chromium (`playwright install chromium`).
"""
import asyncio
import http.server
import io
import pathlib
import sys
import tempfile
import threading

from PIL import Image
from playwright.async_api import async_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXT = ROOT / "browser"
SHOTS = pathlib.Path(sys.argv[sys.argv.index("--shots") + 1]) if "--shots" in sys.argv else None

HEAD_PROBE = "<script>window.firstFilter = getComputedStyle(document.documentElement).filter;</script>"
PAGES = {
    "/bare": HEAD_PROBE + "<p>no background anywhere</p>",
    "/bodyblue": "<style>body{background:#00f}</style><p>short blue body</p>",
    "/htmlgreen": "<style>html{background:#0f0}</style><p>green root</p>",
    "/darkscheme": "<meta name='color-scheme' content='dark'><p>dark scheme, no background</p>",
    "/boxes": "<style>body{margin:0;background:#fff}div{width:100px;height:100px}</style>"
              "<div style='background:#f00'></div><div style='background:#0f0'></div>",
    "/tall": "<style>html,body{height:100%;margin:0}div{height:3000px;background:#f00}</style><div></div>",
    "/wide": "<style>body{margin:0}div{width:3000px;height:100px;background:#f00}</style><div></div>",
    "/floating": "<style>body{margin:0}div{position:absolute;left:0;top:0;width:100px;height:100px;background:#f00}</style><div></div>",
    "/fixed": "<style>body{margin:0;height:3000px;background:#fff}"
              "#f{position:fixed;left:0;bottom:0;width:60px;height:60px;background:#000}</style><div id='f'></div>",
}


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = ("<!doctype html><title>t</title>" + PAGES.get(self.path, "")).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


failures = []


def check(name, got, want, tol=3):
    ok = all(abs(g - w) <= tol for g, w in zip(got, want))
    print(("ok   " if ok else "FAIL ") + f"{name}: {got} (want {want})")
    if not ok:
        failures.append(name)


async def pixel(page, x, y):
    im = Image.open(io.BytesIO(await page.screenshot())).convert("RGB")
    return im.getpixel((x, y))


async def main():
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{server.server_port}"

    async with async_playwright() as p:
        ctx = await p.chromium.launch_persistent_context(
            tempfile.mkdtemp(), channel="chromium", headless=True,
            viewport={"width": 400, "height": 300},
            args=[f"--disable-extensions-except={EXT}", f"--load-extension={EXT}"],
        )
        worker = ctx.service_workers[0] if ctx.service_workers else await ctx.wait_for_event("serviceworker")
        ext_id = worker.url.split("/")[2]

        async def setting(**values):
            await worker.evaluate("v => chrome.storage.local.set(v)", values)
            await asyncio.sleep(0.6)

        async def open_(path):
            page = await ctx.new_page()
            await page.goto(base + path)
            await asyncio.sleep(0.3)
            return page

        await asyncio.sleep(1)  # let onInstalled register the stylesheet

        # Amber at 70 %: white -> (255*.7, 255*.5167*.7, 0)
        page = await open_("/bare")
        check("no background at all", await pixel(page, 390, 290), (178, 92, 0))
        first = await page.evaluate("window.firstFilter")
        print(("ok   " if first and first != "none" else "FAIL ") + "filter present before the page's first script: " + str(first)[:40])
        if not first or first == "none":
            failures.append("pre-paint")
        bare = page

        page = await open_("/bodyblue")
        check("short body with its own background fills the window", await pixel(page, 390, 290), (13, 7, 0))
        page = await open_("/htmlgreen")
        check("the page's own root background wins", await pixel(page, 390, 290), (128, 66, 0))
        page = await open_("/darkscheme")
        got = await pixel(page, 390, 290)
        print(("ok   " if max(got) < 40 and got[2] == 0 else "FAIL ") + f"dark colour scheme stays dark: {got}")
        if not (max(got) < 40 and got[2] == 0):
            failures.append("darkscheme")

        boxes = await open_("/boxes")
        check("gray: red box", await pixel(boxes, 50, 50), (38, 20, 0))
        check("gray: green box", await pixel(boxes, 50, 150), (128, 66, 0))

        tall = await open_("/tall")
        await tall.evaluate("window.scrollTo(0, 2000)")
        check("content overflowing a 100 % root, far down", await pixel(tall, 200, 150), (38, 20, 0))
        wide = await open_("/wide")
        await wide.evaluate("window.scrollTo(2000, 0)")
        check("content overflowing sideways", await pixel(wide, 200, 50), (38, 20, 0))
        floating = await open_("/floating")
        check("root with no height: content", await pixel(floating, 50, 50), (38, 20, 0))
        check("root with no height: rest of the window", await pixel(floating, 390, 290), (178, 92, 0))

        fixed = await open_("/fixed")
        await fixed.evaluate("window.scrollTo(0, 1500)")
        await asyncio.sleep(0.2)
        check("fixed element still pinned to the window after scrolling", await pixel(fixed, 30, 270), (0, 0, 0))
        check("... with the page around it", await pixel(fixed, 200, 270), (178, 92, 0))

        await setting(gray=False)
        check("colours kept: red box", await pixel(boxes, 50, 50), (178, 0, 0))
        check("colours kept: green box", await pixel(boxes, 50, 150), (0, 92, 0))
        await setting(gray=True)
        front = await open_("/bare")
        await setting(dim=40)
        check("brightness 40 %, page in front", await pixel(front, 390, 290), (102, 53, 0))
        # Not checked on a tab behind another one: headless Chromium keeps the part of the
        # window below a short page as it last drew it until that tab is shown again.
        check("brightness 40 %: boxes page", await pixel(boxes, 50, 150), (73, 38, 0))
        await setting(gray=False)
        check("brightness 40 %, colours kept", await pixel(boxes, 50, 150), (0, 53, 0))
        await setting(gray=True, dim=70)
        check("back to the usual look", await pixel(bare, 390, 290), (178, 92, 0))

        # Off: open pages go back to normal without a reload, new ones are untouched.
        await setting(enabled=False)
        check("off: open page is plain again", await pixel(bare, 390, 290), (255, 255, 255))
        check("off: body background still fills the window", await pixel(await open_("/bodyblue"), 390, 290), (0, 0, 255))
        late = await open_("/bare")
        check("off: new page untouched", await pixel(late, 390, 290), (255, 255, 255))
        await setting(enabled=True)
        check("on again: page opened while off is covered", await pixel(late, 390, 290), (178, 92, 0))
        check("on again: earlier page too", await pixel(bare, 390, 290), (178, 92, 0))

        # The keyboard command goes through the same switch.
        await worker.evaluate("chrome.commands.onCommand.dispatch ? chrome.commands.onCommand.dispatch('toggle') : null")

        popup = await ctx.new_page()
        await popup.set_viewport_size({"width": 280, "height": 230})
        await popup.goto(f"chrome-extension://{ext_id}/popup.html")
        await asyncio.sleep(0.3)
        got = await pixel(popup, 5, 5)
        print(("ok   " if got[2] < 10 else "FAIL ") + f"popup ground has no blue: {got}")
        if SHOTS:
            SHOTS.mkdir(parents=True, exist_ok=True)
            await popup.screenshot(path=str(SHOTS / "popup.png"))
            await boxes.screenshot(path=str(SHOTS / "boxes.png"))
        await ctx.close()
    server.shutdown()
    print("\n" + ("ALL OK" if not failures else "FAILED: " + ", ".join(failures)))
    sys.exit(1 if failures else 0)


asyncio.run(main())
