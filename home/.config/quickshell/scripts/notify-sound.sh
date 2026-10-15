#!/bin/sh
# Play the notification sound: the first ~/.config/cachypunk/sounds/notification.*
# (any format libsndfile reads: ogg, wav, flac, mp3). The sound is optional and
# per-machine, not shipped in the repo; without one this exits quietly.
for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/cachypunk/sounds/notification.*; do
	[ -f "$f" ] || continue
	exec pw-play "$f"
done
exit 0
