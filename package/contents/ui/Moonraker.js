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
        virtual_sdcard: ["progress"],
        extruder: ["temperature", "target"],
        heater_bed: ["temperature", "target"]
    };
    var objects = {};
    Object.keys(wanted).forEach(function(name) {
        if (available.indexOf(name) !== -1)
            objects[name] = wanted[name];
    });
    return objects;
}

// Moonraker stores one reading per second, with the newest reading last.
function temperatureHistory(store, endTime) {
    var extruder = store.extruder || {};
    var bed = store.heater_bed || {};
    var fields = [extruder.temperatures, extruder.targets, bed.temperatures, bed.targets];
    var count = Math.min(1200, Math.max.apply(null, fields.map(function(field) {
        return Array.isArray(field) ? field.length : 0;
    })));
    var samples = [];
    function reading(field, age) {
        return Array.isArray(field) ? field[field.length - 1 - age] : undefined;
    }
    for (var age = count - 1; age >= 0; --age) {
        samples.push({ time: endTime - age * 1000,
            extruder: reading(extruder.temperatures, age),
            extruderTarget: reading(extruder.targets, age),
            bed: reading(bed.temperatures, age),
            bedTarget: reading(bed.targets, age) });
    }
    return samples;
}
