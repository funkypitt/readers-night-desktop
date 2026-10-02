const $ = (id) => document.getElementById(id);

for (const node of document.querySelectorAll("[data-msg]")) {
  node.textContent = chrome.i18n.getMessage(node.dataset.msg);
}
document.documentElement.lang = chrome.i18n.getUILanguage();

function show(state) {
  $("enabled").checked = state.enabled;
  $("gray").checked = state.gray;
  $("dim").value = state.dim;
  $("dim-out").textContent = state.dim + " %";
  $("dependent").setAttribute("aria-disabled", String(!state.enabled));
  $("gray").disabled = $("dim").disabled = !state.enabled;
}

readState().then(show);
chrome.storage.onChanged.addListener(() => readState().then(show));

$("enabled").addEventListener("change", (e) => chrome.storage.local.set({ enabled: e.target.checked }));
$("gray").addEventListener("change", (e) => chrome.storage.local.set({ gray: e.target.checked }));
$("dim").addEventListener("input", (e) => {
  $("dim-out").textContent = e.target.value + " %";
  chrome.storage.local.set({ dim: Number(e.target.value) });
});
