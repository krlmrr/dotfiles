#!/bin/sh
# SUDO_ASKPASS helper: lets sudo collect a password when there is no TTY.
#
# Why: contexts like Claude Code's `!` prompt, launchd jobs and editor tasks run
# with no terminal, so sudo cannot prompt and just fails with "a terminal is
# required to read the password". sudo will instead run this program and read the
# password from its stdout.
#
# Usage is OPT-IN per command — sudo only calls this when given -A:
#     sudo -A rm -rf /Library/something
# Exporting SUDO_ASKPASS alone changes nothing, which is the point: nothing
# starts popping password dialogs unless a command explicitly asks for it.
#
# sudo passes its prompt string as $1, so the dialog shows what is being asked.
#
# SECURITY TRADE: any process that can run `sudo -A` can now put a convincing
# password dialog on screen. That is a real loosening. It is accepted here
# because the alternative is that half of this repo's maintenance scripts cannot
# run outside an interactive terminal.
PROMPT="${1:-sudo password:}"
osascript \
  -e "display dialog \"$PROMPT\" default answer \"\" with hidden answer with title \"sudo (askpass)\" buttons {\"Cancel\",\"OK\"} default button \"OK\"" \
  -e 'text returned of result' 2>/dev/null
