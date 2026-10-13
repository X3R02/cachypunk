#!/bin/sh
# Focus the window of the app a notification came from: focus-app.sh <name>...
# Each name (the notification's desktop-entry hint, then its app name) is
# matched against window classes, exactly first and then as a substring,
# case-insensitively; the most recently used match wins. Exits 1 when no
# window matches, so the caller can fall back.
clients=$(hyprctl clients -j) || exit 1
for want in "$@"; do
	[ -n "$want" ] || continue
	addr=$(printf '%s' "$clients" | jq -r --arg w "$want" '
		($w | ascii_downcase) as $w
		| map(select((.class | ascii_downcase) as $c | (.initialClass | ascii_downcase) as $i
			| $c == $w or $i == $w or ($c | contains($w)) or ($w | contains($c) and ($c | length) > 2)))
		| sort_by(.focusHistoryID) | .[0].address // empty')
	if [ -n "$addr" ]; then
		hyprctl dispatch "hl.dsp.focus({window=\"address:$addr\"})" >/dev/null
		exit 0
	fi
done
exit 1
