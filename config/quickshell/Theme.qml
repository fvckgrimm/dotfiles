pragma Singleton
import Quickshell
import QtQuick

// ─────────────────────────────────────────────────────────────────────────
// Theme — material-inspired design token system
//
// Replaces the old flat "cyberpunk" palette (neon borders + per-widget
// hardcoded hex) with a layered token system closer to Material 3 /
// dankmaterialshell / noctalia: tonal surfaces instead of glow, one
// primary accent instead of five neon ones, semantic colors for meaning
// (error/warning/success) rather than decoration, and shared shape/
// spacing/motion scales so every widget stops inventing its own radius,
// margin, and animation duration.
//
// NOTE on naming: Material calls text-on-a-colored-surface tokens like
// "onSurface" / "onPrimary". QML reserves any property name starting
// with "on" + capital letter for signal handlers, so those names cannot
// be used directly here — the "On" is a suffix instead (surfaceText,
// primaryText, etc.) to keep the same meaning without colliding with
// QML's signal-handler syntax.
//
// LEGACY ALIASES: at the bottom of this file, the old property names
// (bgBar, cyan, textPrimary, etc.) are kept as aliases onto the new
// tokens so nothing breaks today. They're marked deprecated — widgets
// should be migrated to the new names one at a time, then the aliases
// section can be deleted.
// ─────────────────────────────────────────────────────────────────────────

Scope {
    id: theme

    // ── Font ─────────────────────────────────────────────────────────────
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int    fontSize:   8
    readonly property int    iconSize:   10

    // ── External commands ───────────────────────────────────────────────
    readonly property var launcherCmd: ["fuzzel"]
    readonly property var drawerCmd:   ["nwg-drawer"]

    // ─────────────────────────────────────────────────────────────────────
    // THEMES
    // The whole color scheme is data-driven: each palette below maps a
    // token to a hex value, and `currentTheme` picks which one is live.
    // All color tokens are readonly bindings into `_p` (the active
    // palette), so switching `currentTheme` repaints every widget that
    // reads Theme.* — no reload needed.
    //
    // "default" is the original cyberpunk/material palette (kept bit-for-
    // bit identical so nothing changes out of the box). The rest are
    // re-rolls of Catppuccin (mocha/macchiato/frappe/latte), Dracula, and
    // Rose Pine mapped onto the same token roles.
    //
    // Every palette must define exactly these keys (33 total). `surface`
    // → `surfaceContainerHighest` are elevation steps, darkest → lightest.
    // ─────────────────────────────────────────────────────────────────────
    property string currentTheme: "default"

    readonly property var palettes: ({
        "default": {
            background: "#0e1116", surface: "#12161d",
            surfaceContainerLowest: "#0a0d12", surfaceContainerLow: "#161b23",
            surfaceContainer: "#1b212b", surfaceContainerHigh: "#212836",
            surfaceContainerHighest: "#28303f",
            outline: "#3a4354", outlineVariant: "#262d3a",
            surfaceText: "#e2e6ee", surfaceTextVariant: "#98a2b8", surfaceTextDim: "#5c6579",
            primary: "#7dd8ff", primaryText: "#00303f", primaryContainer: "#1c3a49", primaryContainerText: "#bfe9ff",
            secondary: "#e3b872", secondaryText: "#3a2a05", secondaryContainer: "#4a3a15", secondaryContainerText: "#f7ddb0",
            tertiary: "#c9a8f0", tertiaryText: "#3a2555", tertiaryContainer: "#4a3565", tertiaryContainerText: "#e9d9fa",
            error: "#ff6b7d", errorText: "#3a0510", errorContainer: "#4a1520", errorContainerText: "#ffd8dc",
            warning: "#f0b860", warningContainer: "#4a3515",
            success: "#7ee0a8", successContainer: "#1c4a30"
        },
        "catppuccin-mocha": {
            background: "#1e1e2e", surface: "#313244",
            surfaceContainerLowest: "#11111b", surfaceContainerLow: "#45475a",
            surfaceContainer: "#585b70", surfaceContainerHigh: "#6c7086",
            surfaceContainerHighest: "#7f849c",
            outline: "#9399b2", outlineVariant: "#45475a",
            surfaceText: "#cdd6f4", surfaceTextVariant: "#bac2de", surfaceTextDim: "#7f849c",
            primary: "#cba6f7", primaryText: "#1e1e2e", primaryContainer: "#43375e", primaryContainerText: "#e5d8fa",
            secondary: "#fab387", secondaryText: "#2e2418", secondaryContainer: "#4a3a24", secondaryContainerText: "#f9e0c9",
            tertiary: "#94e2d5", tertiaryText: "#0a2e28", tertiaryContainer: "#1c4039", tertiaryContainerText: "#d2f5ec",
            error: "#f38ba8", errorText: "#3d0a18", errorContainer: "#4d2030", errorContainerText: "#ffd5df",
            warning: "#f9e2af", warningContainer: "#4a4028",
            success: "#a6e3a1", successContainer: "#24482a"
        },
        "catppuccin-macchiato": {
            background: "#24273a", surface: "#363a4f",
            surfaceContainerLowest: "#181926", surfaceContainerLow: "#494d64",
            surfaceContainer: "#5b6078", surfaceContainerHigh: "#6e738d",
            surfaceContainerHighest: "#8087a2",
            outline: "#939ab7", outlineVariant: "#494d64",
            surfaceText: "#cad3f5", surfaceTextVariant: "#b8c0e0", surfaceTextDim: "#8087a2",
            primary: "#c6a0f6", primaryText: "#241e33", primaryContainer: "#443d63", primaryContainerText: "#e6dcfb",
            secondary: "#f5a97f", secondaryText: "#2e2118", secondaryContainer: "#4a3526", secondaryContainerText: "#f9dfc9",
            tertiary: "#8bd5ca", tertiaryText: "#082a24", tertiaryContainer: "#1c3d38", tertiaryContainerText: "#cff3ec",
            error: "#ed8796", errorText: "#3a0a15", errorContainer: "#4d202c", errorContainerText: "#ffd6de",
            warning: "#eed49f", warningContainer: "#4a3e26",
            success: "#a6da95", successContainer: "#24482a"
        },
        "catppuccin-frappe": {
            background: "#303446", surface: "#414559",
            surfaceContainerLowest: "#232634", surfaceContainerLow: "#51576d",
            surfaceContainer: "#626880", surfaceContainerHigh: "#737994",
            surfaceContainerHighest: "#838ba7",
            outline: "#949cbb", outlineVariant: "#51576d",
            surfaceText: "#c6d0f5", surfaceTextVariant: "#b5bfe2", surfaceTextDim: "#838ba7",
            primary: "#ca9ee6", primaryText: "#2b2538", primaryContainer: "#4b4170", primaryContainerText: "#eadcff",
            secondary: "#ef9f76", secondaryText: "#322118", secondaryContainer: "#503523", secondaryContainerText: "#fae0cd",
            tertiary: "#81c8be", tertiaryText: "#0a2c27", tertiaryContainer: "#1e403c", tertiaryContainerText: "#cff3ee",
            error: "#e78284", errorText: "#3a0d10", errorContainer: "#522327", errorContainerText: "#ffd9db",
            warning: "#e5c890", warningContainer: "#4a3f28",
            success: "#a6d189", successContainer: "#27472b"
        },
        "catppuccin-latte": {
            background: "#eff1f5", surface: "#ccd0da",
            surfaceContainerLowest: "#dce0e8", surfaceContainerLow: "#bcc0cc",
            surfaceContainer: "#acb0be", surfaceContainerHigh: "#9ca0b0",
            surfaceContainerHighest: "#8c8fa1",
            outline: "#7c7f93", outlineVariant: "#bcc0cc",
            surfaceText: "#4c4f69", surfaceTextVariant: "#5c5f77", surfaceTextDim: "#8c8fa1",
            primary: "#8839ef", primaryText: "#ffffff", primaryContainer: "#e3d6fb", primaryContainerText: "#4c2c7a",
            secondary: "#fe640b", secondaryText: "#ffffff", secondaryContainer: "#fbd7c3", secondaryContainerText: "#7a340a",
            tertiary: "#179299", tertiaryText: "#ffffff", tertiaryContainer: "#bfe8e6", tertiaryContainerText: "#0a3c40",
            error: "#d20f39", errorText: "#ffffff", errorContainer: "#f9c7d0", errorContainerText: "#7a0a1c",
            warning: "#df8e1d", warningContainer: "#f2dfc3",
            success: "#40a02b", successContainer: "#c9e8c4"
        },
        "dracula": {
            background: "#282a36", surface: "#2e3040",
            surfaceContainerLowest: "#21222c", surfaceContainerLow: "#333747",
            surfaceContainer: "#3b3f52", surfaceContainerHigh: "#44475a",
            surfaceContainerHighest: "#4b5066",
            outline: "#565b70", outlineVariant: "#3b3f52",
            surfaceText: "#f8f8f2", surfaceTextVariant: "#c0c3cf", surfaceTextDim: "#70758a",
            primary: "#bd93f9", primaryText: "#241f33", primaryContainer: "#4a3a6e", primaryContainerText: "#ece2ff",
            secondary: "#ffb86c", secondaryText: "#2e2113", secondaryContainer: "#4a3a24", secondaryContainerText: "#ffe6c9",
            tertiary: "#ff79c6", tertiaryText: "#351226", tertiaryContainer: "#4d2038", tertiaryContainerText: "#ffd5ec",
            error: "#ff5555", errorText: "#3a0a0a", errorContainer: "#4d1c1c", errorContainerText: "#ffd6d6",
            warning: "#f1fa8c", warningContainer: "#3d4a1f",
            success: "#50fa7b", successContainer: "#1c4a2e"
        },
        "rosepine": {
            background: "#191724", surface: "#1f1d2e",
            surfaceContainerLowest: "#131120", surfaceContainerLow: "#26233a",
            surfaceContainer: "#403d52", surfaceContainerHigh: "#524f67",
            surfaceContainerHighest: "#5b5872",
            outline: "#6e6a86", outlineVariant: "#403d52",
            surfaceText: "#e0def4", surfaceTextVariant: "#908caa", surfaceTextDim: "#6e6a86",
            primary: "#c4a7e7", primaryText: "#241d33", primaryContainer: "#463d63", primaryContainerText: "#eadcff",
            secondary: "#f6c177", secondaryText: "#2e2413", secondaryContainer: "#4a3d24", secondaryContainerText: "#ffe6c9",
            tertiary: "#9ccfd8", tertiaryText: "#0a2428", tertiaryContainer: "#1e3c44", tertiaryContainerText: "#d0eef4",
            error: "#eb6f92", errorText: "#3a0a14", errorContainer: "#4d2030", errorContainerText: "#ffd5e0",
            warning: "#ebbcba", warningContainer: "#4a3a38",
            success: "#31748f", successContainer: "#1c3a44"
        }
    })

    readonly property var _p: palettes[currentTheme] ?? palettes["default"]

    // ─────────────────────────────────────────────────────────────────────
    // COLOR — surfaces (elevation via tone, not glow)
    // Darkest → lightest. Popups/cards sit on higher containers than the
    // bar itself, which is how Material communicates stacking order
    // without borders doing all the work.
    // ─────────────────────────────────────────────────────────────────────
    readonly property string background:              _p.background
    readonly property string surface:                  _p.surface
    readonly property string surfaceContainerLowest:   _p.surfaceContainerLowest
    readonly property string surfaceContainerLow:      _p.surfaceContainerLow
    readonly property string surfaceContainer:         _p.surfaceContainer
    readonly property string surfaceContainerHigh:     _p.surfaceContainerHigh
    readonly property string surfaceContainerHighest:  _p.surfaceContainerHighest

    // Outlines — for the rare places a hairline is actually needed
    // (dividers, input focus rings). Not used for decorative glow boxes.
    readonly property string outline:        _p.outline
    readonly property string outlineVariant: _p.outlineVariant

    // Text — three tones instead of guessing a new grey per widget
    readonly property string surfaceText:        _p.surfaceText      // primary text
    readonly property string surfaceTextVariant: _p.surfaceTextVariant // secondary text
    readonly property string surfaceTextDim:     _p.surfaceTextDim    // tertiary / disabled

    // ── Primary accent — the ONE color used for focus, active states,
    // links, and the main interactive affordance across the whole shell.
    // Old design used cyan for this; kept close but desaturated so it
    // reads as "material accent" rather than "neon sign".
    readonly property string primary:             _p.primary
    readonly property string primaryText:         _p.primaryText      // content on primary
    readonly property string primaryContainer:    _p.primaryContainer
    readonly property string primaryContainerText: _p.primaryContainerText

    // ── Secondary accent — warm, used sparingly for things that mean
    // "attention, but not urgent" (pinned todos, volume/brightness).
    readonly property string secondary:              _p.secondary
    readonly property string secondaryText:          _p.secondaryText
    readonly property string secondaryContainer:     _p.secondaryContainer
    readonly property string secondaryContainerText: _p.secondaryContainerText

    // ── Tertiary accent — used for a distinct "creative/media" surface
    // (wallpaper picker, media widget) so it doesn't compete with primary.
    readonly property string tertiary:              _p.tertiary
    readonly property string tertiaryText:          _p.tertiaryText
    readonly property string tertiaryContainer:     _p.tertiaryContainer
    readonly property string tertiaryContainerText: _p.tertiaryContainerText

    // ── Semantic colors — meaning, not decoration. Only ever used for
    // errors/destructive actions, warnings, and success/positive states.
    readonly property string error:              _p.error
    readonly property string errorText:          _p.errorText
    readonly property string errorContainer:     _p.errorContainer
    readonly property string errorContainerText: _p.errorContainerText

    readonly property string warning:          _p.warning
    readonly property string warningContainer: _p.warningContainer

    readonly property string success:          _p.success
    readonly property string successContainer: _p.successContainer

    // Ordered list for theme pickers / cycling — first entry is the fallback.
    readonly property var themeNames: ["default", "catppuccin-mocha", "catppuccin-macchiato",
        "catppuccin-frappe", "catppuccin-latte", "dracula", "rosepine"]

    function prettyName(name) {
        var map = { "default": "Default", "catppuccin-mocha": "Catppuccin Mocha",
            "catppuccin-macchiato": "Catppuccin Macchiato", "catppuccin-frappe": "Catppuccin Frappe",
            "catppuccin-latte": "Catppuccin Latte", "dracula": "Dracula", "rosepine": "Rose Pine" }
        return map[name] ?? name
    }

    function cycle() {
        var idx = themeNames.indexOf(currentTheme)
        var next = themeNames[(idx + 1) % themeNames.length]
        currentTheme = next
        return next
    }

    // ─────────────────────────────────────────────────────────────────────
    // SHAPE — one radius scale, used everywhere instead of ad-hoc 2/3/4/5/6/8/10
    // ─────────────────────────────────────────────────────────────────────
    readonly property int radiusXs:   4
    readonly property int radiusSm:   6
    readonly property int radiusMd:   8
    readonly property int radiusLg:   12
    readonly property int radiusXl:   16
    readonly property int radiusFull: 999

    // ─────────────────────────────────────────────────────────────────────
    // SPACING — one scale, used for margins/padding/gaps
    // ─────────────────────────────────────────────────────────────────────
    readonly property int spacingXs:  2
    readonly property int spacingSm:  4
    readonly property int spacingMd:  8
    readonly property int spacingLg:  12
    readonly property int spacingXl:  16
    readonly property int spacingXxl: 24

    // ─────────────────────────────────────────────────────────────────────
    // MOTION — shared durations/easing instead of each widget picking
    // its own 80/100/120/150/180/200/260/280ms
    // ─────────────────────────────────────────────────────────────────────
    readonly property int motionFast:   100   // hover/press feedback
    readonly property int motionMedium: 180   // toggles, expand/collapse
    readonly property int motionSlow:   280   // panel slide-in/out
    readonly property int easingStandard: Easing.OutCubic

    // ─────────────────────────────────────────────────────────────────────
    // STATE LAYERS — Material-style hover/press/focus opacities, applied
    // as a tint of surfaceText (or the relevant accent) over a surface,
    // rather than swapping the whole background color per widget.
    // ─────────────────────────────────────────────────────────────────────
    readonly property real stateHoverOpacity:    0.08
    readonly property real statePressedOpacity:  0.12
    readonly property real stateFocusOpacity:    0.10
    readonly property real stateDisabledOpacity: 0.38

    // ─────────────────────────────────────────────────────────────────────
    // TYPOGRAPHY — point-size scale (Qt uses font.pointSize)
    // ─────────────────────────────────────────────────────────────────────
    readonly property real labelSmall:  6
    readonly property real labelMedium: 7
    readonly property real labelLarge:  8
    readonly property real bodySmall:   7.5
    readonly property real bodyMedium:  8
    readonly property real bodyLarge:   9
    readonly property real titleSmall:  9
    readonly property real titleMedium: 10
    readonly property real titleLarge:  12

    // ─────────────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────────────

    // withAlpha("#7dd8ff", 0.2) -> "#337dd8ff"  (ARGB hex string)
    // Use this instead of hand-picking a new "#22xxxxxx" every time a
    // widget needs a translucent tint of a token color.
    function withAlpha(hex, alpha) {
        var clamped = Math.max(0, Math.min(1, alpha))
        var a = Math.round(clamped * 255).toString(16).padStart(2, "0")
        var clean = hex.toString().replace("#", "").substring(0, 6)
        return "#" + a + clean
    }

    // Standard "surface + hairline outline" card style, so popups/menus
    // stop each defining their own bg/border pair.
    function cardColor()  { return withAlpha(surfaceContainer, 0.94) }
    function cardBorder() { return withAlpha(outline, 0.4) }

    // ─────────────────────────────────────────────────────────────────────
    // ⚠ DEPRECATED — legacy aliases for migration only.
    // Every widget currently reads these old names. Once a widget is
    // migrated to the tokens above, remove its reliance on this section.
    // Do not add new usages of these names.
    // ─────────────────────────────────────────────────────────────────────
    readonly property string bgBar:     withAlpha(surfaceContainerLowest, 0.92)
    readonly property string bgModule:  withAlpha(surfaceContainer, 0.55)
    readonly property string bgHover:   withAlpha(surfaceContainerHigh, 0.7)
    readonly property string borderBar: withAlpha(outline, 0.35)

    readonly property string textPrimary: surfaceText
    readonly property string textDim:     surfaceTextVariant
    readonly property string textDimmer:  surfaceTextDim

    readonly property string cyan:   primary
    readonly property string red:    error
    readonly property string yellow: warning
    readonly property string orange: secondary
    readonly property string green:  success
    readonly property string purple: tertiary
}
