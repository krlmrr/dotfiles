// ==UserScript==
// @name           space_extensions
// @description    Enable and disable extensions based on the active Zen Space
// ==/UserScript==

import { AddonManager } from "resource://gre/modules/AddonManager.sys.mjs";

const ONE_PASSWORD = "{d634138d-c276-4fc8-924b-40a0ea21d284}";
const PROTON_PASS = "78272b6fa58f4a1abaac99321d503a20@proton.me";

const EXTENSIONS_BY_SPACE = {
  NotaryDash: [PROTON_PASS],
  "*": [ONE_PASSWORD],
};

const managedIds = new Set(Object.values(EXTENSIONS_BY_SPACE).flat());

let pending = Promise.resolve();

function activeSpaceName() {
  const window = Services.wm.getMostRecentWindow("navigator:browser");
  const uuid = Services.prefs.getStringPref("zen.workspaces.active", "");
  return window?.gZenWorkspaces?.getWorkspaceFromId(uuid)?.name;
}

async function applyActiveSpace() {
  const wanted = EXTENSIONS_BY_SPACE[activeSpaceName()] ?? EXTENSIONS_BY_SPACE["*"];
  for (const id of managedIds) {
    const addon = await AddonManager.getAddonByID(id);
    if (!addon) {
      continue;
    }
    const shouldBeEnabled = wanted.includes(id);
    if (shouldBeEnabled && addon.userDisabled) {
      await addon.enable();
    } else if (!shouldBeEnabled && !addon.userDisabled) {
      await addon.disable();
    }
  }
}

function scheduleApply() {
  pending = pending.then(applyActiveSpace).catch(error => console.error("space_extensions:", error));
}

Services.prefs.addObserver("zen.workspaces.active", scheduleApply);

Services.obs.addObserver(window => {
  window.addEventListener("AfterWorkspacesSessionRestore", scheduleApply, { once: true });
  scheduleApply();
}, "browser-delayed-startup-finished");
