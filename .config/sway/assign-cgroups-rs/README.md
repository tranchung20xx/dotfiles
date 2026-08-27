## This project was created by claudecode. Use with own risk.

# assign-cgroups

Rust rewrite of the Python `assign-cgroups` script. Automatically assigns a
dedicated systemd (user) scope to GUI applications launched in the same
cgroup as the i3/sway compositor — useful for cgroup-based resource
management, and required when `systemd-oomd` is in use.

Compared to the Python original, this rewrite avoids per-window process
spawning and Python startup overhead: the whole thing is a single native
binary, event handling and `/proc` scans are done without any interpreter
overhead, and the systemd D-Bus calls reuse one persistent connection
instead of creating one per launch.

**Limitation** (same as upstream): window creation is detected via the
i3/sway IPC `window::new` event, so background apps or special surfaces that
never map a window are missed. Supplement this with systemd user services
for such apps.

## Build

Requires a Rust toolchain (1.75+) and D-Bus development headers:

```sh
sudo apt install rustc cargo pkg-config libdbus-1-dev   # Debian/Ubuntu
cargo build --release
```

The binary is produced at `target/release/assign-cgroups`.

## Run

```sh
./target/release/assign-cgroups --loglevel info
```

It picks up the IPC socket from `$SWAYSOCK`/`$I3SOCK`, falling back to
invoking `sway --get-socketpath` / `i3 --get-socketpath`. Scopes are created
via the systemd **user** session bus (`app-<id>.slice/app-<id>-<pid>.scope`),
mirroring what `systemd-run --user --scope` would do.

### As a systemd user service

```ini
# ~/.config/systemd/user/assign-cgroups.service
[Unit]
Description=Assign transient scopes to compositor-launched apps
PartOf=graphical-session.target

[Service]
ExecStart=%h/.local/bin/assign-cgroups
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

```sh
systemctl --user enable --now assign-cgroups.service
```

## Notes on the port

- **IPC**: the i3/sway wire protocol (6-byte magic + length + type header) is
  implemented directly over `tokio::net::UnixStream` — no external i3ipc
  crate dependency.
- **PID resolution**: prefers sway's native `pid` field on the IPC container;
  falls back to X11 for XWayland/i3 windows, trying the X-Resource extension
  first and `_NET_WM_PID` second, same order as upstream.
- **systemd**: `StartTransientUnit` is called through `zbus`, with the same
  3-attempt retry as the Python version's `tenacity` decorator, to absorb the
  race where a short-lived child exits before the D-Bus call lands.
- **Child enumeration**: uses the fast `/proc/<pid>/task/<pid>/children`
  interface where available, falling back to a full `/proc` scan keyed by
  parent PID otherwise.
