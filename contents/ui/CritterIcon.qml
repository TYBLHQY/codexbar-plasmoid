import QtQuick
import org.kde.kirigami as Kirigami

// Panel meters: two stacked capsules on an 18×18pt (36px) grid, fill =
// remaining percent in the theme accent, with the provider "critter" face cut
// out of the top bar (Codex: eyes, Claude: asterisk eyes on a blockier bar).
// Geometry follows CodexBar's IconRenderer, but the bars bleed the full grid
// width and drop the 1pt outline so the meters stay readable — and match the
// rest of the panel — at thin panel heights (17px icons).
Canvas {
    id: canvas

    property string providerId: ""
    property real remainingPrimary: -1    // 0..100, -1 = unknown
    property real remainingSecondary: -1
    property bool stale: false
    property bool hideCritters: false
    property bool fillUsed: false        // fill = used percent instead of remaining
    property bool sideBySide: false      // two pills next to each other, not stacked
    property color baseColor: Kirigami.Theme.textColor
    property color fillColor: Kirigami.Theme.highlightColor

    // Drawing-grid aspect: three times as wide as it is tall for the side-by-side
    // pills, square when the two meters are stacked.
    readonly property real gridAspect: sideBySide ? 3 : 1

    onRemainingPrimaryChanged: requestPaint()
    onRemainingSecondaryChanged: requestPaint()
    onStaleChanged: requestPaint()
    onHideCrittersChanged: requestPaint()
    onFillUsedChanged: requestPaint()
    onSideBySideChanged: requestPaint()
    onBaseColorChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onProviderIdChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function rgba(c, a) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
    }

    function roundedRectPath(ctx, x, y, w, h, r) {
        r = Math.min(r, h / 2, w / 2)
        ctx.beginPath()
        ctx.moveTo(x + r, y)
        ctx.lineTo(x + w - r, y)
        ctx.arcTo(x + w, y, x + w, y + r, r)
        ctx.lineTo(x + w, y + h - r)
        ctx.arcTo(x + w, y + h, x + w - r, y + h, r)
        ctx.lineTo(x + r, y + h)
        ctx.arcTo(x, y + h, x, y + h - r, r)
        ctx.lineTo(x, y + r)
        ctx.arcTo(x, y, x + r, y, r)
        ctx.closePath()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)

        // 36-unit-tall drawing grid, 3× as wide when the pills sit side by side.
        var gridWidth = 36 * gridAspect
        var u = Math.min(width / gridWidth, height / 36)
        var ox = (width - gridWidth * u) / 2
        var oy = (height - 36 * u) / 2

        var trackFillAlpha = stale ? 0.08 : 0.15
        var fillAlpha = stale ? 0.55 : 1.0

        var isClaude = providerId === "claude"
        var critter = !hideCritters && (providerId === "codex" || providerId === "claude"
                                        || providerId === "openai" || providerId === "azure-openai")

        function drawBar(bx, by, bw, bh, radius, remaining) {
            var x = ox + bx * u, y = oy + by * u, w = bw * u, h = bh * u, r = radius * u

            // track
            ctx.fillStyle = rgba(baseColor, trackFillAlpha)
            roundedRectPath(ctx, x, y, w, h, r)
            ctx.fill()

            // left-to-right fill clipped to the capsule
            if (remaining >= 0) {
                var frac = Math.max(0, Math.min(1, remaining / 100))
                if (fillUsed)
                    frac = 1 - frac
                if (frac > 0) {
                    ctx.save()
                    roundedRectPath(ctx, x, y, w, h, r)
                    ctx.clip()
                    ctx.fillStyle = rgba(fillColor, fillAlpha)
                    ctx.fillRect(x, y, w * frac, h)
                    ctx.restore()
                }
            }
        }

        if (sideBySide) {
            // Side by side on the 108-unit grid: two 50-unit pills with 8 units
            // between them and 10 units of margin above and below.
            drawBar(0, 10, 50, 16, 8, remainingPrimary)
            drawBar(58, 10, 50, 16, 8, remainingSecondary)
        } else {
            // Stacked capsules, balanced on the 36-unit grid: 36×14 at y3 and
            // 36×12 at y21. Claude keeps its blockier corners.
            var topRadius = isClaude ? 4 : 7
            drawBar(0, 3, 36, 14, topRadius, remainingPrimary)
            drawBar(0, 21, 36, 12, 6, remainingSecondary)
        }

        // critter face cut out of the bar that carries it (the left pill when
        // the meters sit side by side)
        if (critter) {
            var faceX = sideBySide ? 25 : 18
            var faceY = sideBySide ? 18 : 10
            var cy = oy + faceY * u
            var cxL = ox + (faceX - 7) * u
            var cxR = ox + (faceX + 7) * u
            ctx.globalCompositeOperation = "destination-out"
            if (isClaude) {
                // asterisk eyes (Claude starburst)
                ctx.lineWidth = 2 * u
                ctx.lineCap = "round"
                var len = 3 * u
                var centers = [cxL, cxR]
                for (var i = 0; i < centers.length; i++) {
                    var cx = centers[i]
                    for (var k = 0; k < 3; k++) {
                        var ang = (Math.PI / 3) * k + Math.PI / 6
                        ctx.beginPath()
                        ctx.moveTo(cx - Math.cos(ang) * len, cy - Math.sin(ang) * len)
                        ctx.lineTo(cx + Math.cos(ang) * len, cy + Math.sin(ang) * len)
                        ctx.stroke()
                    }
                }
            } else {
                // square eyes (Codex)
                var e = 5 * u
                ctx.fillRect(cxL - e / 2, cy - e / 2, e, e)
                ctx.fillRect(cxR - e / 2, cy - e / 2, e, e)
            }
            ctx.globalCompositeOperation = "source-over"
        }
    }
}
