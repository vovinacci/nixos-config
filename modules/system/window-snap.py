"""Magnet-style window placement for sway.

window-snap ACTION   snap the focused window (see GRID and TILED below)
window-snap restore  undo the snap
window-snap --daemon apply pending tiled snaps when new windows open

Tiled windows stay tiled for the side-by-side actions (halves, thirds,
two-thirds): the window's top-level column moves to that edge of the
workspace and takes that share of its width, and later windows fill the rest.
A window that is alone on its workspace cannot be narrower than the
workspace, so the snap is recorded as a hidden mark and applied by the
daemon when the next window opens there.

Everything else - quarters, top/bottom, centre, maximise, and any snap of a
floating window - floats the window into a cell of the workspace's usable
area (bars excluded).

The pre-snap state is saved on the first snap and kept across later snaps,
so `restore`, or repeating the same snap, returns a floating window to its
old geometry, a floated tiled window to the tiling layout, and a tiled snap
to an even split.
"""

import json
import os
import subprocess
import sys

from i3ipc import Connection, Event

NOTIFY_SEND = "@notify_send@"
STATE_DIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "window-snap")
MARK = "_snap"  # leading underscore: sway never draws the mark

# column start, span, columns, row start, span, rows
GRID = {
    "left": (0, 1, 2, 0, 1, 1),
    "right": (1, 1, 2, 0, 1, 1),
    "top": (0, 1, 1, 0, 1, 2),
    "bottom": (0, 1, 1, 1, 1, 2),
    "top-left": (0, 1, 2, 0, 1, 2),
    "top-right": (1, 1, 2, 0, 1, 2),
    "bottom-left": (0, 1, 2, 1, 1, 2),
    "bottom-right": (1, 1, 2, 1, 1, 2),
    "left-third": (0, 1, 3, 0, 1, 1),
    "center-third": (1, 1, 3, 0, 1, 1),
    "right-third": (2, 1, 3, 0, 1, 1),
    "left-two-thirds": (0, 2, 3, 0, 1, 1),
    "right-two-thirds": (1, 2, 3, 0, 1, 1),
    "maximize": (0, 1, 1, 0, 1, 1),
}

# actions a tiled window performs in the tiling layout: edge, width in ppt
TILED = {
    "left": ("left", 50),
    "right": ("right", 50),
    "left-third": ("left", 33),
    "right-third": ("right", 33),
    "left-two-thirds": ("left", 67),
    "right-two-thirds": ("right", 67),
}


def state_path(con_id):
    return os.path.join(STATE_DIR, str(con_id))


def load(con_id):
    try:
        with open(state_path(con_id)) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def save(con_id, state):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(state_path(con_id), "w") as f:
        json.dump(state, f)


def drop(con_id):
    try:
        os.remove(state_path(con_id))
    except OSError:
        pass


def connect(**kwargs):
    # SWAYSOCK explicitly: i3ipc would try I3SOCK first, and a stale or
    # inherited I3SOCK can point at another sway instance.
    return Connection(socket_path=os.environ.get("SWAYSOCK"), **kwargs)


def run(i3, con_id, command):
    i3.command(f"[con_id={con_id}] {command}")


def notify(message):
    subprocess.run(
        [NOTIFY_SEND, "-a", "window-snap", "-t", "2500", "Window snap", message],
        check=False,
    )


def column(con):
    """The ancestor of con that is a direct child of its workspace."""
    while con.parent is not None and con.parent.type != "workspace":
        con = con.parent
    return con


def unmark_pending(i3, con):
    for mark in con.marks:
        if mark.startswith(MARK + "_"):
            run(i3, con.id, f"unmark {mark}")


def snap_column(i3, col_id, side, pct):
    """Move a top-level column to one edge and give it pct of the width."""
    for _ in range(64):
        col = i3.get_tree().find_by_id(col_id)
        if col is None:
            return
        ids = [n.id for n in col.workspace().nodes]
        i = ids.index(col_id)
        if side == "left" and i > 0:
            other = ids[i - 1]
        elif side == "right" and i < len(ids) - 1:
            other = ids[i + 1]
        else:
            break
        # swap with the neighbour, not `move`: moving towards a split
        # container would put the column inside it
        run(i3, col_id, f"swap container with con_id {other}")
    run(i3, col_id, f"resize set width {pct} ppt")


def restore(i3, tree, key):
    state = load(key)
    drop(key)
    if state is None:
        return
    if state["kind"] == "tiled":
        run(i3, key, "floating disable")
    elif state["kind"] == "floating":
        x, y, w, h = state["rect"]
        run(
            i3,
            key,
            f"resize set width {w} px height {h} px, move absolute position {x} {y}",
        )
    elif state["kind"] == "column":
        col = tree.find_by_id(state["col"])
        if col is None:
            return
        unmark_pending(i3, col)
        n = len(col.workspace().nodes)
        if n > 1:
            run(i3, col.id, f"resize set width {100 // n} ppt")


def snap(action):
    if action not in GRID and action not in ("center", "restore"):
        print(f"window-snap: unknown action '{action}'", file=sys.stderr)
        sys.exit(1)

    i3 = connect()
    tree = i3.get_tree()
    focused = tree.find_focused()
    if focused is None or focused.type not in ("con", "floating_con"):
        return
    key = focused.id
    state = load(key)

    if action == "restore" or (state and state.get("last") == action):
        restore(i3, tree, key)
        return

    tiled = focused.type == "con"
    ws = focused.workspace()

    if tiled and action in TILED:
        col = column(focused)
        alone = len(ws.nodes) == 1
        # a lone column that is itself a split holds all the windows; new
        # ones would open inside it, so the pending snap could never apply
        if (alone and not col.nodes) or (not alone and ws.layout == "splith"):
            if state is None or state["kind"] != "column":
                state = {"kind": "column", "col": col.id}
            state["last"] = action
            save(key, state)
            unmark_pending(i3, col)
            side, pct = TILED[action]
            if alone:
                run(i3, col.id, f"mark --add {MARK}_{side}_{pct}_{col.id}")
                notify(f"{action}: applies when the next window opens")
            else:
                snap_column(i3, col.id, side, pct)
            return

    # floating snap
    if state is None:
        if tiled:
            state = {"kind": "tiled"}
        else:
            r = focused.rect
            state = {"kind": "floating", "rect": [r.x, r.y, r.width, r.height]}
    elif state["kind"] == "column":
        col = tree.find_by_id(state["col"])
        if col is not None:
            unmark_pending(i3, col)
        state = {"kind": "tiled"}
    state["last"] = action
    save(key, state)

    if action == "center":
        run(i3, key, "floating enable, move position center")
        return
    cs, cn, cols, rs, rn, rows = GRID[action]
    r = ws.rect
    run(
        i3,
        key,
        (
            "floating enable, "
            f"resize set width {r.width * cn // cols} px height {r.height * rn // rows} px, "
            f"move absolute position {r.x + r.width * cs // cols} {r.y + r.height * rs // rows}"
        ),
    )


def on_new_window(i3, _event):
    tree = i3.get_tree()
    for con in tree.descendants():
        for mark in con.marks:
            parts = mark.split("_")  # "", "snap", side, pct, id
            if len(parts) != 5 or parts[1] != "snap":
                continue
            ws = con.workspace()
            if ws is None or len(ws.nodes) < 2:
                continue  # still alone: the new window opened elsewhere or floats
            run(i3, con.id, f"unmark {mark}")
            if ws.layout == "splith" and con.parent.type == "workspace":
                snap_column(i3, con.id, parts[2], int(parts[3]))


def daemon():
    i3 = connect(auto_reconnect=True)
    i3.on(Event.WINDOW_NEW, on_new_window)
    i3.main()


def main():
    if len(sys.argv) != 2:
        print("usage: window-snap ACTION | restore | --daemon", file=sys.stderr)
        sys.exit(2)
    if sys.argv[1] == "--daemon":
        daemon()
    else:
        snap(sys.argv[1])


if __name__ == "__main__":
    main()
