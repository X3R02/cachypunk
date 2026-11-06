#!/usr/bin/env python3
"""Write fprintd.po and sudoers.po: the auth prompts as one live NetTech card.

Both are en_US gettext catalogs. pam_fprintd hands sudo one message per
fingerprint state and sudoers supplies the password prompt and the retry
note; sudo prints each verbatim followed by a newline. Instead of stacking,
the messages share one fixed card, shaped like fastfetch's sections (a filled
header strip, tree rows, a bottom edge ending in a 45-degree cut), and move
the cursor over it, so the card updates in place:

    1  header strip        drawn by prompts
    2  request row         drawn by prompts
    3  hint / input row    drawn by prompts; the password is typed here
    4  bottom edge         drawn by prompts
    5  status line         drawn by notes only, prompts skip it

A prompt is drawn from line 1 down. A fingerprint prompt, and every note
(a failed scan, a wrong password), then parks the cursor above line 1, so
sudo's newline brings it back to line 1, hidden: whatever comes next starts
there, even when pam_fprintd ends silently (Ctrl+C during the scan skips to
the password and prints nothing). A note moves to the status line and
redraws only that. After the password, Enter leaves the cursor on line 4,
so the messages that follow it start from there.

Nothing paints a background except the header strip, whose text is the
terminal's own background (reverse video), so the card sits on any theme.
The palette is NetTech's own, sampled from the game (STYLEGUIDE.md 2.4), not
the desktop theme. Only real information is shown: no decorative device
branding or version strings. The Quickshell polkit card gets the same text
and keeps only the line holding "//" (see polkit/PolkitDialog.qml), so every
message needs one. sudo logs in the C locale (sudoers_locale), so the journal
never sees these.

A "verdict" redraws the card once auth is over: the granted one is printed
by pam_exec from /etc/pam.d/sudo (pam-sudo here, with the `granted` script
this writes), the locked-out one replaces sudo's "N incorrect password
attempts". The password prompt leaves the colour on cyan so pwfeedback's
asterisks (sudoers-pwfeedback) land inside the card; every later message
starts with a reset.
"""
import os

W = 46  # card width in cells, cut included
EDGE = 4  # the bottom edge, counted from the card's first line
STATUS = 5  # the status line

LIME = (203, 231, 87)
CYAN = (87, 208, 215)
RED = (255, 59, 69)
GREEN = (28, 217, 123)

ESC = "\\033"
NL = "\\n"
CR = "\\r"


def fg(c):
    return f"{ESC}[38;2;{c[0]};{c[1]};{c[2]}m"


def up(n):
    # A count of 0 still moves one line in most terminals
    return f"{ESC}[{n}A" if n else ""


def down(n):
    return f"{ESC}[{n}B" if n else ""


BOLD = f"{ESC}[1m"
REVERSE = f"{ESC}[7m"
RESET = f"{ESC}[0m"
# Erase to the end of the line, so nothing from an earlier draw survives
CLEAR = f"{ESC}[K"
# Hide what the user types: while the reader waits the terminal still echoes
CONCEAL = f"{ESC}[8m"
# The cursor waits on line 1 during the scan, hidden; every later message
# shows it again
HIDE = f"{ESC}[?25l"
SHOW = f"{ESC}[?25h"


def row(parts):
    """One line of coloured text on the terminal's background."""
    return "".join(fg(c) + t for c, t in parts) + RESET + CLEAR


def header(title, colour=LIME):
    """The filled strip: the colour as background, the terminal's background
    as text, padded to the card's width."""
    pad = W - 1 - len(title)
    return fg(colour) + REVERSE + BOLD + " " + title + " " * pad + RESET + CLEAR


def edge(colour=LIME):
    return row([(colour, "└" + "─" * (W - 2) + "╱")])


def card(title, request, value, hint):
    """Lines 1-4, leaving the cursor at the start of the status line, which
    it does not touch, so a note on it survives."""
    return (RESET + SHOW + header(title) + NL
            + row([(LIME, f"│ ├ //{request}  "), (CYAN, "▣ " + value)]) + NL
            + row([(LIME, "│ └ > "), (CYAN, hint)]) + NL
            + edge() + NL)


def prompt(title, request, value, hint):
    """A fingerprint prompt, parking the cursor above line 1. quiet-tty (see
    pam-sudo) turns echo off while it waits; if that is missing, typed keys
    are at least drawn invisible."""
    return card(title, request, value, hint) + up(STATUS) + HIDE + CONCEAL


def status(colour, mark, request, value):
    return row([(colour, f" {mark} //{request}  "), (CYAN, value)])


def note(colour, request, value, start=1):
    """Redraw the status line from line `start` (1, or 4 after the password)
    and park the cursor above line 1 (see above). The reader may keep
    scanning after it, so it conceals again."""
    line = status(colour, "✕", request, value)
    return (RESET + CR + down(STATUS - start) + line + up(STATUS) + HIDE
            + CONCEAL)


def verdict(title, colour, mark, request, value, start):
    """From line `start`, after auth: redraw the card as the header and one
    row, erase everything below it, and leave the cursor so sudo's newline
    lands on line 4, where what follows starts."""
    return (RESET + SHOW + CR + up(start - 1) + header(title, colour) + NL
            + row([(colour, f"│ └ {mark} //{request}  "), (CYAN, value)]) + NL
            + edge(colour) + NL + f"{ESC}[J" + up(1))


def retry(request, value):
    return note(LIME, request, value)


def denied(request, value, start=1):
    return note(RED, request, value, start=start)


FINGERS = ["left thumb", "left index finger", "left middle finger",
           "left ring finger", "left little finger", "right thumb",
           "right index finger", "right middle finger", "right ring finger",
           "right little finger"]


def short(finger):
    return finger.replace(" finger", "").upper()


fprintd = []
for verb, prep, hint in (("Place", "on", "place finger on reader_"),
                         ("Swipe", "across", "swipe finger across reader_")):
    for tail in ("%s", "the fingerprint reader"):
        fprintd.append((f"{verb} your finger {prep} {tail}",
                        prompt("BIOMETRIC ACCESS", "ACCESS_REQUEST",
                               "ANY FINGER", hint)))
        for f in FINGERS:
            fprintd.append((f"{verb} your {f} {prep} {tail}",
                            prompt("BIOMETRIC ACCESS", "ACCESS_REQUEST",
                                   short(f), hint)))

fprintd += [
    # The reader keeps scanning after these
    ("Place your finger on the reader again", retry("RESCAN", "place again_")),
    ("Swipe your finger again", retry("RESCAN", "swipe again_")),
    ("Swipe was too short, try again", retry("SWIPE_TOO_SHORT", "again_")),
    ("Swipe was too fast, try again", retry("SWIPE_TOO_FAST", "again_")),
    ("Your finger was not centered, try swiping your finger again",
     retry("OFF_CENTER", "swipe again_")),
    ("Your finger was not centered, try touching the sensor again",
     retry("OFF_CENTER", "touch again_")),
    ("Remove your finger, and try swiping your finger again",
     retry("LIFT_FINGER", "swipe again_")),
    # A new prompt follows these: the next scan, or the password
    ("Failed to match fingerprint", denied("NO_MATCH", "access denied")),
    ("Verification timed out", denied("TIMEOUT", "scan window closed")),
    ("An unknown error occurred", denied("READER_FAULT", "falling back")),
]

# The password is typed on line 3: draw the card in full to wipe the
# fingerprint hint, then climb back to its start for the "> " the cursor sits
# on. Enter then moves the cursor to line 4
password = card("PASSWORD OVERRIDE", "MANUAL_AUTH", "USER PASSWORD", "")
password += up(STATUS - 3) + CR + fg(LIME) + "│ └ > " + fg(CYAN)

# Ctrl+C or Ctrl+D at the password prompt: sudo gives up, prefixing "sudo: ".
# `sudo -n` prints the same message with no card above it, so this never
# climbs: it closes the card in place of its bottom edge and erases below
cancelled = (RESET + SHOW + CR + status(RED, "✕", "NO_PASSWORD", "access denied")
             + f"{ESC}[J")

sudoers = [
    ("[sudo] password for %p: ", password),
    ("Sorry, try again.", denied("BAD_PASSWORD", "access denied", start=EDGE)),
    ("a password is required", cancelled),
    (("%u incorrect password attempt", "%u incorrect password attempts"),
     [verdict("ACCESS DENIED", RED, "✕", "LOCKED_OUT", "%u failed attempt",
              EDGE),
      verdict("ACCESS DENIED", RED, "✕", "LOCKED_OUT", "%u failed attempts",
              EDGE)]),
]

granted = {
    "fingerprint": verdict("ACCESS GRANTED", GREEN, "✓", "AUTHORIZED",
                           "fingerprint", 1),
    "password": verdict("ACCESS GRANTED", GREEN, "✓", "AUTHORIZED",
                        "password", EDGE),
}

HEADER = '''# Generated by ~/.config/auth-prompts/generate.py - edit that, not this.
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\\n"
"Language: en_US\\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"
'''

here = os.path.dirname(os.path.abspath(__file__))
for domain, entries in (("fprintd", fprintd), ("sudoers", sudoers)):
    with open(os.path.join(here, domain + ".po"), "w") as fh:
        fh.write(HEADER)
        for k, v in entries:
            if isinstance(k, tuple):
                fh.write(f'\nmsgid "{k[0]}"\nmsgid_plural "{k[1]}"\n')
                for i, form in enumerate(v):
                    fh.write(f'msgstr[{i}] "{form}"\n')
            else:
                fh.write(f'\nmsgid "{k}"\nmsgstr "{v}"\n')

# The msgids this overrides, one per line, for the pacman hook's check that
# a new fprintd or sudo still uses them
for domain, entries in (("fprintd", fprintd), ("sudoers", sudoers)):
    with open(os.path.join(here, "msgids-" + domain), "w") as fh:
        for k, _ in entries:
            for msgid in (k if isinstance(k, tuple) else (k,)):
                fh.write(msgid + "\n")

# Run as root by pam_exec, so install.sh copies it out of $HOME. No newline:
# pam_exec would split the output into separate messages
with open(os.path.join(here, "granted"), "w") as fh:
    fh.write("#!/bin/sh\n# Generated by ~/.config/auth-prompts/generate.py: "
             "the ACCESS GRANTED panel.\n# $1 is how the user got in: "
             "fingerprint or password.\n")
    # quiet-tty turned echo and canonical mode off; back on
    fh.write('stty -F "$PAM_TTY" echo icanon 2>/dev/null\n')
    fh.write('case "$1" in\n')
    for how, text in granted.items():
        fh.write(f"{how}) printf '{text}' ;;\n")
    fh.write("esac\nexit 0\n")
