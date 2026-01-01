import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Modules.MainScreen
import qs.Services.UI
import qs.Widgets
import Quickshell.Io
import Qt.labs.folderlistmodel

Item {
  id: root

  property var pluginApi: null
  property real contentPreferredWidth: 680 * Style.uiScaleRatio
  property real contentPreferredHeight: 540 * Style.uiScaleRatio

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  property string wallpapersFolder: pluginApi?.pluginSettings?.wallpapersFolder ||
  pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ||
  ""

  property var mainInstance: pluginApi?.mainInstance
  property bool cacheReady: mainInstance?.cacheLoaded ?? false

  property string currentWallpaper: cacheReady ? (mainInstance?.currentWallpaper ?? "") : ""
  property string viewMode: cacheReady ? (mainInstance?.viewMode ?? "grid") : "grid"
  property bool audioEnabled: cacheReady ? (mainInstance?.audioEnabled ?? true) : true

  anchors.fill: parent
  
  Process {
    id: ipcProcess
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: Color.transparent
    
    property string filterText: ""

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: headerLayout.implicitHeight + (Style.marginL * 2)
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        radius: Style.radiusM

        ColumnLayout {
          id: headerLayout
          anchors.margins: Style.marginL
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: Style.marginM

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NIcon {
              icon: "wallpaper"
              pointSize: Style.fontSizeXXL
              color: Color.mPrimary
            }

            NText {
              text: "Mpvpaper Wallpaper Selector"
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
              Layout.fillWidth: true
            }

            NIconButton {
              icon: "refresh"
              tooltipText: "Refresh Wallpaper List"
              baseSize: Style.baseWidgetSize * 0.8
              onClicked: {
                if (mainInstance) {
                  mainInstance.restartMpvpaper()
                }
              }
            }

            NIconButton {
              icon: "close"
              tooltipText: "Close"
              baseSize: Style.baseWidgetSize * 0.8
              onClicked: {
                pluginApi.closePanel(root.screen)
              }
            }
          }

          NDivider {
            Layout.fillWidth: true
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NTextInput {
              id: filterInput
              placeholderText: "Type to filter wallpapers..."
              Layout.fillWidth: true
              onTextChanged: root.updateFilter(text)
            }

            NComboBox {
              id: viewModeCB
              Layout.fillWidth: false
              currentKey: root.viewMode
              onSelected: (key) => {
                root.viewMode = key;
                mainInstance.cacheViewMode(root.viewMode);
              }
              model: [
                {
                  "key": "grid",
                  "name": "Grid"
                },
                {
                  "key": "list",
                  "name": "List"
                }
              ]
            }
          }

          NDivider {
            Layout.fillWidth: true
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NToggle {
              label: "Audio"
              checked: root.audioEnabled
              onToggled: (checked) => {
                if (mainInstance) {  
                  root.audioEnabled = checked;
                  mainInstance.setAudio(root.audioEnabled);
                }
              }
            }
          }
        }
      }
      
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        radius: Style.radiusM
        clip: true

        StackLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          currentIndex: {
            if (root.wallpapersFolder === "") return 0;
            return (root.viewMode === "grid") ? 1 : 2;
          }

          NText {
            anchors.centerIn: parent
            text: "Wallpaper list will appear here\nonce you configure the folder path"
            color: Color.mOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
          }

          GridView {
            id: gridView
            model: wallpaperModel
            cellWidth: width / 3
            cellHeight: cellWidth * 0.75
            delegate: wallpaperDelegate

            ScrollBar.vertical: ScrollBar {
              policy: ScrollBar.AsNeeded
            }
          }

          ListView {
            id: listView
            model: wallpaperModel
            spacing: Style.marginS
            delegate: wallpaperListDelegate
          }
        }
      }
    }
  }

  FolderListModel {
    id: wallpaperModel
    folder: "file://" + root.wallpapersFolder
    nameFilters: ["*.mp4", "*.mkv", "*.mov", "*.png", "*.jpg"]
    showDirs: false
  }

  function updateFilter(text) {
    if (text.length > 0) {
      wallpaperModel.nameFilters = [
          "*" + text + "*.mp4", "*" + text + "*.mkv", 
          "*" + text + "*.png", "*" + text + "*.jpg"
      ];
    } else {
      wallpaperModel.nameFilters = ["*.mp4", "*.mkv", "*.mov", "*.avi", "*.webm", "*.png", "*.jpg", "*.jpeg", "*.webp"];
    }
  }

  Component {
    id: wallpaperDelegate
    Item {
      width: gridView.cellWidth
      height: gridView.cellHeight
      
      Rectangle {
        id: delegateBackground
        anchors.fill: parent
        anchors.margins: 4
        color: Color.mSurface
        border.width: mouseHandler.containsMouse ? 2 : 1
        border.color: mouseHandler.containsMouse ? Color.mPrimary : Color.mOutline
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: delegateBackground.border.width
          source: mainInstance ? mainInstance.getVideoThumbnail(filePath) : filePath
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          autoTransform: true
          
          NIcon {
            visible: parent.status !== Image.Ready
            anchors.centerIn: parent
            icon: "movie" 
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXXL
          }
        }

        MouseArea {
          id: mouseHandler
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            if (mainInstance) {
              mainInstance.setWallpaper(filePath)
            }
          }
        }

        Behavior on border.color {
          ColorAnimation { duration: 150 }
        }
      }
    }
  }

  Component {
    id: wallpaperListDelegate
    NButton {
      width: listView.width
      text: fileName
      onClicked: {
        if (mainInstance) {
          mainInstance.setWallpaper(filePath)
        }
      }
    }
  }
}
