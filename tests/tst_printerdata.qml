import QtQuick
import QtTest
import "../package/contents/ui/PrinterData.js" as Data

TestCase {
    name: "PrinterData"

    function test_liveData() {
        var status = { print_stats: { state: "printing", filename: "bins/test file.gcode",
            print_duration: 1800, info: { current_layer: 25, total_layer: 123 } },
            virtual_sdcard: { progress: 0.5 } };
        var metadata = { estimated_time: 3000, filament_total: 6620,
            thumbnails: [{ width: 32, relative_path: ".thumbs/small.png" },
                { width: 400, relative_path: ".thumbs/big #1.png" }] };
        var history = { total_jobs: 2, total_print_time: 7200, longest_print: 5000, total_filament_used: 12000 };
        var printer = Data.printer("Printer", "ws://printer.local/prefix/websocket", status, metadata, history, 100000, 0, true);
        compare(printer.progress, 0.5);
        compare(printer.layer, "25 of 123");
        compare(printer.filament, "6.62 m");
        compare(printer.remaining, "30m 0s");
        compare(printer.total, "1h 0m");
        compare(printer.history[2].value, "1h 0m");
        compare(printer.thumbnail, "http://printer.local/prefix/server/files/gcodes/bins/.thumbs/big%20%231.png");
        verify(printer.eta !== "—");
        compare(Data.state(true, true, "ready", status), "Printing");
        status.print_stats.state = "paused";
        compare(Data.state(true, true, "ready", status), "Paused");
        compare(Data.printer("", "", status, metadata, history, 100000, 0, true).eta, "—");
        compare(Data.state(false, false, "unknown", status), "Offline");
        compare(Data.state(false, true, "shutdown", status), "Shutdown");
    }

    function test_missingData() {
        var printer = Data.printer("", "", {}, {}, {}, 0, 0, false);
        compare(printer.remaining, "—");
        compare(printer.layer, "—");
        compare(printer.thumbnail, "");
        compare(printer.lastUpdated, "—");
        compare(printer.history[4].value, "—");
        compare(Data.duration(0), "0s");
        compare(Data.filament(0), "0.00 m");
        compare(Data.state(false, true, "unknown", {}), "Connecting");
        compare(Data.state(true, true, "ready", {print_stats: {state: "complete"}}), "Complete");
    }
}
