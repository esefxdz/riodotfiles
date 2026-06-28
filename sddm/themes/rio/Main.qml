// ─────────────────────────────────────────────────────────────────────────────
//  My rio sddm theme
//  Black, red, dystopian themed
//  vers. 1.0.0
// ─────────────────────────────────────────────────────────────────────────────

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#000000"

    // ── Data models provided by SDDM ─────────────────────────────────────────
    property var config
    TextConstants { id: textConstants }

    // ── Background ───────────────────────────────────────────────────────────
    Image {
        id: bg
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true

        // Dim overlay over background image
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: parseFloat(config.backgroundDim) || 0.6
        }
    }

    // ── Scanline overlay (subtle CRT-like texture for dystopian feel) ─────────
    Rectangle {
        anchors.fill: parent
        opacity: 0.04
        color: "transparent"

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#ff2a2a"
                ctx.lineWidth = 1
                for (var y = 0; y < height; y += 4) {
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }
            }
        }
    }

    // ── Top-left: system clock ────────────────────────────────────────────────
    Column {
        anchors {
            top: parent.top
            left: parent.left
            margins: 60
        }
        spacing: 6

        Text {
            id: clockLabel
            color: "#ff2a2a"
            font.family: config.font
            font.pixelSize: 72
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "HH:mm")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockLabel.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Text {
            color: "#661111"
            font.family: config.font
            font.pixelSize: 16
            text: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy").toUpperCase()
            letterSpacing: 3
        }
    }

    // ── Bottom-left: flavor text ──────────────────────────────────────────────
    Column {
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 60
        }
        spacing: 4

        Text {
            color: "#3a0000"
            font.family: config.font
            font.pixelSize: 11
            text: "> ctOS_SHELL_ACCESS: LOCKED"
            letterSpacing: 2
        }

        Text {
            color: "#3a0000"
            font.family: config.font
            font.pixelSize: 11
            text: "> IDENTIFY YOURSELF, " + userModel.lastUser.toUpperCase()
            letterSpacing: 2
        }
    }

    // ── Centre: login box ─────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 0

        // ── Top border ──────────────────────────────────────────────────────
        Rectangle {
            width: 360
            height: 1
            color: "#ff2a2a"
            opacity: 0.6
        }

        // ── Inner panel ─────────────────────────────────────────────────────
        Rectangle {
            width: 360
            height: loginColumn.implicitHeight + 60
            color: "#05000000"        // near-transparent black panel
            border.color: "#ff2a2a"
            border.width: 1

            Column {
                id: loginColumn
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 30
                }
                width: 300
                spacing: 14

                // ── Username header ──────────────────────────────────────────
                Text {
                    width: parent.width
                    color: "#ff2a2a"
                    font.family: config.font
                    font.pixelSize: 11
                    text: "[ CREDENTIALS REQUIRED ]"
                    letterSpacing: 3
                    horizontalAlignment: Text.AlignHCenter
                }

                // ── Username field ───────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: 38
                    color: "transparent"
                    border.color: "#ff2a2a"
                    border.width: 1
                    opacity: usernameField.activeFocus ? 1.0 : 0.5

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    TextInput {
                        id: usernameField
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        font.family: config.font
                        font.pixelSize: 14
                        text: userModel.lastUser
                        selectByMouse: true

                        // placeholder
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            color: "#661111"
                            font: parent.font
                            text: "username"
                            visible: !usernameField.text && !usernameField.activeFocus
                        }

                        KeyNavigation.tab: passwordField
                        Keys.onReturnPressed: passwordField.forceActiveFocus()
                    }
                }

                // ── Password field ───────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: 38
                    color: "transparent"
                    border.color: "#ff2a2a"
                    border.width: 1
                    opacity: passwordField.activeFocus ? 1.0 : 0.5

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    TextInput {
                        id: passwordField
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        font.family: config.font
                        font.pixelSize: 14
                        echoMode: TextInput.Password
                        focus: true

                        // placeholder
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            color: "#661111"
                            font: parent.font
                            text: "passphrase"
                            visible: !passwordField.text && !passwordField.activeFocus
                        }

                        KeyNavigation.tab: loginButton
                        Keys.onReturnPressed: loginButton.clicked()
                    }
                }

                // ── Error message ────────────────────────────────────────────
                Text {
                    id: errorMessage
                    width: parent.width
                    color: "#ff2a2a"
                    font.family: config.font
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    visible: false
                    text: "> ACCESS DENIED. RETRY."
                    letterSpacing: 2
                }

                // ── Login button ─────────────────────────────────────────────
                Rectangle {
                    id: loginButton
                    width: parent.width
                    height: 38
                    color: loginMouseArea.containsPress ? "#3a0000"
                         : loginMouseArea.containsMouse ? "#1a0000"
                         : "transparent"
                    border.color: "#ff2a2a"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    function clicked() {
                        errorMessage.visible = false
                        sddm.login(usernameField.text, passwordField.text, sessionIndex)
                    }

                    Text {
                        anchors.centerIn: parent
                        color: "#ff2a2a"
                        font.family: config.font
                        font.pixelSize: 12
                        text: "[ AUTHENTICATE ]"
                        letterSpacing: 3
                    }

                    MouseArea {
                        id: loginMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: loginButton.clicked()
                    }
                }
            }
        }

        // ── Bottom border ────────────────────────────────────────────────────
        Rectangle {
            width: 360
            height: 1
            color: "#ff2a2a"
            opacity: 0.6
        }
    }

    // ── Session selector (hidden, bottom right) ───────────────────────────────
    property int sessionIndex: sessionModel.lastIndex

    ComboBox {
        id: sessionCombo
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 30
        }
        width: 180
        height: 30
        model: sessionModel
        index: sessionModel.lastIndex

        onValueChanged: sessionIndex = currentIndex

        background: Rectangle {
            color: "transparent"
            border.color: "#3a0000"
            border.width: 1
        }

        contentItem: Text {
            leftPadding: 8
            text: sessionCombo.displayText
            color: "#661111"
            font.family: config.font
            font.pixelSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        popup.background: Rectangle { color: "#0a0000"; border.color: "#3a0000" }
    }

    // ── SDDM signal handlers ──────────────────────────────────────────────────
    Connections {
        target: sddm

        function onLoginFailed() {
            passwordField.text = ""
            passwordField.forceActiveFocus()
            errorMessage.visible = true
        }
    }

    // ── Initial focus ─────────────────────────────────────────────────────────
    Component.onCompleted: {
        if (usernameField.text === "")
            usernameField.forceActiveFocus()
        else
            passwordField.forceActiveFocus()
    }
}
