import QtQuick 2.15
import SddmComponents 2.0
import "."

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#050505"

    property color fg: "#d9d9d9"
    property color muted: "#777777"
    property color dim: "#4f4f4f"
    property color line: "#282828"
    property color inputBg: "#0f0f0f"
    property color inputBorder: "#383838"
    property color focusBorder: "#9a9a9a"
    property color warn: "#b85c5c"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    function cleanHostname(value) {
        var h = ""
        try {
            h = String(value)
        } catch (e) {
            h = ""
        }
        h = h.replace(/^\s+|\s+$/g, "")
        if (h.length === 0 || h === "undefined" || h === "null") {
            return ""
        }
        return h
    }

    function readHostnameFile() {
        var h = ""
        try {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///etc/hostname", false)
            xhr.send()
            if (xhr.status === 0 || xhr.status === 200) {
                h = cleanHostname(xhr.responseText.split("\n")[0])
            }
        } catch (e) {
            h = ""
        }
        return h
    }

    property string etcHostname: readHostnameFile()
    property string sddmHostname: cleanHostname(sddm.hostName)
    property string installedHostname: cleanHostname(HostInfo.hostname)

    // Cross-distro hostname handling:
    // 1. /etc/hostname works reliably on Debian, Void, Arch and CachyOS.
    // 2. HostInfo.hostname is written by install.sh as an offline fallback.
    // 3. sddm.hostName is kept as a final runtime fallback, but some SDDM builds return localhost.
    property string systemHostname: {
        if (etcHostname.length > 0) return etcHostname
        if (installedHostname.length > 0) return installedHostname
        if (sddmHostname.length > 0 && sddmHostname !== "localhost") return sddmHostname
        if (sddmHostname.length > 0) return sddmHostname
        return "unknown"
    }

    function toRunes(input) {
        var out = ""
        var value = String(input).toLowerCase()
        for (var i = 0; i < value.length; i++) {
            var ch = value.charAt(i)
            switch (ch) {
            case "a": out += "ᚨ"; break
            case "b": out += "ᛒ"; break
            case "c": out += "ᚲ"; break
            case "d": out += "ᛞ"; break
            case "e": out += "ᛖ"; break
            case "f": out += "ᚠ"; break
            case "g": out += "ᚷ"; break
            case "h": out += "ᚺ"; break
            case "i": out += "ᛁ"; break
            case "j": out += "ᛃ"; break
            case "k": out += "ᚲ"; break
            case "l": out += "ᛚ"; break
            case "m": out += "ᛗ"; break
            case "n": out += "ᚾ"; break
            case "o": out += "ᛟ"; break
            case "p": out += "ᛈ"; break
            case "q": out += "ᚲ"; break
            case "r": out += "ᚱ"; break
            case "s": out += "ᛊ"; break
            case "t": out += "ᛏ"; break
            case "u": out += "ᚢ"; break
            case "v": out += "ᚹ"; break
            case "w": out += "ᚹ"; break
            case "x": out += "ᚲᛊ"; break
            case "y": out += "ᛃ"; break
            case "z": out += "ᛉ"; break
            case "-":
            case "_":
            case ".":
                out += " "
                break
            default:
                out += ch
            }
        }
        return out
    }

    function clampSession() {
        if (sessionModel.count <= 0) {
            sessionIndex = 0
            return
        }
        if (sessionIndex < 0) sessionIndex = sessionModel.count - 1
        if (sessionIndex >= sessionModel.count) sessionIndex = 0
    }

    function prevSession() {
        sessionIndex--
        clampSession()
    }

    function nextSession() {
        sessionIndex++
        clampSession()
    }

    function setInitialFocus() {
        userInput.forceActiveFocus()
        if (userInput.text.length > 0) {
            userInput.selectAll()
        }
    }

    function doLogin() {
        errorText.text = ""

        if (userInput.text.length === 0) {
            errorText.text = "enter username"
            userInput.forceActiveFocus()
            return
        }

        if (passInput.text.length === 0) {
            passInput.forceActiveFocus()
            return
        }

        sddm.login(userInput.text, passInput.text, sessionIndex)
    }

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: root.setInitialFocus()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "login failed"
            passInput.text = ""
            passInput.forceActiveFocus()
        }
        function onLoginSucceeded() {
            errorText.text = ""
        }
    }

    Keys.onEscapePressed: {
        passInput.text = ""
        errorText.text = ""
        setInitialFocus()
    }

    Keys.onLeftPressed: root.prevSession()
    Keys.onRightPressed: root.nextSession()

    Canvas {
        anchors.fill: parent
        opacity: 0.30
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var g = ctx.createRadialGradient(width/2, height*0.46, 50, width/2, height*0.46, Math.max(width, height)*0.62)
            g.addColorStop(0, "#151515")
            g.addColorStop(0.52, "#080808")
            g.addColorStop(1, "#000000")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)

            ctx.globalAlpha = 0.11
            ctx.strokeStyle = "#202020"
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.arc(width/2, height*0.47, Math.min(width, height)*0.33, 0, 2*Math.PI)
            ctx.stroke()
        }
    }

    Column {
        id: header
        anchors {
            top: parent.top
            topMargin: Math.max(62, parent.height * 0.085)
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 12

        // Hostname as Elder Futhark. The font is intentionally normal sans,
        // because most systems already render Unicode runes cleanly.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.toRunes(root.systemHostname)
            color: root.fg
            opacity: 0.96
            font.pixelSize: Math.max(42, root.height * 0.064)
            font.letterSpacing: 9
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.systemHostname.toUpperCase()
            color: root.muted
            opacity: 0.88
            font.pixelSize: 15
            font.letterSpacing: 7
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 275
            height: 1
            color: root.line
            opacity: 0.9
        }
    }

    Column {
        id: panel
        width: Math.min(340, root.width - 80)
        spacing: 11
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Math.max(310, parent.height * 0.385)
        }

        Rectangle {
            width: parent.width
            height: 42
            color: root.inputBg
            border.color: userInput.activeFocus ? root.focusBorder : root.inputBorder
            border.width: 1

            TextInput {
                id: userInput
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 13
                verticalAlignment: TextInput.AlignVCenter
                color: root.fg
                selectionColor: "#404040"
                selectedTextColor: "#ffffff"
                font.pixelSize: 15
                text: UserDefaults.username
                clip: true
                activeFocusOnTab: true
                KeyNavigation.tab: passInput
                KeyNavigation.backtab: passInput

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "user"
                    color: root.muted
                    font.pixelSize: 15
                    visible: userInput.text.length === 0 && !userInput.activeFocus
                }

                Keys.onReturnPressed: {
                    passInput.forceActiveFocus()
                    passInput.selectAll()
                }
                Keys.onEnterPressed: {
                    passInput.forceActiveFocus()
                    passInput.selectAll()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 42
            color: root.inputBg
            border.color: passInput.activeFocus ? root.focusBorder : root.inputBorder
            border.width: 1

            TextInput {
                id: passInput
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 13
                verticalAlignment: TextInput.AlignVCenter
                color: root.fg
                selectionColor: "#404040"
                selectedTextColor: "#ffffff"
                font.pixelSize: 15
                echoMode: TextInput.Password
                passwordCharacter: "●"
                clip: true
                activeFocusOnTab: true
                KeyNavigation.tab: userInput
                KeyNavigation.backtab: userInput

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "password"
                    color: root.muted
                    font.pixelSize: 15
                    visible: passInput.text.length === 0 && !passInput.activeFocus
                }

                Keys.onReturnPressed: root.doLogin()
                Keys.onEnterPressed: root.doLogin()
            }
        }

        Rectangle {
            width: parent.width
            height: 38
            color: "#0b0b0b"
            border.color: root.inputBorder
            border.width: 1

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "‹"
                color: root.muted
                font.pixelSize: 24

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.prevSession()
                }
            }

            Item {
                anchors.centerIn: parent
                width: parent.width - 90
                height: parent.height

                Repeater {
                    model: sessionModel
                    delegate: Text {
                        anchors.centerIn: parent
                        visible: index === root.sessionIndex
                        text: {
                            if (typeof name !== "undefined" && name !== "") return String(name).toUpperCase()
                            if (typeof file !== "undefined" && file !== "") return String(file).replace(".desktop", "").toUpperCase()
                            return "SESSION"
                        }
                        color: root.fg
                        font.pixelSize: 13
                        font.letterSpacing: 3
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: sessionModel.count <= 0
                    text: "SESSION"
                    color: root.fg
                    font.pixelSize: 13
                    font.letterSpacing: 3
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                color: root.muted
                font.pixelSize: 24

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextSession()
                }
            }
        }

        Rectangle {
            width: 180
            height: 38
            anchors.horizontalCenter: parent.horizontalCenter
            color: loginArea.pressed ? "#2a2a2a" : "#151515"
            opacity: (userInput.text.length > 0 && passInput.text.length > 0) ? 1.0 : 0.72
            border.color: loginArea.containsMouse ? root.focusBorder : root.inputBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "ENTER"
                color: root.fg
                font.pixelSize: 12
                font.letterSpacing: 4
            }

            MouseArea {
                id: loginArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.doLogin()
            }
        }

        Text {
            id: errorText
            width: parent.width
            text: ""
            color: root.warn
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Column {
        anchors {
            bottom: parent.bottom
            bottomMargin: 26
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: root.dim
            font.pixelSize: 13
            font.letterSpacing: 4
            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm")
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28

            Text {
                text: "shutdown"
                color: root.muted
                opacity: 0.75
                font.pixelSize: 11
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.powerOff()
                }
            }

            Text {
                text: "reboot"
                color: root.muted
                opacity: 0.75
                font.pixelSize: 11
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.reboot()
                }
            }
        }
    }
}
