//! Talks to `org.freedesktop.systemd1.Manager` over the session bus to start
//! transient scope units, mirroring `systemd-run --scope`.

use std::time::Duration;

use zbus::zvariant::{OwnedObjectPath, Value};
use zbus::{dbus_proxy, Connection};

#[dbus_proxy(
    interface = "org.freedesktop.systemd1.Manager",
    default_service = "org.freedesktop.systemd1",
    default_path = "/org/freedesktop/systemd1"
)]
trait SystemdManager {
    #[dbus_proxy(name = "StartTransientUnit")]
    fn start_transient_unit(
        &self,
        name: &str,
        mode: &str,
        properties: Vec<(&str, Value<'_>)>,
        aux: Vec<(&str, Vec<(&str, Value<'_>)>)>,
    ) -> zbus::Result<OwnedObjectPath>;
}

pub struct SystemdClient<'a> {
    proxy: SystemdManagerProxy<'a>,
}

impl<'a> SystemdClient<'a> {
    pub async fn new(conn: &Connection) -> zbus::Result<SystemdClient<'a>> {
        let proxy = SystemdManagerProxy::new(conn).await?;
        Ok(Self { proxy })
    }

    /// Start a transient scope unit `sd_unit` under slice `sd_slice`
    /// containing `pids`. Retries up to 3 times on DBus errors, since the
    /// caller may be racing a short-lived child process exiting.
    pub async fn assign_scope(&self, sd_unit: &str, sd_slice: &str, pids: &[u32]) -> zbus::Result<()> {
        const MAX_ATTEMPTS: u32 = 3;
        let mut attempt = 0;
        loop {
            attempt += 1;
            let properties = vec![
                ("PIDs", Value::from(pids.to_vec())),
                ("Slice", Value::from(sd_slice)),
            ];
            match self.proxy.start_transient_unit(sd_unit, "fail", properties, vec![]).await {
                Ok(_) => return Ok(()),
                Err(err) if attempt < MAX_ATTEMPTS => {
                    tracing::debug!(
                        "StartTransientUnit attempt {attempt}/{MAX_ATTEMPTS} failed: {err}; retrying"
                    );
                    tokio::time::sleep(Duration::from_millis(100 * attempt as u64)).await;
                }
                Err(err) => return Err(err),
            }
        }
    }
}
