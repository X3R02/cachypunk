#!/bin/sh
# Install the auth panel. Run as root, and keep a root shell open in another
# terminal until sudo is confirmed working: this replaces /etc/pam.d/sudo.
#   catalogs  /usr/share/locale/en_US/LC_MESSAGES/{fprintd,sudoers}.mo
#   granted   /usr/local/lib/auth-prompts/granted (run by pam_exec)
#   hook      /etc/pacman.d/hooks/auth-prompts.hook + lib/check, msgids-* (warns)
#   sudoers   /etc/sudoers.d/10-auth-prompts (pwfeedback)
#   pam       /etc/pam.d/sudo (the stock one is kept as sudo.bak-auth-prompts)
# Undo: delete the first four and restore the pam backup.
set -e
dir=$(dirname "$(readlink -f "$0")")

# Generate as the owner of this directory, so root never owns files in $HOME
owner=$(stat -c %U "$dir")
runuser -u "$owner" -- python3 "$dir/generate.py"

for domain in fprintd sudoers; do
	msgfmt -o "/usr/share/locale/en_US/LC_MESSAGES/$domain.mo" "$dir/$domain.po"
done

# pam_exec runs this as root: install a root-owned copy outside $HOME
install -D -o root -g root -m 755 "$dir/granted" /usr/local/lib/auth-prompts/granted

install -o root -g root -m 755 "$dir/check" /usr/local/lib/auth-prompts/check
install -o root -g root -m 644 "$dir/msgids-fprintd" "$dir/msgids-sudoers" /usr/local/lib/auth-prompts/
install -o root -g root -m 644 "$dir/auth-prompts.hook" /etc/pacman.d/hooks/auth-prompts.hook

visudo -cqf "$dir/sudoers-pwfeedback"
install -o root -g root -m 440 "$dir/sudoers-pwfeedback" /etc/sudoers.d/10-auth-prompts

[ -f /etc/pam.d/sudo.bak-auth-prompts ] || cp -p /etc/pam.d/sudo /etc/pam.d/sudo.bak-auth-prompts
# Without a fingerprint reader stack, drop the two fingerprint lines (both
# tagged chwd-fprintd): a PAM line naming a missing module can break sudo
if [ -f /usr/lib/security/pam_fprintd.so ]; then
	install -o root -g root -m 644 "$dir/pam-sudo" /etc/pam.d/sudo
else
	grep -v "chwd-fprintd" "$dir/pam-sudo" >/etc/pam.d/sudo.auth-prompts.new
	install -o root -g root -m 644 /etc/pam.d/sudo.auth-prompts.new /etc/pam.d/sudo
	rm -f /etc/pam.d/sudo.auth-prompts.new
fi

echo "installed. In a new terminal: sudo -k; sudo true"
echo "undo: cp /etc/pam.d/sudo.bak-auth-prompts /etc/pam.d/sudo"
