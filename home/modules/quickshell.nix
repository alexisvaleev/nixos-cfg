# Quickshell media player popup — toggled by clicking the waybar
# mpris module. Runs as a persistent `qs -c player` instance; the
# panel stays hidden until the IPC toggle fires.
{ pkgs, ... }:
{
  home.packages = [ pkgs.quickshell ];

  xdg.configFile."quickshell/player/shell.qml".text = ''
    import Quickshell
    import Quickshell.Io
    import Quickshell.Services.Mpris
    import QtQuick
    import QtQuick.Layouts

    ShellRoot {
        id: root

        // Prefer the player that is actually playing; fall back to the
        // first registered one.
        readonly property var players: Mpris.players.values

        function fmtTime(s) {
            s = Math.max(0, Math.floor(s));
            const m = Math.floor(s / 60);
            const sec = s % 60;
            return m + ":" + (sec < 10 ? "0" : "") + sec;
        }

        readonly property MprisPlayer player: {
            const list = players;
            if (!list.length) return null;
            for (const p of list)
                if (p.playbackState === MprisPlaybackState.Playing) return p;
            return list[0];
        }

        IpcHandler {
            target: "player"
            function toggle(): void { win.visible = !win.visible; }
        }

        PanelWindow {
            id: win
            visible: false
            aboveWindows: true
            exclusiveZone: 0
            anchors { top: true }
            margins { top: 40 }
            implicitWidth: 400
            implicitHeight: 140
            color: "transparent"

            // Keep the position ticking while the popup is open.
            Timer {
                interval: 500
                running: win.visible && root.player !== null
                         && root.player.playbackState === MprisPlaybackState.Playing
                repeat: true
                onTriggered: if (root.player) root.player.positionChanged()
            }

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "#e618181f"
                border.color: "#a78bfa"
                border.width: 1

                // Close button — the popup has no other way to dismiss
                // itself when the bar cell is hidden (no player).
                Text {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    text: "󰅖"
                    color: "#a0a0b0"
                    font.pixelSize: 14
                    z: 10
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.visible = false
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    // ── Cover art ────────────────────────────────
                    Rectangle {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 96
                        radius: 10
                        clip: true
                        color: "#2a2a35"

                        Image {
                            anchors.fill: parent
                            source: root.player && root.player.trackArtUrl
                                    ? root.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !(root.player && root.player.trackArtUrl)
                            text: "󰝚"
                            color: "#a0a0b0"
                            font.pixelSize: 32
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: root.player ? (root.player.trackTitle || "—") : "Нет плеера"
                            color: "#e6e6f0"
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.player ? (root.player.trackArtist || "") : ""
                            color: "#a0a0b0"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        // ── Progress bar + drag-to-seek ───────────────
                        // dragFrac >= 0 while dragging: the thumb follows
                        // the mouse live, and the actual seek is committed
                        // once on release (players dislike seek spam).
                        Item {
                            id: prog
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16
                            property real dragFrac: -1

                            readonly property real frac: {
                                const p = root.player;
                                if (!p || !(p.length > 0)) return 0;
                                return Math.max(0, Math.min(1, p.position / p.length));
                            }
                            readonly property real shownFrac:
                                dragFrac >= 0 ? dragFrac : frac

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: "#2a2a35"

                                Rectangle {
                                    height: parent.height
                                    radius: 3
                                    color: "#a78bfa"
                                    width: parent.width * prog.shownFrac
                                }

                                // Thumb — grows a bit while dragging.
                                Rectangle {
                                    width: prog.dragFrac >= 0 ? 14 : 10
                                    height: width
                                    radius: width / 2
                                    color: "#c4b5fd"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(parent.width - width,
                                        parent.width * prog.shownFrac - width / 2))
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                function fracAt(x: real): real {
                                    return Math.max(0, Math.min(1, x / width));
                                }
                                onPressed: (m) => prog.dragFrac = fracAt(m.x)
                                onPositionChanged: (m) => {
                                    if (pressed) prog.dragFrac = fracAt(m.x);
                                }
                                onReleased: {
                                    const p = root.player;
                                    if (p && p.canSeek && p.length > 0 && prog.dragFrac >= 0)
                                        p.setPosition(p.length * prog.dragFrac);
                                    prog.dragFrac = -1;
                                }
                                // If the pointer leaves while pressed, drop
                                // the drag without seeking.
                                onCanceled: prog.dragFrac = -1
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: {
                                    const p = root.player;
                                    if (!p) return "0:00";
                                    if (prog.dragFrac >= 0 && p.length > 0)
                                        return root.fmtTime(p.length * prog.dragFrac);
                                    return root.fmtTime(p.position);
                                }
                                color: "#a0a0b0"
                                font.pixelSize: 10
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.fmtTime(root.player ? root.player.length : 0)
                                color: "#a0a0b0"
                                font.pixelSize: 10
                            }
                        }

                        // ── Controls ─────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 18

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "󰒮"
                                color: root.player && root.player.canGoPrevious
                                       ? "#e6e6f0" : "#4a4a55"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.player && root.player.canGoPrevious
                                    onClicked: root.player.previous()
                                }
                            }
                            Text {
                                text: root.player
                                      && root.player.playbackState === MprisPlaybackState.Playing
                                      ? "󰏤" : "󰐊"
                                color: "#a78bfa"
                                font.pixelSize: 22
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.player !== null
                                    onClicked: if (root.player) root.player.playPause()
                                }
                            }
                            Text {
                                text: "󰒭"
                                color: root.player && root.player.canGoNext
                                       ? "#e6e6f0" : "#4a4a55"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.player && root.player.canGoNext
                                    onClicked: root.player.next()
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

        }
    }
  '';
}
