import QtQuick
Rectangle {
    color: "#141414"
    Rectangle { x: 620; y: 400; width: 1100; height: 560; radius: 280; color: "#1e1e1e" }
    Rectangle { x: 1000; y: 330; width: 500; height: 500; radius: 250; color: "#262626" }
    Rectangle { x: 1400; y: 420; width: 560; height: 560; radius: 280; color: "#333333" }
    Rectangle { x: 1800; y: 380; width: 640; height: 640; radius: 320; color: "#6a6a6a" }
    Rectangle { x: 1750; y: 700; width: 380; height: 440; color: "#4a4a4a" }
    Rectangle { x: 2420; y: 310; width: 380; height: 760; color: "#3a3a3a" }
    Repeater { model: [1200, 1780, 2780]; Item { required property int modelData
        Rectangle { x: modelData - 130; y: 699; width: 260; height: 1; color: "#555" }
        Rectangle { x: modelData; y: 560; width: 1; height: 260; color: "#555" } } }
}
