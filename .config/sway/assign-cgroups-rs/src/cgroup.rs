//! cgroup (v2, unified hierarchy) inspection and systemd unit-name escaping.

use std::collections::{HashMap, VecDeque};
use std::fs;

use once_cell::sync::Lazy;
use regex::Regex;

/// Ids of known launcher applications that are not special surfaces. When the
/// app is started using one of those, it should be moved to a new cgroup.
/// A launcher should only be listed here if it creates a cgroup of its own.
pub const LAUNCHER_APPS: &[&str] = &["nwgbar", "nwgdmenu", "nwggrid", "onagre"];

static ESCAPE_RE: Lazy<Regex> = Lazy::new(|| Regex::new(r"[^A-Za-z0-9:._\\]").unwrap());

/// Escape `app_id` for use in a systemd unit name.
///
/// The "unit prefix" must consist of one or more valid characters (ASCII
/// letters, digits, ":", "-", "_", ".", and "\"). The total length of the
/// unit name including the suffix must not exceed 256 characters
/// (systemd.unit(5)). We also escape "-" to avoid creating extra slices.
pub fn escape_app_id(app_id: &str) -> String {
    ESCAPE_RE
        .replace_all(app_id, |caps: &regex::Captures| {
            caps[0].bytes().map(|b| format!("\\x{b:02x}")).collect::<String>()
        })
        .into_owned()
}

pub fn launcher_app_cgroups() -> Vec<String> {
    LAUNCHER_APPS
        .iter()
        .map(|app| format!("app-{}.slice", escape_app_id(app)))
        .collect()
}

/// Read the (single, unified-hierarchy) cgroup path for `pid` from
/// `/proc/<pid>/cgroup`.
pub fn get_cgroup(pid: i32) -> Option<String> {
    let content = fs::read_to_string(format!("/proc/{pid}/cgroup")).ok()?;
    let line = content.trim();
    line.rsplit(':').next().map(|s| s.to_string())
}

/// Decide whether `cgroup` belongs to the compositor or a known launcher, and
/// therefore needs to be split off into its own scope.
pub fn cgroup_change_needed(
    cgroup: Option<&str>,
    compositor_cgroup: &str,
    launcher_cgroups: &[String],
) -> bool {
    let Some(cgroup) = cgroup else {
        return false;
    };
    if launcher_cgroups.iter().any(|l| cgroup.contains(l.as_str())) {
        return true;
    }
    cgroup == compositor_cgroup
}

/// Recursively enumerate all descendant PIDs of `pid`.
///
/// Prefers the fast `/proc/<pid>/task/<pid>/children` interface (needs
/// `CONFIG_CHECKPOINT_RESTORE`, enabled on essentially all desktop distro
/// kernels); falls back to a full `/proc` scan by parent PID otherwise.
pub fn children_recursive(pid: i32) -> Vec<i32> {
    let mut result = Vec::new();
    let mut queue = VecDeque::new();
    queue.push_back(pid);

    let mut fallback_map: Option<HashMap<i32, Vec<i32>>> = None;

    while let Some(current) = queue.pop_front() {
        let kids = match direct_children_fast(current) {
            Some(kids) => kids,
            None => {
                let map = fallback_map.get_or_insert_with(build_children_map);
                map.get(&current).cloned().unwrap_or_default()
            }
        };
        for kid in kids {
            result.push(kid);
            queue.push_back(kid);
        }
    }
    result
}

fn direct_children_fast(pid: i32) -> Option<Vec<i32>> {
    let content = fs::read_to_string(format!("/proc/{pid}/task/{pid}/children")).ok()?;
    Some(content.split_whitespace().filter_map(|s| s.parse().ok()).collect())
}

/// Build a full pid -> children map by scanning `/proc/*/stat`. Used only as
/// a fallback when the kernel doesn't expose the `children` file.
fn build_children_map() -> HashMap<i32, Vec<i32>> {
    let mut map: HashMap<i32, Vec<i32>> = HashMap::new();
    let Ok(entries) = fs::read_dir("/proc") else {
        return map;
    };
    for entry in entries.flatten() {
        let Some(pid_str) = entry.file_name().to_str().map(str::to_owned) else {
            continue;
        };
        let Ok(pid) = pid_str.parse::<i32>() else {
            continue;
        };
        let Ok(stat) = fs::read_to_string(format!("/proc/{pid}/stat")) else {
            continue;
        };
        // Format: "pid (comm) state ppid ...". `comm` may contain
        // spaces/parens, so split on the *last* ')'.
        let Some(close_paren) = stat.rfind(')') else {
            continue;
        };
        let rest = &stat[close_paren + 1..];
        let mut fields = rest.split_whitespace();
        let _state = fields.next();
        let Some(ppid) = fields.next().and_then(|s| s.parse::<i32>().ok()) else {
            continue;
        };
        map.entry(ppid).or_default().push(pid);
    }
    map
}
