pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// MediaService — single source of truth for the "now playing" state shared
// by the bar MediaWidget and the ControlCenter now-playing card.
//
// MprisPlayer.position/length are in SECONDS. position does NOT update
// reactively on its own (see Quickshell docs) — call `poll()` on a Timer
// while the UI is visible so the position binding re-evaluates.
Scope {
    id: root

    readonly property MprisPlayer activePlayer: {
        var players = Mpris.players ? Mpris.players.values : []
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    readonly property bool hasPlayer: root.activePlayer !== null
    readonly property string identity: root.activePlayer ? root.activePlayer.identity : ""
    readonly property string title:    root.activePlayer ? (root.activePlayer.trackTitle || "") : ""
    readonly property string artist:   root.activePlayer ? (root.activePlayer.trackArtists || root.activePlayer.trackArtist || "") : ""
    readonly property string album:    root.activePlayer ? (root.activePlayer.trackAlbum || "") : ""
    readonly property string artUrl:   root.activePlayer ? (root.activePlayer.trackArtUrl || "") : ""
    readonly property bool isPlaying:  root.activePlayer ? root.activePlayer.isPlaying : false

    readonly property double position: root.activePlayer ? root.activePlayer.position : 0
    readonly property double length:   root.activePlayer ? root.activePlayer.length : 0
    readonly property bool canSeek:    root.activePlayer ? (root.activePlayer.canSeek && root.activePlayer.positionSupported) : false

    // Explicit play/pause instead of PlayPause: Chromium/Brave historically
    // ignores the MPRIS PlayPause method, so a toggle lands as a no-op there.
    function toggle() {
        var p = root.activePlayer
        if (!p) return
        if (p.isPlaying) { if (p.canPause) p.pause() }
        else             { if (p.canPlay)  p.play() }
    }
    function next()     { var p = root.activePlayer; if (p) p.next() }
    function previous() { var p = root.activePlayer; if (p) p.previous() }
    function raise()    { var p = root.activePlayer; if (p && p.canRaise) p.raise() }

    // Force a position re-read. Call on a Timer while progress is visible.
    function poll() {
        var p = root.activePlayer
        if (p) p.positionChanged()
    }

    // Seek to a 0..1 fraction of the current track.
    function seekToFraction(frac) {
        var p = root.activePlayer
        if (!p || !root.canSeek) return
        var target = Math.max(0, Math.min(1, frac)) * root.length
        p.seek(target - root.position)
    }

    // mm:ss or h:mm:ss from seconds.
    function format(sec) {
        var s = Math.max(0, Math.floor(sec))
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60
        var mm = (m < 10 ? "0" : "") + m, ss = (r < 10 ? "0" : "") + r
        return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss
    }
}
