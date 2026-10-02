// Runs in every page, before it is drawn. The filter itself is filter.css, which the
// background worker has the browser inject ahead of the first paint; this script only
// carries what a fixed stylesheet cannot know: off, colours kept, another brightness.
(() => {
  const root = document.documentElement;
  if (!root) return;
  let state = null;
  let written = "";

  function paint() {
    if (state.enabled) root.removeAttribute("data-readers-night");
    else root.setAttribute("data-readers-night", "off");

    // The stylesheet holds the usual look. Any other one is written on the root itself,
    // where it outranks the stylesheet.
    const usual = state.gray && state.dim === DEFAULT_DIM;
    const wanted = state.enabled && !usual
      ? `url("${state.gray ? FILTER_URLS.amber : FILTER_URLS.warm}") brightness(${state.dim / 100})`
      : "";
    if (wanted !== written) {
      if (wanted) root.style.setProperty("filter", wanted, "important");
      else root.style.removeProperty("filter");
      written = wanted;
    }
    checkBackground();
  }

  // filter.css gives a background to pages that have none (see there). When the body
  // has its own, the browser must go on spreading that one over the whole window, which
  // it only does while the root has none: lift ours.
  function checkBackground() {
    const body = document.body;
    if (!body) return;
    const style = getComputedStyle(body);
    const colour = style.backgroundColor;
    const painted =
      style.backgroundImage !== "none" ||
      !(colour === "transparent" || /,\s*0\)$/.test(colour));
    if (painted) root.setAttribute("data-readers-night-bg", "");
    else root.removeAttribute("data-readers-night-bg");
  }

  readState().then((s) => {
    state = s;
    paint();
  });
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area !== "local" || !state) return;
    for (const key of Object.keys(changes)) state[key] = changes[key].newValue;
    paint();
  });

  const again = () => state && checkBackground();
  if (!document.body) {
    const waiting = new MutationObserver(() => {
      if (!document.body) return;
      waiting.disconnect();
      again();
    });
    waiting.observe(root, { childList: true });
  }
  document.addEventListener("DOMContentLoaded", again);
  window.addEventListener("load", again);
})();
