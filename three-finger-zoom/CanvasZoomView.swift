import AppKit

/// Вариант B: жест «три пальца вверх/вниз» внутри собственного AppKit-приложения.
///
/// View получает сырые касания трекпада через NSTouch (allowedTouchTypes = .indirect),
/// считает среднюю вертикальную позицию трёх пальцев и превращает её дельту в zoom.
///
/// Требование: системные жесты Mission Control / App Exposé должны быть
/// переведены на 4 пальца или выключены (System Settings → Trackpad → More
/// Gestures), иначе жест перехватит система — приложение не может «отобрать»
/// его у WindowServer.
final class CanvasZoomView: NSView {

    /// Текущий масштаб «канваса». Наблюдайте/привязывайте к своему рендеру.
    var zoomLevel: CGFloat = 1.0 {
        didSet { needsDisplay = true }
    }

    /// Чувствительность: во сколько раз меняется zoom при проводке пальцев
    /// через всю высоту трекпада (normalizedPosition.y меняется на 1.0).
    var sensitivity: CGFloat = 4.0

    private var trackingThreeFingers = false
    private var lastAverageY: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        allowedTouchTypes = [.indirect] // «непрямые» касания = трекпад
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        allowedTouchTypes = [.indirect]
    }

    override func touchesBegan(with event: NSEvent) {
        resyncGesture(with: event)
    }

    override func touchesMoved(with event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        guard touches.count == 3 else {
            trackingThreeFingers = false
            return
        }
        let averageY = touches.map(\.normalizedPosition.y).reduce(0, +) / 3
        if trackingThreeFingers {
            let dy = averageY - lastAverageY
            zoomLevel = min(max(zoomLevel * (1 + dy * sensitivity), 0.1), 10)
        }
        trackingThreeFingers = true
        lastAverageY = averageY
    }

    override func touchesEnded(with event: NSEvent) {
        resyncGesture(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        trackingThreeFingers = false
    }

    /// Пересчитывает опорную точку, когда число пальцев изменилось
    /// (например, добавили третий палец уже во время движения).
    private func resyncGesture(with event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        guard touches.count == 3 else {
            trackingThreeFingers = false
            return
        }
        lastAverageY = touches.map(\.normalizedPosition.y).reduce(0, +) / 3
        trackingThreeFingers = true
    }
}
