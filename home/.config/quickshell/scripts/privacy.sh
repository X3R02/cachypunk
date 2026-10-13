#!/bin/sh
# Who is using the microphone or the camera right now, for the bar's privacy
# chips (modules/Privacy.qml), as key=value lines. A key is missing when
# nothing uses that device. Screen sharing comes from Hyprland's own event.

# Microphone: apps capturing from a real source. A sink's ".monitor" is what
# the speakers play (a visualiser reads it), not the microphone
mic=$(pactl -f json list sources 2>/dev/null |
	jq -r '[.[] | select(.name | endswith(".monitor")) | .index] | map(tostring) | join(" ")')
pactl -f json list source-outputs 2>/dev/null |
	jq -r --arg mon " $mic " '
		[.[] | .source as $s | select(($mon | contains(" \($s) ")) | not)
		| .properties["application.name"] // .properties["application.process.binary"] // "an app"]
		| unique | if length > 0 then "mic=" + join(", ") else empty end'

# Camera: any process holding a /dev/video* device open, whether it went
# through PipeWire or opened the device directly (browsers often do)
cam=$(find /proc/[0-9]*/fd -lname '/dev/video*' 2>/dev/null |
	cut -d/ -f3 | sort -u | while read -r pid; do cat "/proc/$pid/comm" 2>/dev/null; done |
	sort -u | paste -sd, - | sed 's/,/, /g')
[ -n "$cam" ] && echo "cam=$cam"
exit 0
