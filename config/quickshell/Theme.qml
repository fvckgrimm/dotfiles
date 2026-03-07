pragma Singleton
import Quickshell
import QtQuick

// Central config — edit fontFamily to match your installed Nerd Font name exactly
// Run: fc-list | grep -i "nerd\|jetbrains" to find the right name
Scope {
    // ── Font ─────────────────────────────────────────────────────────────────
    // Common names: "JetBrainsMono Nerd Font", "JetBrainsMonoNL Nerd Font Mono",
    //               "JetBrains Mono NF", "BlexMono Nerd Font"
    // Check yours with: fc-list | grep -i "nerd\|jetbrains"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int    fontSize:   8
    readonly property int    iconSize:   10

    // ── App launcher ─────────────────────────────────────────────────────────
    // Change this if you use rofi, bemenu, wofi, etc.
    readonly property var launcherCmd: ["fuzzel"]
    readonly property var drawerCmd:   ["nwg-drawer"]

    // ── Colors (cyberpunk palette) ────────────────────────────────────────────
    readonly property string bgBar:       "#d90d1117"
    readonly property string bgModule:    "#661e1e28"
    readonly property string bgHover:     "#991e1e28"
    readonly property string borderBar:   "#335bcefa"
    readonly property string textPrimary: "#d8e0f0"
    readonly property string textDim:     "#7984a4"
    readonly property string textDimmer:  "#555e7a"
    readonly property string cyan:        "#0df0ff"
    readonly property string red:         "#ff416c"
    readonly property string yellow:      "#ffcc00"
    readonly property string orange:      "#fab387"
    readonly property string green:       "#00ff9d"
    readonly property string purple:      "#c792ea"
}
