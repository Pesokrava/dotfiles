#!/usr/bin/env bash
# ctrl+h/j/k/l entry point. A `type = "shell"` key command runs on the herdr
# server of the machine being viewed, so this sees that machine's panes and nvim.
# A plugin_action binding runs on the local server instead, which cannot see
# nvim inside a remote pane.
# ponytail: same logic as herdr-splits' scripts/herdr-nav.sh, but bash builtins
# only (no jq/sed/grep, no `pane current`): it runs on every keypress. Re-sync
# by hand if the plugin's nav behaviour changes.
set -uo pipefail
dir=$1
herdr=${HERDR_BIN_PATH:-herdr}

case $dir in
  left)  key=ctrl+h opp=right ;;
  down)  key=ctrl+j opp=up ;;
  up)    key=ctrl+k opp=down ;;
  right) key=ctrl+l opp=left ;;
  *) echo "herdr-splits-nav.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

unzoom=true at_edge=wrap
conf=${HERDR_SPLITS_CONFIG:-${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/config/herdr-splits}/herdr-splits.conf}
if [[ -r $conf ]]; then
  while IFS='=' read -r k v; do
    case $k in
      "nav_key_$dir") key=$v ;;
      unzoom_on_nav) unzoom=$v ;;
      nav_at_edge) at_edge=$v ;;
    esac
  done <"$conf"
fi

# process-info carries pane_id too, so one call answers both questions.
info=$("$herdr" pane process-info --current 2>/dev/null) || info=
vim_re='"name":"g?(view|l?n?vim?x?)(diff)?"'
pane_re='"pane_id":"([^"]+)"'
shopt -s nocasematch
if [[ $info =~ $vim_re ]]; then
  shopt -u nocasematch
  [[ $info =~ $pane_re ]] && exec "$herdr" pane send-keys "${BASH_REMATCH[1]}" "$key"
fi
shopt -u nocasematch

edges=$("$herdr" pane edges --current 2>/dev/null) || edges=
trusted=1
if [[ $edges == *'"zoomed":true'* ]]; then
  if [[ $unzoom == true ]]; then
    "$herdr" pane zoom --off --current 2>/dev/null
    edges=$("$herdr" pane edges --current 2>/dev/null) || edges=
  else
    # A zoomed pane reports every edge as true, so the flags can't drive wrap.
    trusted=0
  fi
fi

if ((trusted)) && [[ $edges == *"\"$dir\":true"* ]]; then
  [[ $at_edge == stop ]] && exit 0
  exec "$herdr" pane focus --direction "$opp" --current
fi
exec "$herdr" pane focus --direction "$dir" --current
