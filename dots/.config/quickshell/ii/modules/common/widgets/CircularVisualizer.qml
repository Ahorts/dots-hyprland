import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Effects


// Circular Visualizer
Canvas { 
    id: root
    property list<var> points
    property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property color color: Appearance.m3colors.m3primary
    property real innerRadius: 80
    property real outerRadius: 120

    onPointsChanged: root.requestPaint()
    onLiveChanged: root.requestPaint()

    width: (outerRadius + 10) * 2
    height: (outerRadius + 10) * 2

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var n = points.length;
        if (n < 2) return;

        var smoothWindow = root.smoothing;
        var smoothPoints = [];
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += points[idx];
                count++;
            }
            smoothPoints.push(sum / count);
        }
        if (!root.live) smoothPoints.fill(0);

        var cx = width / 2, cy = height / 2;
        var maxVal = root.maxVisualizerValue || 1;

        ctx.beginPath();
        for (var i = 0; i < n; ++i) {
            var angle = (2 * Math.PI * i) / n;
            var amp = smoothPoints[i] / maxVal;
            var r = root.innerRadius + (root.outerRadius - root.innerRadius) * amp;
            var x = cx + r * Math.cos(angle - Math.PI/2);
            var y = cy + r * Math.sin(angle - Math.PI/2);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.closePath();

        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.15);
        ctx.fill();
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        source: root
        saturation: 0.2
        blurEnabled: false
        blurMax: 7
        blur: 1
    }
}
