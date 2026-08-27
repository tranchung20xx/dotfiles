//! Automatically assign a dedicated systemd scope to the GUI applications
//! launched in the same cgroup as the compositor. This is helpful for
//! implementing cgroup-based resource management, and is necessary when
//! `systemd-oomd` is in use.
//!
//! Limitations: window creation is detected via the i3/sway IPC `window::new`
//! event, so background apps or special surfaces that never map a window are
//! missed. Supplement this with systemd user services for such apps.

mod cgroup;
mod ipc;
mod systemd;
mod x11;

use std::fs;
use std::sync::OnceLock;

use clap::Parser;
use tracing::{debug, error, info, warn};

use cgroup::{cgroup_change_needed, children_recursive, escape_app_id, get_cgroup, launcher_app_cgroups};
use ipc::{Con, IpcConnection};
use systemd::SystemdClient;
use x11::X11PidGetter;

#[derive(Parser)]
#[command(about = "Assign CGroups to apps in compositors with i3 IPC protocol support")]
struct Args {
    /// Set logging level
    #[arg(short, long, default_value = "info", value_parser = ["critical", "error", "warning", "info", "debug"])]
    loglevel: String,
}

fn init_logging(level: &str) {
    // Map the Python-flavoured level names onto tracing's.
    let level = match level {
        "critical" => "error",
        "warning" => "warn",
        other => other,
    };
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::new(level))
        .init();
}

/// Lazily create the X11 fallback PID getter on first use, matching the
/// Python script's on-demand `lru_cache`d property. Returns `None` (and logs
/// once) if no X server is reachable, e.g. a pure-Wayland session.
fn x11_getter() -> Option<&'static X11PidGetter> {
    static GETTER: OnceLock<Option<X11PidGetter>> = OnceLock::new();
    GETTER
        .get_or_init(|| match X11PidGetter::new() {
            Ok(g) => Some(g),
            Err(err) => {
                warn!("Failed to create X11 PID getter: {err}");
                None
            }
        })
        .as_ref()
}

/// Resolve the PID for a container: prefer sway's native `pid` field, and
/// fall back to X11 lookups (XRes / `_NET_WM_PID`) for XWayland/i3 windows.
fn get_pid(con: &Con) -> Option<i32> {
    if let Some(pid) = con.pid {
        if pid > 0 {
            return Some(pid);
        }
    }
    let window = con.window?;
    let getter = x11_getter()?;
    match getter.get_pid(window as u32) {
        Ok(pid) => Some(pid),
        Err(err) => {
            debug!("X11 PID lookup failed for window {window:#x}: {err}");
            None
        }
    }
}

fn process_name(pid: i32) -> Option<String> {
    fs::read_to_string(format!("/proc/{pid}/comm")).ok().map(|s| s.trim().to_string())
}

async fn assign_scope(
    systemd: &SystemdClient<'_>,
    compositor_cgroup: &str,
    launcher_cgroups: &[String],
    app_id: &str,
    pid: i32,
) -> anyhow::Result<()> {
    let escaped = escape_app_id(app_id);
    let sd_slice = format!("app-{escaped}.slice");
    let sd_unit = format!("app-{escaped}-{pid}.scope");

    // Collect child processes as systemd assigns a scope only to explicitly
    // specified PIDs. There's a race here (a child may exit before the DBus
    // call reaches systemd), which is why assign_scope itself retries.
    let mut pids: Vec<u32> = vec![pid as u32];
    for child in children_recursive(pid) {
        if cgroup_change_needed(get_cgroup(child).as_deref(), compositor_cgroup, launcher_cgroups) {
            pids.push(child as u32);
        }
    }

    systemd.assign_scope(&sd_unit, &sd_slice, &pids).await?;
    debug!("window {app_id} successfully assigned to cgroup {sd_slice}/{sd_unit}");
    Ok(())
}

async fn handle_new_window(
    systemd: &SystemdClient<'_>,
    compositor_cgroup: &str,
    launcher_cgroups: &[String],
    con: Con,
) {
    let mut app_id = con.app_id_or_class();
    let label = app_id.clone().unwrap_or_else(|| "<unknown>".to_string());

    let pid = match get_pid(&con) {
        Some(pid) => pid,
        None => {
            warn!("Failed to get pid for {label}");
            return;
        }
    };

    let cgroup = get_cgroup(pid);

    // Some X11 apps don't set WM_CLASS; fall back to the process name.
    if app_id.is_none() {
        app_id = process_name(pid);
    }
    let app_id = match app_id {
        Some(id) => id,
        None => {
            warn!("Failed to determine app_id for pid {pid}");
            return;
        }
    };

    debug!("window {app_id}({pid}) cgroup {cgroup:?}");

    if cgroup_change_needed(cgroup.as_deref(), compositor_cgroup, launcher_cgroups) {
        if let Err(err) = assign_scope(systemd, compositor_cgroup, launcher_cgroups, &app_id, pid).await {
            error!("Failed to modify cgroup for {app_id}: {err}");
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    init_logging(&args.loglevel);

    let sockpath = ipc::find_socket_path()?;

    let compositor_pid = ipc::get_pid_by_socket(&sockpath)?;
    let compositor_cgroup = get_cgroup(compositor_pid)
        .ok_or_else(|| anyhow::anyhow!("could not determine compositor's cgroup"))?;
    info!("compositor:{compositor_pid} {compositor_cgroup}");

    let launcher_cgroups = launcher_app_cgroups();

    let dbus_conn = zbus::Connection::session()
        .await
        .map_err(|e| anyhow::anyhow!("DBus connection error: {e}"))?;
    let systemd = SystemdClient::new(&dbus_conn)
        .await
        .map_err(|e| anyhow::anyhow!("failed to create systemd manager proxy: {e}"))?;

    let mut ipc = IpcConnection::connect(&sockpath).await?;
    ipc.subscribe_window().await?;

    loop {
        let con = match ipc.next_new_window().await {
            Ok(con) => con,
            Err(err) => {
                error!("Sway IPC connection error: {err}");
                return Err(err.into());
            }
        };
        handle_new_window(&systemd, &compositor_cgroup, &launcher_cgroups, con).await;
    }
}
