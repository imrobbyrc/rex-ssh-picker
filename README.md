# rex-ssh-picker

Native SSH host picker for [Rex](https://www.superlogical.com/rex/), written in Lua — no external binaries.

Picks a host from `~/.ssh/config` and connects in its **own Rex session**: one
session per host, one tab per host. Picking a host you are already connected
to just switches to its tab, so repeated picks never stack duplicate tabs.
The connection is a plain `ssh <host>`, so your config handles keys, ports,
jumps, and everything else.

Inspired by the Rex integration in [alde/git-wt](https://github.com/alde/git-wt).

## Install

```sh
./setup.sh
```

`setup.sh` copies `ssh.lua` into `~/.config/rex/` (override with
`REX_CONFIG_DIR`) and appends `require("ssh")` to `init.lua`. Then:

```sh
rex config reload
```

## Usage

- **`ctrl+alt+s`** — opens the host picker
- Command palette → **"SSH: Connect Host…"**
- Headless: `rex do ssh_open`, or connect directly with `rex do ssh_open host=<host>`

Hosts with `*`, `?`, or `!` patterns in their `Host` line are skipped; the
picker shows `user@hostname:port` from the config when present.

To jump focus to the tab you picked, enable **Remote Control** in the Rex
app's settings (Rex Server section); without it the session is created but
focus stays where it is.

## Requirements

- Rex with Lua plugin support (`rex.action`, `rex.ui.pick`, `rex.call`)
- `ssh` on the server's `PATH`

## Files

| File | Purpose |
|------|---------|
| `ssh.lua` | The plugin: action `ssh_open`, keybind, session/tab logic |
| `setup.sh` | Copies the plugin into the Rex config dir and wires `init.lua` |
