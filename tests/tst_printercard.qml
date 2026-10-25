import QtQuick
import QtTest
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

    function sample(x, y) {
        var preview;
        for (var child of card.children) {
            if (child instanceof Image) {
                preview = child;
                break;
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
