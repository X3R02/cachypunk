#!/bin/sh
# Install this theme as SDDM's login screen. Run once with sudo; afterwards
# theme-set keeps its colors and background current without root.
#
# SDDM runs as its own user and cannot read $HOME (0700), so the theme has to
# live under /usr/share. Only the two files derived from the current theme are
# owned by the invoking user, so theme-set can rewrite them.
set -eu
user=${SUDO_USER:?run with sudo}
home=$(getent passwd "$user" | cut -d: -f6)
src=$(dirname "$(readlink -f "$0")")
dest=/usr/share/sddm/themes/matugen

install -d -m 755 "$dest"
install -m 644 "$src/Main.qml" "$src/metadata.desktop" "$src/theme.conf" "$dest/"
for f in theme.conf.user background.jpg; do
	[ -e "$dest/$f" ] || install -m 644 /dev/null "$dest/$f"
	chown "$user" "$dest/$f"
done

# SDDM can't read ~/.local/share/fonts either; the theme is set in Rajdhani
install -d -m 755 /usr/local/share/fonts/Rajdhani
install -m 644 "$home/.local/share/fonts/Rajdhani/"*.ttf "$home/.local/share/fonts/Rajdhani/OFL.txt" /usr/local/share/fonts/Rajdhani/
fc-cache -f /usr/local/share/fonts/Rajdhani

install -d -m 755 /etc/sddm.conf.d
printf '[Theme]\nCurrent=matugen\n' >/etc/sddm.conf.d/theme.conf

# Fill the user-owned files now instead of waiting for the next theme switch
sudo -u "$user" "$home/.local/bin/theme-set"
echo "SDDM theme installed: $dest"
