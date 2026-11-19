pragma Singleton
import QtQuick
QtObject { property int refreshes: 0; function forceRefresh() { refreshes++ } }
