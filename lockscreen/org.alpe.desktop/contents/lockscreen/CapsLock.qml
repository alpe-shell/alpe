// Feststelltaste. Eigene Datei, damit ein fehlendes KDE-Modul nur diesen Hinweis kostet,
// nicht den ganzen Sperrbildschirm.
import QtQuick
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

KeyboardIndicator.KeyState {
    key: Qt.Key_CapsLock
}
