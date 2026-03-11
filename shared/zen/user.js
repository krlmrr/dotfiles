// Zen Browser preferences
// Deployed by dotfiles setup script into the default profile

// Skip onboarding
user_pref("zen.welcome-screen.seen", true);

// Tabs on the right
user_pref("zen.tabs.vertical.right-side", true);

// Don't nag about default browser
user_pref("browser.shell.checkDefaultBrowser", false);

// Don't warn on quit shortcut
user_pref("browser.warnOnQuitShortcut", false);

// Don't offer to save passwords (use 1Password)
user_pref("signon.rememberSignons", false);

// Disable telemetry first-run prompt
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
