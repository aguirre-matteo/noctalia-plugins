import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property string editSocket: pluginApi?.pluginSettings?.mpvSocket ||
  pluginApi?.manifest?.metadata?.defaultSettings?.mpvSocket ||
  "/tmp/mpv-socket"

  property string editFolder: pluginApi?.pluginSettings?.wallpapersFolder ||
  pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ||
  ""

  spacing: Style.marginM

  NTextInputButton {
    label: "Wallpapers folder"
    description: "Path to your main wallpapers folder"
    buttonIcon: "folder-open"
    Layout.fillWidth: true
    text: root.editFolder
    onInputEditingFinished: root.editFolder = text
    onButtonClicked: wallpaperFolderPicker.open()
  }

  NFilePicker {
    id: wallpaperFolderPicker
    selectionMode: "folders"
    title: "Select wallpaper folder"
    initialPath: Settings.data.wallpaper.directory || Quickshell.env("HOME") + "/Pictures"
    onAccepted: paths => {
      if (paths.length > 0) {
        root.editFolder = paths[0];
      }
    }
  }
  
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Mpv Socket"
    description: "Path to the Mpv Socker"
    placeholderText: "/tmp/mpv-socket"
    text: root.editSocket
    onTextChanged: root.editSocket = text
  }

  function saveSettings() {
    pluginApi.pluginSettings.mpvSocket = root.editSocket
    pluginApi.pluginSettings.wallpapersFolder = root.editFolder
    pluginApi.saveSettings()
  }
}
