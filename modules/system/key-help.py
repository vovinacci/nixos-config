"""Searchable help for the running sway config's key bindings.

Reads the loaded config over IPC, so the help always matches what sway is
using. A binding's description is a `#: text` line directly above its
`bindsym`; without one the command itself is shown. Bindings inside a mode
are listed as "<key that enters the mode>, <key>". Enter runs the selected
binding's command.
"""

import json
import os
import re
import subprocess
import sys
import tempfile

SWAYMSG = "@swaymsg@"
WOFI = "@wofi@"

MODE_OPEN = re.compile(r'^mode\s+(?:--\S+\s+)*("(?:[^"\\]|\\.)*"|\S+)\s*\{$')
ENTER_MODE = re.compile(r'^mode\s+("(?:[^"\\]|\\.)*"|\S+)$')
BINDSYM = re.compile(r'^(?:--\S+\s+)*(\S+)\s+(.+)$')


def unquote(s):
    return s[1:-1] if len(s) >= 2 and s[0] == s[-1] == '"' else s


def split_bindsym(rest):
    """Split `[--flags] key command` into (key, command)."""
    m = BINDSYM.match(rest)
    return m.groups() if m else None


def pretty(key):
    return key.replace("Mod4", "Super").replace("Mod1", "Alt")


def parse(config):
    rows, entry_keys = [], {}
    mode, desc = None, None
    for raw in config.splitlines():
        line = raw.strip()
        if line.startswith("#:"):
            desc = line[2:].strip()
            continue
        m = MODE_OPEN.match(line)
        if m:
            mode, desc = unquote(m.group(1)), None
            continue
        if line == "}":
            mode, desc = None, None
            continue
        if line.startswith("bindsym "):
            parsed = split_bindsym(line[len("bindsym "):])
            if parsed:
                key, command = parsed
                target = ENTER_MODE.match(command)
                if mode is None and target:
                    entry_keys[unquote(target.group(1))] = key
                if command != "mode default":
                    rows.append((mode, key, desc or command, command))
        desc = None

    out = []
    for mode, key, desc, command in rows:
        label = pretty(key) if mode is None else \
            f"{pretty(entry_keys.get(mode, mode))}, {key}"
        out.append((label, desc, command))
    return out


def main():
    tree = subprocess.run([SWAYMSG, "-t", "get_config"],
                          capture_output=True, text=True, check=True)
    rows = parse(json.loads(tree.stdout)["config"])
    width = max(len(label) for label, _, _ in rows) + 2
    lines = {f"{label:<{width}}{desc}": command for label, desc, command in rows}

    # The launcher's own style plus a monospace font, so the keys line up.
    style = os.path.expanduser("~/.config/wofi/style.css")
    css = open(style).read() if os.path.exists(style) else ""
    with tempfile.NamedTemporaryFile("w", suffix=".css") as f:
        f.write(css + '\n#text { font-family: "JetBrainsMono Nerd Font", monospace; }\n')
        f.flush()
        choice = subprocess.run(
            [WOFI, "--dmenu", "--prompt", "Key or action", "--insensitive",
             "--matching", "fuzzy", "--cache-file", "/dev/null",
             "--width", "50%", "--lines", "24", "--style", f.name],
            input="\n".join(lines), capture_output=True, text=True).stdout.strip()

    if choice in lines:
        subprocess.run([SWAYMSG, "-q", "--", lines[choice]])


if __name__ == "__main__":
    sys.exit(main())
