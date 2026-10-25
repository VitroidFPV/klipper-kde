import QtQuick
import QtTest
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../package/contents/ui" as Widget

TestCase {
    id: testCase
    name: "PrinterCard"
    when: windowShown
    visible: true
    width: 400
    height: 600

    Widget.PrinterCard {
        id: card
        anchors.fill: parent
        Kirigami.Theme.inherit: false
        Kirigami.Theme.highlightColor: "#f0b3c4"
        printerState: "Printing"
        printer: ({
            name: "Preview", progress: 0.5, filename: "test.gcode",
            filament: "1 m", layer: "1 of 2", remaining: "1m",
            slicer: "2m", total: "2m", eta: "12:00", history: [],
            thumbnail: "data:image/svg+xml," + encodeURIComponent(
                '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">'
                + '<path fill="cyan" d="M0 0h50v50H0z"/>'
                + '<path fill="red" d="M50 0h50v50H50z"/>'
                + '<path fill="#008080" d="M0 50h50v50H0z"/></svg>')
        })
    }

    function sample(x, y, preview) {
        if (!preview) {
            for (var child of card.children) {
                if (child instanceof Image) {
                    preview = child;
                    break;
                }
            }
        }
        verify(preview !== undefined);
        tryCompare(preview, "status", Image.Ready);
        var point = preview.mapToItem(card,
            (preview.width - preview.paintedWidth) / 2 + x * preview.paintedWidth,
            (preview.height - preview.paintedHeight) / 2 + y * preview.paintedHeight);
        return grabImage(card).pixel(Math.floor(point.x), Math.floor(point.y));
    }

    function verifyTint(pixel, tint) {
        verify(pixel.r > 0 && pixel.g > 0 && pixel.b > 0);
        verify(Math.abs(pixel.g / pixel.r - tint.g / tint.r) < 0.02,
            "Expected theme tint " + tint + ", got " + pixel);
        verify(Math.abs(pixel.b / pixel.r - tint.b / tint.r) < 0.02,
            "Expected theme tint " + tint + ", got " + pixel);
    }

    function test_idleRecentPrints() {
        var recent = findChild(card, "recentPrintsView");
        var graphButton = findChild(card, "temperatureViewButton");
        var modelButton = findChild(card, "modelViewButton");
        card.printerState = "Idle";
        compare(recent.visible, true);
        compare(modelButton.text, "Recent prints");
        card.recentPrints = [{ filename: "last.gcode", thumbnail: "", status: "Complete",
            duration: "2m", date: "25 Oct, 12:00", failed: false }];
        compare(recent.jobs.length, 1);
        waitForRendering(card);
        mouseClick(graphButton);
        compare(recent.visible, false);
        mouseClick(modelButton);
        compare(recent.visible, true);
        card.printerState = "Paused";
        compare(recent.visible, false);
        card.printerState = "Printing";
        card.recentPrints = [];
    }

    function test_recentPrintScrollbar() {
        card.printerState = "Idle";
        var jobs = [];
        for (var i = 0; i < 10; ++i)
            jobs.push({ filename: "a-long-print-filename-" + i + ".gcode", thumbnail: "",
                status: "Complete", duration: "1h 32m", date: "25 Oct, 12:00", failed: false });
        card.recentPrints = jobs;
        var list = findChild(card, "recentPrintList");
        var scrollbar = findChild(card, "recentPrintScrollBar");
        tryCompare(scrollbar, "visible", true);
        tryVerify(function() { return list.itemAtIndex(0) !== null; });
        var row = list.itemAtIndex(0);
        var right = row.mapToItem(list, row.width, 0).x;
        var left = scrollbar.mapToItem(list, 0, 0).x;
        verify(right + Kirigami.Units.smallSpacing <= left,
            "Print items must leave a gap before the scrollbar: item right=" + right + ", scrollbar left=" + left);
        verify(scrollbar.width <= Kirigami.Units.smallSpacing * 2, "Scrollbar should stay compact");
        card.printerState = "Printing";
        card.recentPrints = [];
    }

    function test_recentPrintWheelScrolling() {
        card.printerState = "Idle";
        var jobs = [];
        for (var i = 0; i < 10; ++i)
            jobs.push({ filename: "print-" + i + ".gcode", thumbnail: "", status: "Complete",
                duration: "1h", date: "25 Oct, 12:00", failed: false });
        card.recentPrints = jobs;
        var list = findChild(card, "recentPrintList");
        tryVerify(function() { return list.contentHeight > list.height; });
        list.positionViewAtBeginning();
        wait(500);
        for (var step = 0; step < 3; ++step) {
            mouseWheel(list, list.width / 2, list.height / 2, 0, -120);
            wait(500);
        }
        var slowDistance = list.contentY - list.originY;
        list.cancelFlick();
        list.positionViewAtBeginning();
        wait(500);
        for (var rapidStep = 0; rapidStep < 3; ++rapidStep)
            mouseWheel(list, list.width / 2, list.height / 2, 0, -120, Qt.NoButton, Qt.NoModifier, 20);
        wait(1000);
        var rapidDistance = list.contentY - list.originY;
        verify(slowDistance > 0);
        verify(Math.abs(rapidDistance - slowDistance) < 2,
            "Equal wheel input should travel equally: slow=" + slowDistance + ", rapid=" + rapidDistance);
        list.cancelFlick();
        card.printerState = "Printing";
        card.recentPrints = [];
    }

    function test_switchViews() {
        var graphButton = findChild(card, "temperatureViewButton");
        var modelButton = findChild(card, "modelViewButton");
        var graph = findChild(card, "temperatureGraph");
        var state = findChild(card, "printerStateLabel");
        var progress = findChild(card, "printProgress");
        var filename = findChild(card, "printFilename");
        var stats = findChild(card, "printStats");
        verify(graphButton && modelButton && graph && state && progress && filename && stats);
        compare(modelButton.icon.name, "draw-cuboid");
        compare(graphButton.icon.name, "view-media-chart");
        compare(modelButton.display, QQC2.AbstractButton.IconOnly);
        compare(graphButton.display, QQC2.AbstractButton.IconOnly);
        compare(modelButton.checked, true);
        compare(graphButton.checked, false);
        card.temperatureStatus = { extruder: { temperature: 210, target: 215 },
            heater_bed: { temperature: 60, target: 60 } };
        card.temperatureHistory = [
            { time: 1000, extruder: 208, extruderTarget: 215, bed: 59, bedTarget: 60 },
            { time: 2000, extruder: 210, extruderTarget: 215, bed: 60, bedTarget: 60 }
        ];
        mouseClick(graphButton);
        compare(card.showTemperatures, true);
        compare(graphButton.checked, true);
        compare(modelButton.checked, false);
        compare(graph.visible, true);
        compare(graph.history.length, 2);
        var chart = findChild(graph, "temperatureLineChart");
        verify(chart);
        compare(chart.valueSources.length, 4);
        compare(chart.valueSources[0].array[0], 210);
        compare(chart.valueSources[0].array[1], 208);
        verify(state.visible && progress.visible && filename.visible && stats.visible);
        waitForRendering(graph);
        mouseClick(graphButton);
        compare(card.showTemperatures, true);
        compare(graphButton.checked, true);
        compare(modelButton.checked, false);
        mouseClick(modelButton);
        compare(card.showTemperatures, false);
        compare(modelButton.checked, true);
        compare(graphButton.checked, false);
        compare(graph.visible, false);
        mouseClick(modelButton);
        compare(card.showTemperatures, false);
        compare(modelButton.checked, true);
        compare(graphButton.checked, false);
    }

    function test_recentThumbnailTint() {
        card.printerState = "Idle";
        card.recentPrints = [{ filename: "last.gcode", thumbnail: card.printer.thumbnail,
            status: "Complete", duration: "2m", date: "25 Oct, 12:00", failed: false }];
        var recent = findChild(card, "recentPrintsView");
        tryVerify(function() { return findChild(recent, "recentPrintThumbnail") !== null; });
        var thumbnail = findChild(recent, "recentPrintThumbnail");
        compare(sample(0.25, 0.25, thumbnail), Qt.color("cyan"));
        var transparent = sample(0.75, 0.75, thumbnail);
        card.tintModelImage = true;
        waitForRendering(card);
        verifyTint(sample(0.25, 0.25, thumbnail), card.Kirigami.Theme.highlightColor);
        compare(sample(0.75, 0.75, thumbnail), transparent);
        card.tintModelImage = false;
        waitForRendering(card);
        compare(sample(0.25, 0.25, thumbnail), Qt.color("cyan"));
        card.printerState = "Printing";
        card.recentPrints = [];
    }

    function test_themeTint() {
        verify(GraphicsInfo.api !== GraphicsInfo.Software,
            "This pixel test requires an OpenGL or Vulkan Qt Quick backend.");
        waitForRendering(card);
        var original = sample(0.25, 0.25);
        compare(original, Qt.color("cyan"));
        var transparent = sample(0.75, 0.75);

        card.tintModelImage = true;
        waitForRendering(card);
        var cyanTinted = sample(0.25, 0.25);
        verifyTint(cyanTinted, card.Kirigami.Theme.highlightColor);
        verifyTint(sample(0.75, 0.25), card.Kirigami.Theme.highlightColor);
        var shaded = sample(0.25, 0.75);
        verifyTint(shaded, card.Kirigami.Theme.highlightColor);
        verify(shaded.r < cyanTinted.r, "Tinting must preserve shading.");
        compare(sample(0.75, 0.75), transparent);

        card.Kirigami.Theme.highlightColor = "#80c0f0";
        waitForRendering(card);
        verifyTint(sample(0.25, 0.25), card.Kirigami.Theme.highlightColor);

        card.tintModelImage = false;
        waitForRendering(card);
        compare(sample(0.25, 0.25), original);
    }
}
