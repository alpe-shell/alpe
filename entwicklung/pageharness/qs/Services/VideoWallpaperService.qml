pragma Singleton
import QtQuick
QtObject { function isVideo(p) { return /\.(mp4|webm|mkv|mov)$/i.test(String(p)) } function imageFor(p) { return isVideo(p) ? "" : p } }
