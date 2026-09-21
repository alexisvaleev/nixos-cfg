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

                        // ── Progress bar + seek ──────────────────
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16

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
                                    width: {
                                        const p = root.player;
                                        if (!p || !(p.length > 0)) return 0;
                                        return parent.width
                                             * Math.max(0, Math.min(1, p.position / p.length));
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: (m) => {
                                        const p = root.player;
                                        if (p && p.canSeek && p.length > 0)
                                            p.setPosition(p.length * m.x / width);
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: root.fmtTime(root.player ? root.player.position : 0)
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
