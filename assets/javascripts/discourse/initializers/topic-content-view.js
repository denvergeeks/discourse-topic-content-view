import { withPluginApi } from "discourse/lib/plugin-api";

// Parse the unified JSON modes array from the site setting.
// Returns only modes that are enabled.
function parseModes(rawSetting) {
  if (!rawSetting) return [];
  try {
    const modes = JSON.parse(rawSetting);
    if (!Array.isArray(modes)) return [];
    return modes.filter((m) => m && m.value && m.enabled !== false);
  } catch (_) {
    return [];
  }
}

// Remove any previously applied tcv body classes
function clearTcvClasses() {
  const toRemove = [...document.body.classList].filter((c) =>
    c.startsWith("tcv-")
  );
  document.body.classList.remove(...toRemove);
}

// Inject (or remove) the per-mode custom CSS into a <style> tag
function applyModeCss(modeValue, modes) {
  const existing = document.getElementById("tcv-mode-custom-css");
  if (existing) existing.remove();

  if (!modeValue || !modes || !modes.length) return;

  const mode = modes.find((m) => m.value === modeValue);
  if (!mode || !mode.css || !mode.css.trim()) return;

  const style = document.createElement("style");
  style.id = "tcv-mode-custom-css";
  style.textContent = mode.css;
  document.head.appendChild(style);
}

export default {
  name: "topic-content-view",

  initialize(container) {
    withPluginApi("1.0.0", (api) => {
      const siteSettings = container.lookup("service:site-settings");

      api.onPageChange(() => {
        clearTcvClasses();

        if (!siteSettings.topic_content_view_enabled) return;

        const modeParam = new URLSearchParams(window.location.search).get("tcv");
        if (!modeParam) return;

        // Parse modes, filtering out disabled ones
        const enabledModes = parseModes(siteSettings.topic_content_view_modes);

        const match = enabledModes.find((m) => m.value === modeParam);
        if (match && match.classes) {
          document.body.classList.add(
            ...match.classes.split(/\s+/).filter(Boolean)
          );
        }

        // Inject admin-saved CSS for this mode
        applyModeCss(modeParam, enabledModes);
      });
    });
  },
};
