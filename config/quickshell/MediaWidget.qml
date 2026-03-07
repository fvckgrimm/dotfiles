import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: root
    implicitHeight: 22
    implicitWidth: visible ? chip.implicitWidth : 0

    // Use the first active player, prefer one that's Playing
    property MprisPlayer activePlayer: {
        var players = Mpris.players
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    visible: activePlayer !== null

    readonly property string mediaIcon: {
        if (!activePlayer) return ""
        if (activePlayer.identity?.toLowerCase().includes("spotify")) return ""
        return "🎜"
    }

    readonly property string trackText: {
        if (!activePlayer) return ""
        var artist = activePlayer.trackArtists?.join(", ") ?? ""
        var title  = activePlayer.trackTitle ?? ""
        var info   = (artist && title) ? (artist + " - " + title) : (title || artist)
        if (info.length > 40) info = info.substring(0, 40) + "…"
        var paused = activePlayer.playbackState !== MprisPlaybackState.Playing
        return paused ? ("  " + info) : info
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: root.mediaIcon
        value: root.trackText
        iconColor: "#c792ea"
        valueColor: "#c792ea"
        accentColor: "#80c792ea"
        bgColor: "#661e1e28"
        tooltipText: root.activePlayer
            ? (root.activePlayer.identity + ": " + root.trackText)
            : ""

        onClicked: { if (root.activePlayer) root.activePlayer.togglePlaying() }
        onRightClicked: { if (root.activePlayer) root.activePlayer.next() }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (!root.activePlayer) return
            if (wheel.angleDelta.y > 0) root.activePlayer.previous()
            else root.activePlayer.next()
        }
    }
}

