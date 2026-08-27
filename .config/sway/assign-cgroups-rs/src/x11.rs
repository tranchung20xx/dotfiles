//! Fallback PID lookup for X11/XWayland windows.
//!
//! Sway (>= 1.6.1 with wlroots >= 0.14) can resolve the PID for Xwayland
//! clients itself via XRes and reports it directly in the IPC `pid` field, so
//! this path is mainly needed for plain i3 and older Sway releases.
//!
//! Preference order matches upstream: X-Resource extension first (works even
//! when the client doesn't cooperate), falling back to the `_NET_WM_PID`
//! property.

use anyhow::{anyhow, Context, Result};
use x11rb::protocol::res::{self, ConnectionExt as _, ClientIdMask, ClientIdSpec};
use x11rb::protocol::xproto::{AtomEnum, ConnectionExt as _};
use x11rb::rust_connection::RustConnection;

pub struct X11PidGetter {
    conn: RustConnection,
    net_wm_pid_atom: u32,
    has_res: bool,
}

impl X11PidGetter {
    pub fn new() -> Result<Self> {
        let (conn, _screen_num) =
            RustConnection::connect(None).context("failed to connect to the X server")?;

        let has_res = match res::query_version(&conn, 1, 2) {
            Ok(cookie) => cookie.reply().is_ok(),
            Err(_) => false,
        };
        if !has_res {
            tracing::warn!(
                "X-Resource extension is not available; \
                 PID lookup for X11 windows will rely on _NET_WM_PID only"
            );
        }

        let atom = conn
            .intern_atom(false, b"_NET_WM_PID")?
            .reply()
            .context("failed to intern _NET_WM_PID atom")?
            .atom;

        Ok(Self { conn, net_wm_pid_atom: atom, has_res })
    }

    pub fn get_pid(&self, window: u32) -> Result<i32> {
        if self.has_res {
            if let Ok(pid) = self.get_pid_via_xres(window) {
                return Ok(pid);
            }
        }
        self.get_pid_via_net_wm_pid(window)
    }

    fn get_pid_via_xres(&self, window: u32) -> Result<i32> {
        let spec = ClientIdSpec { client: window, mask: ClientIdMask::LOCAL_CLIENT_PID };
        let reply = self
            .conn
            .res_query_client_ids(&[spec])?
            .reply()
            .context("XRes QueryClientIds failed")?;
        for id in reply.ids {
            if id.spec.client > 0 && id.spec.mask.contains(ClientIdMask::LOCAL_CLIENT_PID) {
                if let Some(&pid) = id.value.first() {
                    return Ok(pid as i32);
                }
            }
        }
        Err(anyhow!("XRes did not return a PID for window {window:#x}"))
    }

    fn get_pid_via_net_wm_pid(&self, window: u32) -> Result<i32> {
        let reply = self
            .conn
            .get_property(false, window, self.net_wm_pid_atom, AtomEnum::CARDINAL, 0, 1)?
            .reply()
            .context("failed to read _NET_WM_PID property")?;
        reply
            .value32()
            .and_then(|mut it| it.next())
            .map(|pid| pid as i32)
            .ok_or_else(|| anyhow!("_NET_WM_PID not set on window {window:#x}"))
    }
}
