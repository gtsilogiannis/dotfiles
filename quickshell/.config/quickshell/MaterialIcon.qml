// One Material Symbols glyph, selected by its name ("wifi", "volume_up", ...).
import QtQuick

Text {
    property string icon
    property bool filled: false

    text: icon
    color: Theme.surfaceText
    font.family: Theme.iconFamily
    font.pixelSize: Theme.iconSize
    // FILL 0 = outlined, 1 = solid; opsz matches the pixel size for crisp strokes.
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "opsz": 20 })
    verticalAlignment: Text.AlignVCenter
}
