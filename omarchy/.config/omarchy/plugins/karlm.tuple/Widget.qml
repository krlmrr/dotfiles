import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "karlm.tuple"
  ipcTarget: "karlm.tuple"

  readonly property string phoneIcon: String.fromCodePoint(0xF03F2)
  readonly property string mutedIcon: String.fromCodePoint(0xF036D)
  readonly property string sharingIcon: String.fromCodePoint(0xF1483)

  property bool daemonRunning: false
  property bool inCall: false
  property bool muted: false
  property bool sharing: false
  property string callUrl: ""
  property string notice: ""
  property var contacts: []
  property bool cursorActive: false
  property int cursorIndex: 0

  readonly property string barIcon: !inCall ? phoneIcon : (sharing ? sharingIcon : (muted ? mutedIcon : phoneIcon))
  readonly property string statusText: {
    if (!daemonRunning) return "Offline"
    if (!inCall) return "Available"
    var parts = ["In a call"]
    if (muted) parts.push("muted")
    if (sharing) parts.push("sharing")
    return parts.join(" · ")
  }

  function tuple(args) {
    Quickshell.execDetached(["tuple"].concat(args))
    refreshSoon.restart()
  }

  function say(text) {
    notice = text
    noticeTimer.restart()
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
    if (root.opened && root.daemonRunning && !contactsProc.running) contactsProc.running = true
  }

  function parseContacts(text) {
    var list = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*(\d+)\s+(.+?)\s+<[^>]*>\s+\[([^\]]+)\](\s+\(favorite\))?/)
      if (!m) continue
      list.push({ id: m[1], name: m[2], status: m[3], favorite: !!m[4] })
    }
    list.sort(function(a, b) {
      if (a.favorite !== b.favorite) return a.favorite ? -1 : 1
      var rank = { "available": 0, "in call": 1 }
      var ra = rank[a.status] !== undefined ? rank[a.status] : 2
      var rb = rank[b.status] !== undefined ? rank[b.status] : 2
      if (ra !== rb) return ra - rb
      return a.name.localeCompare(b.name)
    })
    contacts = list
    cursorIndex = Math.min(cursorIndex, Math.max(0, list.length - 1))
  }

  function startDaemon() {
    Quickshell.execDetached(["tuple", "on"])
    say("Starting Tuple…")
    refreshSoon.restart()
  }

  function newCall() {
    if (!newProc.running) newProc.running = true
    say("Starting a call…")
  }

  function joinFromClipboard() {
    Quickshell.execDetached(["bash", "-c", "url=$(wl-paste --no-newline 2>/dev/null); [[ $url == http* ]] && tuple join \"$url\""])
    inCall = true
    say("Joining the link on your clipboard…")
    refreshSoon.restart()
  }

  function callContact(contact) {
    tuple(["call", contact.id])
    inCall = true
    say("Calling " + contact.name + "…")
  }

  function toggleMute() {
    if (!inCall) return
    tuple([muted ? "unmute" : "mute"])
    muted = !muted
  }

  function toggleShare() {
    if (!inCall) return
    tuple([sharing ? "unshare" : "share"])
    sharing = !sharing
  }

  function endCall() {
    tuple(["end"])
    inCall = false
    muted = false
    sharing = false
    callUrl = ""
    say("Call ended")
  }

  function copyCallUrl() {
    if (!callUrl) return
    Quickshell.execDetached(["wl-copy", callUrl])
    say("Call link copied")
  }

  onOpenedChanged: {
    if (!opened) return
    cursorActive = false
    cursorIndex = 0
    refresh()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: statusProc
    command: ["pgrep", "-x", "tuple"]
    onExited: function(exitCode) {
      root.daemonRunning = exitCode === 0
      if (!root.daemonRunning) {
        root.inCall = false
        root.muted = false
        root.sharing = false
      }
    }
  }

  Process {
    id: contactsProc
    command: ["tuple", "ls"]
    stdout: StdioCollector {
      onStreamFinished: root.parseContacts(text)
    }
  }

  Process {
    id: newProc
    command: ["tuple", "new"]
    stdout: StdioCollector {
      onStreamFinished: {
        var m = String(text || "").match(/https?:\/\/\S+/)
        if (!m) {
          root.say("Couldn't start a call")
          return
        }
        root.callUrl = m[0]
        root.inCall = true
        Quickshell.execDetached(["wl-copy", root.callUrl])
        root.say("Call started, link copied")
      }
    }
  }

  Timer {
    interval: root.opened ? 3000 : 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshSoon
    interval: 800
    onTriggered: root.refresh()
  }

  Timer {
    id: noticeTimer
    interval: 4000
    onTriggered: root.notice = ""
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barIcon
    active: root.inCall
    tooltipText: "Tuple: " + root.statusText
    onPressed: function(b) {
      if (b === Qt.RightButton && root.inCall) root.toggleMute()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (root.contacts.length === 0) return
        if (!root.cursorActive) { root.cursorActive = true; return }
        var step = dy !== 0 ? dy : dx
        root.cursorIndex = Math.max(0, Math.min(root.contacts.length - 1, root.cursorIndex + step))
      }
      onActivateRequested: {
        if (root.cursorActive && root.cursorIndex < root.contacts.length) root.callContact(root.contacts[root.cursorIndex])
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        var k = String(t).toLowerCase()
        if (!root.daemonRunning) {
          if (k === "o") root.startDaemon()
          return
        }
        if (k === "n") root.newCall()
        if (k === "j") root.joinFromClipboard()
        if (k === "m") root.toggleMute()
        if (k === "s") root.toggleShare()
        if (k === "e") root.endCall()
        if (k === "c") root.copyCallUrl()
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.barIcon
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            opacity: root.daemonRunning ? 1.0 : 0.5
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Tuple"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.notice || root.statusText
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              font.capitalization: Font.AllUppercase
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        Button {
          visible: !root.daemonRunning
          text: "Start Tuple"
          fontSize: Style.font.bodySmall
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          bordered: true
          onClicked: root.startDaemon()
        }

        Flow {
          visible: root.daemonRunning
          width: parent.width
          spacing: Style.space(6)

          Button {
            visible: !root.inCall
            text: "New call"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: root.newCall()
          }

          Button {
            visible: !root.inCall
            text: "Join link"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: root.joinFromClipboard()
          }

          Button {
            visible: root.inCall
            text: root.muted ? "Unmute" : "Mute"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: root.toggleMute()
          }

          Button {
            visible: root.inCall
            text: root.sharing ? "Stop sharing" : "Share screen"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: root.toggleShare()
          }

          Button {
            visible: root.inCall && root.callUrl !== ""
            text: "Copy link"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: root.copyCallUrl()
          }

          Button {
            visible: root.inCall
            text: "End call"
            fontSize: Style.font.bodySmall
            foreground: root.bar.urgent
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: root.endCall()
          }
        }

        PanelSeparator {
          visible: root.daemonRunning
          foreground: root.bar.foreground
        }

        Text {
          visible: root.daemonRunning && root.contacts.length === 0
          width: parent.width
          textFormat: Text.PlainText
          text: "No contacts yet."
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Column {
          id: contactList
          visible: root.daemonRunning && root.contacts.length > 0
          width: parent.width
          spacing: Style.space(2)

          Repeater {
            model: root.contacts

            Rectangle {
              id: row
              required property var modelData
              required property int index
              readonly property bool current: root.cursorActive && root.cursorIndex === index
              readonly property bool reachable: modelData.status === "available"

              width: contactList.width
              implicitHeight: labels.implicitHeight + Style.space(10)
              radius: Style.cornerRadius > 0 ? Style.space(6) : 0
              color: current ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"

              Rectangle {
                id: presenceDot
                width: Style.space(7)
                height: width
                radius: width / 2
                anchors.left: parent.left
                anchors.leftMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                color: row.reachable ? Color.accent : (row.modelData.status === "in call" ? root.bar.urgent : "transparent")
                border.width: row.reachable || row.modelData.status === "in call" ? 0 : 1
                border.color: Qt.darker(root.bar.foreground, 1.6)
              }

              Column {
                id: labels
                anchors.left: presenceDot.right
                anchors.leftMargin: Style.space(8)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(1)

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: (row.modelData.favorite ? "★ " : "") + row.modelData.name
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  opacity: row.reachable ? 1.0 : 0.6
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: row.modelData.status
                  color: Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.reachable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: { root.cursorActive = true; root.cursorIndex = row.index }
                onClicked: if (row.reachable) root.callContact(row.modelData)
              }
            }
          }
        }

        Text {
          visible: root.daemonRunning
          width: parent.width
          textFormat: Text.PlainText
          text: root.inCall ? "m mute · s share · c copy link · e end" : "n new call · j join link · ↵ call contact"
          color: Qt.darker(root.bar.foreground, 1.6)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }
}
