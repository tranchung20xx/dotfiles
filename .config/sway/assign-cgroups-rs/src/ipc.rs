//! Minimal async client for the i3/sway IPC protocol.
//!
//! Only what we need is implemented: connecting to the socket, subscribing to
//! the `window` event, and decoding `window::new` events.

use std::io;
use std::os::unix::net::UnixStream as StdUnixStream;
use std::process::Command;

use serde::Deserialize;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::UnixStream;

const MAGIC: &[u8; 6] = b"i3-ipc";
const HEADER_LEN: usize = 14;

const MSG_TYPE_SUBSCRIBE: u32 = 2;
const EVENT_BIT: u32 = 1 << 31;
const EVENT_TYPE_WINDOW: u32 = 3;

/// `window_properties` block on a container (X11 apps only).
#[derive(Debug, Deserialize, Default)]
pub struct WindowProperties {
    pub class: Option<String>,
}

/// The subset of the i3ipc `Con` (container) node that we care about.
#[derive(Debug, Deserialize, Default)]
pub struct Con {
    /// Wayland app_id (sway) — absent for X11/XWayland windows.
    pub app_id: Option<String>,
    /// PID of the owning process. Only populated by sway, not i3.
    pub pid: Option<i32>,
    /// X11 window id, present for XWayland/X11 windows.
    pub window: Option<i64>,
    pub window_properties: Option<WindowProperties>,
}

impl Con {
    /// Best-effort app identifier: app_id, falling back to the X11 WM_CLASS.
    pub fn app_id_or_class(&self) -> Option<String> {
        self.app_id
            .clone()
            .or_else(|| self.window_properties.as_ref().and_then(|p| p.class.clone()))
    }
}

#[derive(Debug, Deserialize)]
pub struct WindowEvent {
    #[allow(dead_code)]
    pub change: String,
    pub container: Con,
}

/// Locate the sway/i3 IPC socket path, mirroring how i3ipc-python does it:
/// prefer the env vars, then ask the running compositor via its CLI.
pub fn find_socket_path() -> io::Result<String> {
    if let Ok(path) = std::env::var("SWAYSOCK") {
        return Ok(path);
    }
    if let Ok(path) = std::env::var("I3SOCK") {
        return Ok(path);
    }
    for (cmd, arg) in [("sway", "--get-socketpath"), ("i3", "--get-socketpath")] {
        if let Ok(output) = Command::new(cmd).arg(arg).output() {
            if output.status.success() {
                let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                if !path.is_empty() {
                    return Ok(path);
                }
            }
        }
    }
    Err(io::Error::new(
        io::ErrorKind::NotFound,
        "could not determine sway/i3 IPC socket path \
         (set SWAYSOCK or I3SOCK, or ensure sway/i3 is on PATH)",
    ))
}

/// Get the peer PID of whatever process is listening on `sockpath`, using
/// SO_PEERCRED on a fresh connection. This is how we identify the
/// compositor's own PID (and from there, its cgroup).
pub fn get_pid_by_socket(sockpath: &str) -> io::Result<i32> {
    let stream = StdUnixStream::connect(sockpath)?;
    let ucred = get_peer_cred(&stream)?;
    Ok(ucred.pid)
}

struct UCred {
    pid: i32,
}

fn get_peer_cred(stream: &StdUnixStream) -> io::Result<UCred> {
    use std::os::fd::AsRawFd;

    let fd = stream.as_raw_fd();
    let mut cred: libc::ucred = unsafe { std::mem::zeroed() };
    let mut len = std::mem::size_of::<libc::ucred>() as libc::socklen_t;

    let ret = unsafe {
        libc::getsockopt(
            fd,
            libc::SOL_SOCKET,
            libc::SO_PEERCRED,
            &mut cred as *mut _ as *mut libc::c_void,
            &mut len,
        )
    };
    if ret != 0 {
        return Err(io::Error::last_os_error());
    }
    Ok(UCred { pid: cred.pid })
}

/// A connected IPC socket, subscribed to window events.
pub struct IpcConnection {
    stream: UnixStream,
}

impl IpcConnection {
    pub async fn connect(sockpath: &str) -> io::Result<Self> {
        let stream = UnixStream::connect(sockpath).await?;
        Ok(Self { stream })
    }

    async fn write_message(&mut self, msg_type: u32, payload: &[u8]) -> io::Result<()> {
        let mut buf = Vec::with_capacity(HEADER_LEN + payload.len());
        buf.extend_from_slice(MAGIC);
        buf.extend_from_slice(&(payload.len() as u32).to_le_bytes());
        buf.extend_from_slice(&msg_type.to_le_bytes());
        buf.extend_from_slice(payload);
        self.stream.write_all(&buf).await
    }

    async fn read_message(&mut self) -> io::Result<(u32, Vec<u8>)> {
        let mut header = [0u8; HEADER_LEN];
        self.stream.read_exact(&mut header).await?;
        if &header[0..6] != MAGIC {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "bad i3-ipc magic"));
        }
        let len = u32::from_le_bytes(header[6..10].try_into().unwrap()) as usize;
        let msg_type = u32::from_le_bytes(header[10..14].try_into().unwrap());
        let mut payload = vec![0u8; len];
        self.stream.read_exact(&mut payload).await?;
        Ok((msg_type, payload))
    }

    /// Subscribe to the `window` event stream and consume the ack reply.
    pub async fn subscribe_window(&mut self) -> io::Result<()> {
        let payload = br#"["window"]"#;
        self.write_message(MSG_TYPE_SUBSCRIBE, payload).await?;
        let (_type, reply) = self.read_message().await?;
        #[derive(Deserialize)]
        struct SubscribeReply {
            success: bool,
        }
        let reply: SubscribeReply = serde_json::from_slice(&reply).map_err(|e| {
            io::Error::new(io::ErrorKind::InvalidData, format!("bad subscribe reply: {e}"))
        })?;
        if !reply.success {
            return Err(io::Error::new(io::ErrorKind::Other, "IPC subscribe was rejected"));
        }
        Ok(())
    }

    /// Block until the next `window::new` event arrives, skipping any other
    /// window sub-events (focus, close, move, ...).
    pub async fn next_new_window(&mut self) -> io::Result<Con> {
        loop {
            let (msg_type, payload) = self.read_message().await?;
            if msg_type != (EVENT_BIT | EVENT_TYPE_WINDOW) {
                continue;
            }
            let event: WindowEvent = match serde_json::from_slice(&payload) {
                Ok(e) => e,
                Err(e) => {
                    tracing::warn!("failed to decode window event: {e}");
                    continue;
                }
            };
            if event.change == "new" {
                return Ok(event.container);
            }
        }
    }
}
