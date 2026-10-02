importScripts("state.js");

const SCRIPT_ID = "filter";
const CSS = "filter.css";

// While the filter is on, the browser itself injects the stylesheet into every new page
// before its first paint: no page flashes white. Off, nothing is injected at all.
async function register(enabled) {
  const known = await chrome.scripting.getRegisteredContentScripts({ ids: [SCRIPT_ID] });
  if (enabled && !known.length) {
    await chrome.scripting.registerContentScripts([
      { id: SCRIPT_ID, matches: ["<all_urls>"], css: [CSS], runAt: "document_start" },
    ]);
  } else if (!enabled && known.length) {
    await chrome.scripting.unregisterContentScripts({ ids: [SCRIPT_ID] });
  }
}

// Pages opened while the filter was off have no stylesheet yet. The browser's own pages
// (settings, extension store) refuse it; that is expected.
async function coverOpenTabs() {
  const tabs = await chrome.tabs.query({});
  await Promise.all(
    tabs.map(async (tab) => {
      const target = { tabId: tab.id };
      try {
        await chrome.scripting.removeCSS({ target, files: [CSS] });
        await chrome.scripting.insertCSS({ target, files: [CSS] });
      } catch (e) {
        /* a page extensions cannot touch */
      }
    })
  );
}

async function showState(enabled) {
  const kind = enabled ? "on" : "off";
  await chrome.action.setIcon({
    path: { 16: `icons/${kind}-16.png`, 32: `icons/${kind}-32.png`, 48: `icons/${kind}-48.png` },
  });
}

async function sync() {
  const state = await readState();
  await register(state.enabled);
  if (state.enabled) await coverOpenTabs();
  await showState(state.enabled);
}

chrome.runtime.onInstalled.addListener(sync);
chrome.runtime.onStartup.addListener(sync);
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && "enabled" in changes) sync();
});
chrome.commands.onCommand.addListener(async (command) => {
  if (command !== "toggle") return;
  const state = await readState();
  await chrome.storage.local.set({ enabled: !state.enabled });
});
