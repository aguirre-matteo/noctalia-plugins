import QtQuick
import Quickshell.Io
import qs.Modules.Panels.Settings
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  property string mpvSocket: pluginApi?.pluginSettings?.mpvSocket ||
  pluginApi?.manifest?.metadata?.defaultSettings?.mpvSocket ||
  "/tmp/mpv-socket"

  property string cacheFile: ""
  property string currentWallpaper: ""
  property string viewMode: "grid"
  property bool audioEnabled: true
  property bool cacheLoaded: false

  // Process for mpvpaper
  Process {
    id: mpvPaper
  }

  Component.onCompleted: {
    loadCache();
  }

  Timer {
    id: initDelay
    interval: 500
    repeat: false
    onTriggered: {
      setAudio(audioEnabled);
      setWallpaper(currentWallpaper);
    }
  }

  function startMpvpaper() {
    mpvPaper.running = false;
    mpvPaper.command = [
      "sh", "-c", 
      `mpvpaper -o "--loop input-ipc-server=${mpvSocket}" ALL ""`
    ];
    mpvPaper.running = true;
    initDelay.restart();
  }

  function restartMpvpaper() {
    if (mpvPaper.running) {
      mpvPaper.signal(9);
    }
    ipcProcess.command = [ "sh", "-c", "pkill -9 mpvpaper; sleep 0.2" ];
    ipcProcess.running = true;
    restartDelay.restart();
  }

  Timer {
    id: restartDelay
    interval: 300
    repeat: false
    onTriggered: startMpvpaper()
  }

  FileView {
    id: cacheView
    printErrors: true
    watchChanges: false
    adapter: JsonAdapter {
      id: cacheAdapter
      property string wallpaper: ""
      property string viewMode: "grid"
      property bool audioEnabled: true
    }

    onLoaded: {
      if (cacheAdapter.wallpaper !== undefined && cacheAdapter.wallpaper !== "") {
        root.currentWallpaper = cacheAdapter.wallpaper;
      }
      if (cacheAdapter.viewMode !== undefined) {
        root.viewMode = cacheAdapter.viewMode;
      }
      if (cacheAdapter.audioEnabled !== undefined) {
        root.audioEnabled = cacheAdapter.audioEnabled;
      }
      root.cacheLoaded = true;
      startMpvpaper();
    }

    onLoadFailed: error => {
      root.cacheLoaded = true;
      startMpvpaper();
    }
  }

  function loadCache() {
    if (typeof Settings !== 'undefined' && Settings.cacheDir) {
      cacheFile = Settings.cacheDir + "mpvpaper/config.json";
      cacheView.path = cacheFile;
    } else {
      cacheLoaded = true;
      startMpvpaper();
    }
  }

  Process {
    id: cacheWriteProcess
  }

  function saveToCache() {
    const cacheData = {
      wallpaper: root.currentWallpaper,
      viewMode: root.viewMode,
      audioEnabled: root.audioEnabled
    };
    
    const jsonString = JSON.stringify(cacheData, null, 2);
    
    cacheWriteProcess.command = [
      "sh", "-c",
      `mkdir -p "$(dirname "${cacheFile}")" && echo '${jsonString}' > "${cacheFile}"`
    ];
    cacheWriteProcess.running = true;
  }

  function cacheViewMode(viewMode) {
    root.viewMode = viewMode;
    saveToCache();
  }

  Process {
    id: thumbnailProcess
  }

  function getVideoThumbnail(videoPath) {
    if (!videoPath) return "";
    const videoExtensions = ['mp4', 'mkv', 'mov', 'avi', 'webm'];
    const ext = videoPath.split('.').pop().toLowerCase();
    
    if (videoExtensions.indexOf(ext) === -1) {
        return videoPath;
    }

    if (!Settings.cacheDir) return "";
    const thumbDir = Settings.cacheDir + "mpvpaper/thumbnails/";
    const fileName = videoPath.split('/').pop();
    const thumbPath = thumbDir + fileName + ".jpg";

    thumbnailProcess.command = [
        "sh", "-c",
        `mkdir -p "${thumbDir}" && [ ! -f "${thumbPath}" ] && ffmpegthumbnailer -s 512 -i "${videoPath}" -o "${thumbPath}" || true`
    ];
    thumbnailProcess.running = true;
    return "file://" + thumbPath;
  }

  // Process for mpvpaper's IPC
  Process {
    id: ipcProcess
  }

  function setAudio(audio) {
    if (audio) {
      ipcProcess.command = [
        "sh", "-c", 
        `echo '{ "command": ["set_property", "mute", false] }' | socat - "${root.mpvSocket}"`
      ];
      ipcProcess.running = true;
    } else {
      ipcProcess.command = [
        "sh", "-c", 
        `echo '{ "command": ["set_property", "mute", true] }' | socat - "${root.mpvSocket}"`
      ];
      ipcProcess.running = true;
    }
    root.audioEnabled = audio;
    saveToCache();
  }

  function setWallpaper(filePath) {
    if (!mpvSocket) return;
    ipcProcess.command = [
      "sh", "-c", 
      `echo 'loadfile "${filePath}"' | socat - "${root.mpvSocket}"`
    ];
    ipcProcess.running = true;
    root.currentWallpaper = filePath;
    saveToCache();
  }
}
