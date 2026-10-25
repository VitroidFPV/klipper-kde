import QtQuick
import QtWebSockets
import "Moonraker.js" as Protocol

// One instance per printer. Only status, metadata and history requests are sent.
Item {
    id: root
    visible: false

    property string address: ""
    property bool connectionEnabled: true
    property string apiKey: "" // Optional, supplied by the caller; never persisted here.
    readonly property bool connected: socket.status === WebSocket.Open
    readonly property bool ready: connected && internal.subscribed && klippyState === "ready"
    readonly property string klippyState: internal.klippyState
    readonly property string error: internal.error
    readonly property var status: internal.status
    readonly property var metadata: internal.metadata
    readonly property var historyTotals: internal.historyTotals
    readonly property double lastStatusAt: internal.lastStatusAt
    readonly property double historyUpdatedAt: internal.historyUpdatedAt

    QtObject {
        id: internal
        property bool subscribed: false
        property string klippyState: "unknown"
        property string error: ""
        property var status: ({})
        property var metadata: ({})
        property var historyTotals: ({})
        property double lastStatusAt: 0
        property double historyUpdatedAt: 0
        property int nextId: 0
        property var pending: ({})
        property int retryDelay: 1000
    }

    function request(method, params, callback) {
        if (socket.status !== WebSocket.Open)
            return;
        var id = ++internal.nextId;
        internal.pending[id] = { callback: callback, sent: Date.now(), method: method };
        socket.sendTextMessage(JSON.stringify({ jsonrpc: "2.0", id: id, method: method, params: params || {} }));
    }

    function refreshHistory() {
        request("server.history.totals", {}, function(result) {
            internal.historyTotals = result.job_totals;
            internal.historyUpdatedAt = Date.now();
        });
    }

    function updateStatus(patch) {
        var previousFile = status.print_stats ? status.print_stats.filename : "";
        internal.status = Protocol.merge(status, patch);
        internal.lastStatusAt = Date.now();
        var filename = status.print_stats ? status.print_stats.filename : "";
        if (filename !== previousFile) {
            internal.metadata = {};
            if (filename) {
                request("server.files.metadata", { filename: filename }, function(result) {
                    // A previous file's response may arrive after a new job starts.
                    if (root.status.print_stats && root.status.print_stats.filename === filename)
                        internal.metadata = result;
                });
            }
        }
    }

    function subscribe() {
        internal.subscribed = false;
        request("printer.objects.list", {}, function(result) {
            request("printer.objects.subscribe", { objects: Protocol.subscription(result.objects) }, function(snapshot) {
                internal.status = {};
                updateStatus(snapshot.status);
                internal.subscribed = true;
            });
        });
    }

    function inspectServer() {
        request("server.info", {}, function(result) {
            internal.klippyState = result.klippy_state;
            if (result.klippy_state === "ready" && !internal.subscribed)
                subscribe();
        });
    }

    function receive(text) {
        var message;
        try { message = JSON.parse(text); }
        catch (e) { internal.error = "Invalid JSON received from Moonraker"; return; }
        if (message.id !== undefined) {
            var pending = internal.pending[message.id];
            delete internal.pending[message.id];
            if (!pending)
                return;
            if (message.error) {
                internal.error = pending.method + ": " + message.error.message;
                return;
            }
            pending.callback(message.result);
            return;
        }
        switch (message.method) {
        case "notify_status_update":
            if (internal.subscribed) updateStatus(message.params[0]);
            break;
        case "notify_klippy_ready":
            internal.klippyState = "ready";
            subscribe();
            break;
        case "notify_klippy_shutdown":
        case "notify_klippy_disconnected":
            internal.klippyState = message.method === "notify_klippy_shutdown" ? "shutdown" : "disconnected";
            internal.subscribed = false;
            break;
        case "notify_history_changed":
            refreshHistory();
            break;
        }
    }

    function restart(clearData) {
        reconnect.stop();
        socket.active = false;
        internal.pending = {};
        internal.subscribed = false;
        internal.klippyState = "unknown";
        internal.retryDelay = 1000;
        internal.error = "";
        if (clearData) {
            internal.status = {};
            internal.metadata = {};
            internal.historyTotals = {};
            internal.lastStatusAt = 0;
            internal.historyUpdatedAt = 0;
        }
        if (connectionEnabled && address) {
            if (!Protocol.websocketUrl(address))
                internal.error = "Enter an http, https, ws or wss Moonraker URL";
            else
                reconnect.start();
        }
    }

    onAddressChanged: restart(true)
    onApiKeyChanged: restart(false)
    onConnectionEnabledChanged: restart(false)
    Component.onCompleted: restart(false)

    WebSocket {
        id: socket
        url: Protocol.websocketUrl(root.address)
        active: false
        onTextMessageReceived: function(message) { root.receive(message); }
        onStatusChanged: function(status) {
            if (status === WebSocket.Open) {
                internal.error = "";
                internal.retryDelay = 1000;
                var identity = { client_name: "klipper-kde", version: "0.1.0", type: "desktop",
                    url: "https://github.com/VitroidFPV/klipper-kde" };
                if (root.apiKey) identity.api_key = root.apiKey;
                root.request("server.connection.identify", identity, function() {
                    root.inspectServer();
                    root.refreshHistory();
                });
            } else if (status === WebSocket.Error || status === WebSocket.Closed) {
                internal.subscribed = false;
                internal.klippyState = "unknown";
                internal.pending = {};
                if (status === WebSocket.Error) internal.error = errorString;
                active = false;
                if (root.connectionEnabled && Protocol.websocketUrl(root.address)) reconnect.start();
            }
        }
    }

    Timer {
        id: reconnect
        interval: internal.retryDelay
        onTriggered: {
            internal.retryDelay = Math.min(internal.retryDelay * 2, 30000);
            socket.active = true;
        }
    }

    // A round trip detects half-open sockets even while a printer is idle.
    Timer {
        interval: 5000
        repeat: true
        running: root.connected
        onTriggered: {
            var ids = Object.keys(internal.pending);
            for (var i = 0; i < ids.length; ++i) {
                if (Date.now() - internal.pending[ids[i]].sent > 15000) {
                    internal.error = "Moonraker request timed out";
                    socket.active = false;
                    return;
                }
            }
            if (ids.length === 0) root.inspectServer();
        }
    }
}
