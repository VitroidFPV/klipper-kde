import QtQuick
import QtTest
import "../package/contents/ui" as Widget

TestCase {
    name: "TemperatureHistory"

    Widget.MoonrakerClient {
        id: client
        connectionEnabled: false
    }

    function test_frequentUpdatesKeepHistory() {
        for (var i = 0; i < 7; ++i) {
            client.updateStatus({ extruder: { temperature: 200 + i, target: 210 } });
            wait(250);
        }
        verify(client.temperatureHistory.length >= 2,
            "Frequent updates must add points across multiple seconds");
    }
}
