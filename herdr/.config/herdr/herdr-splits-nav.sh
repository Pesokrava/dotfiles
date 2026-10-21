#!/usr/bin/env bash
# ctrl+h/j/k/l entry point. A `type = "shell"` key command runs on the herdr
# server of the machine being viewed, so the nav script sees that machine's
# panes and nvim. A plugin_action binding runs on the local server instead,
# which cannot see nvim inside a remote pane.
# The plugin's install path differs per machine, so ask herdr for it.
set -euo pipefail
root=$(herdr plugin list --json | jq -r '.result.plugins[] | select(.plugin_id == "herdr-splits") | .plugin_root')
exec bash "$root/scripts/herdr-nav.sh" "$1"
