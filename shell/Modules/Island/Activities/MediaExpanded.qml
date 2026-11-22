pragma ComponentBehavior: Bound

import QtQuick
import qs.Alpe.Dash

DashTabFace {
    id: root

    activityId: "media"
    tabComponent: Component {
        MediaPlayerTab {
            live: root.live
        }
    }
}
