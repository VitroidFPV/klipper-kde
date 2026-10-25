// Immutable merges make nested status changes visible to QML bindings.
function merge(base, patch) {
    var result = Object.assign({}, base);
    Object.keys(patch).forEach(function(key) {
        var value = patch[key];
        result[key] = value !== null && typeof value === "object" && !Array.isArray(value)
            ? merge(base[key] || {}, value) : value;
    });
    return result;
}

function websocketUrl(address) {
    var url = address.trim().replace(/\/+$/, "");
    if (!/^(https?|wss?):\/\/[^/?#]+(\/[^?#]*)?$/.test(url))
        return "";
    url = url.replace(/^http:/, "ws:").replace(/^https:/, "wss:");
    return url.endsWith("/websocket") ? url : url + "/websocket";
}

function subscription(available) {
    var wanted = {
        print_stats: ["state", "message", "filename", "print_duration", "total_duration", "filament_used", "info"],
        display_status: ["progress", "message"],
        virtual_sdcard: ["progress"]
    };
    var objects = {};
    Object.keys(wanted).forEach(function(name) {
        if (available.indexOf(name) !== -1)
            objects[name] = wanted[name];
    });
    return objects;
}
