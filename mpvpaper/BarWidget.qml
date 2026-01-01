import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  implicitWidth: pill.width
  implicitHeight: pill.height

  BarPill {
    id: pill
    screen: root.screen
    density: Settings.data.bar.density
    oppositeDirection: BarService.getPillDirection(root)
    autoHide: false
    icon: "wallpaper"
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen)
      }
    }
  }
}
