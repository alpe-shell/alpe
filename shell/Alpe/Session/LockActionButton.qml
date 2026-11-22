import QtQuick
import qs.Alpe.Widgets
import qs.Alpe.Common

AlpeActionButton {
    radius: Style.buttonRadius(width, height, buttonSize, pressed, circular)
    shapeDuration: LockMetrics.effectsDuration
    shapeCurve: Style.expressiveCurves.expressiveEffects
    stateDuration: LockMetrics.effectsDuration
    stateCurve: Style.expressiveCurves.expressiveEffects
}
