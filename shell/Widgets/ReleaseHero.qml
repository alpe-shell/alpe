import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets

DHeroCard {
    // Kachel "Al" plus Rest des Namens ergibt den Schriftzug, die Marke daneben Version und Codename.
    brand: Brand.version
    accent: Brand.codename
    caption: Brand.name
    symbol: "Al"
    atomicNumber: 13
    atomicMass: "26.982"
}
