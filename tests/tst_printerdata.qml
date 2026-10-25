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

    function test_recentPrints() {
        var jobs = [{ status: "in_progress", filename: "active.gcode" },
            { status: "completed", filename: "bins/test.gcode", print_duration: 120,
              end_time: 1700000000, metadata: { thumbnails: [{ width: 100, relative_path: ".thumbs/test.png" }] } },
            { status: "error", filename: "deleted.gcode", exists: false,
              metadata: { thumbnails: [{ width: 100, relative_path: "deleted.png" }] } },
            { status: "cancelled", filename: "cancelled.gcode" },
            { status: "completed", filename: "older.gcode" }];
        var prints = Data.recentPrints("http://printer.local", jobs);
        compare(prints.length, 4);
        compare(prints[0].filename, "bins/test.gcode");
        compare(prints[0].duration, "2m 0s");
        compare(prints[0].status, "Complete");
        compare(prints[0].thumbnail, "http://printer.local/server/files/gcodes/bins/.thumbs/test.png");
        verify(prints[0].date !== "—");
        compare(prints[1].failed, true);
        compare(prints[1].thumbnail, "");
        compare(prints[1].duration, "—");
        compare(prints[1].date, "—");
        compare(prints[2].status, "Cancelled");
        compare(Data.recentPrints("", []).length, 0);
        for (var i = 0; i < 10; ++i)
            jobs.push({ status: "completed", filename: "older-" + i + ".gcode" });
        prints = Data.recentPrints("", jobs);
        compare(prints.length, 10);
        compare(prints[0].filename, "bins/test.gcode");
        compare(prints[9].filename, "older-5.gcode");
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
