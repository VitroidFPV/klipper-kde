.pragma library

function known(value) {
    return typeof value === "number" && isFinite(value) && value >= 0;
}

function duration(seconds) {
    if (!known(seconds)) return "—";
    var minutes = Math.floor(seconds / 60);
    return minutes >= 60 ? Math.floor(minutes / 60) + "h " + minutes % 60 + "m"
        : minutes > 0 ? minutes + "m " + Math.floor(seconds % 60) + "s" : Math.floor(seconds) + "s";
}

function filament(mm) {
    return known(mm) ? (mm / 1000).toFixed(2) + " m" : "—";
}

function state(ready, connected, klippyState, status) {
    if (!connected) return "Offline";
    if (klippyState === "shutdown") return "Shutdown";
    if (!ready) return "Connecting";
    var value = (status.print_stats || {}).state;
    return ({ printing: "Printing", paused: "Paused", complete: "Complete",
        cancelled: "Cancelled", error: "Error", standby: "Idle" })[value] || "Idle";
}

function thumbnail(address, filename, thumbnails) {
    if (!filename || !thumbnails || !thumbnails.length) return "";
    var best = thumbnails.reduce(function(a, b) { return b.width > a.width ? b : a; });
    if (!best.relative_path) return "";
    var base = address.trim().replace(/\/+$/, "").replace(/\/websocket$/, "")
        .replace(/^ws:/, "http:").replace(/^wss:/, "https:");
    var directory = filename.slice(0, filename.lastIndexOf("/") + 1);
    var path = (directory + best.relative_path).split("/").map(encodeURIComponent).join("/");
    return base + "/server/files/gcodes/" + path;
}

// Keep the view independent of Moonraker's nested objects and units.
function printer(name, address, status, metadata, history, lastStatusAt, historyUpdatedAt, ready) {
    var stats = status.print_stats || {};
    var info = stats.info || {};
    var progress = (status.display_status || {}).progress;
    if (!known(progress)) progress = (status.virtual_sdcard || {}).progress;
    progress = known(progress) ? Math.max(0, Math.min(1, progress)) : 0;
    var elapsed = stats.print_duration;
    var total = progress > 0 && known(elapsed) && elapsed > 0 ? elapsed / progress : metadata.estimated_time;
    var remaining = known(total) && known(elapsed) ? Math.max(0, total - elapsed) : undefined;
    var active = ready && stats.state === "printing";
    var updated = Math.max(lastStatusAt, historyUpdatedAt);
    return {
        name: name || qsTr("Klipper printer"), filename: stats.filename || "—", progress: progress,
        thumbnail: thumbnail(address, stats.filename, metadata.thumbnails),
        filament: filament(metadata.filament_total),
        layer: known(info.current_layer) ? info.current_layer + (info.total_layer > 0 ? qsTr(" of ") + info.total_layer : "") : "—",
        remaining: duration(remaining), slicer: duration(metadata.estimated_time), total: duration(total),
        eta: active && known(remaining) ? Qt.formatTime(new Date(lastStatusAt + remaining * 1000), "hh:mm") : "—",
        lastUpdated: updated ? Qt.formatDateTime(new Date(updated), "d MMM, hh:mm") : "—",
        history: [
            { label: qsTr("Total print time"), value: duration(history.total_print_time) },
            { label: qsTr("Longest print"), value: duration(history.longest_print) },
            { label: qsTr("Average print"), value: duration(history.total_jobs > 0 ? history.total_print_time / history.total_jobs : undefined) },
            { label: qsTr("Filament used"), value: filament(history.total_filament_used) },
            { label: qsTr("Total jobs"), value: known(history.total_jobs) ? String(history.total_jobs) : "—" }
        ]
    };
}
