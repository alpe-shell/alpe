import QtQuick
Rectangle {
    gradient: Gradient { GradientStop { position: 0; color: "#7aa6d6" } GradientStop { position: 0.55; color: "#3b4e66" } GradientStop { position: 1; color: "#1a1f29" } }
    Repeater { model: 7; Rectangle { x: index * 380 - 120; y: 700 - (index % 3) * 120; width: 600; height: 600; rotation: 45; color: index % 2 ? "#2c3442" : "#4a5568" } }
}
