// Shared by the page script, the popup and the background worker.
// enabled: the filter is on. gray: colours are turned to gray before the amber tint.
// dim: brightness kept, in percent.
const DEFAULTS = { enabled: true, gray: true, dim: 70 };  // dim: keep equal to DEFAULT_DIM in filter-urls.js
const DIM_MIN = 15;

function readState() {
  return chrome.storage.local.get(DEFAULTS).then((s) => ({
    enabled: s.enabled !== false,
    gray: s.gray !== false,
    dim: Math.min(100, Math.max(DIM_MIN, Number(s.dim) || DEFAULTS.dim)),
  }));
}
