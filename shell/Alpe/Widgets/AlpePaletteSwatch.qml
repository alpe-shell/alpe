import QtQuick
import qs.Alpe.Common

AlpeColorSwatch {
    property color primaryColor: Style.primary

    swatchColor: primaryColor
    secondaryColor: primaryColor
    tertiaryColor: secondaryColor
    ringWidth: 0
}
