#!/usr/bin/env python3
"""Generate a Theme palette (the 32-key object Theme.qml expects) from a wallpaper.

Usage: qs-theme.py <image>
Prints a single JSON line:
  {"palette": {...}, "light": bool}   on success
  {"fallback": true}                  wallpaper is monochrome / unsuitable

Approach (Material-You-ish approximation):
- Quantize the image down to ~10 dominant clusters.
- The most common cluster drives the neutral surface ramp (low chroma).
- The most saturated clusters become the primary / secondary / tertiary
  accents; every token is derived from a seed via a tonal ramp
  (full chroma at tone 50, melting to black/white at the extremes).
- Light vs dark surfaces chosen from the image's mean luminance.
"""
import colorsys
import json
import math
import sys

try:
    from PIL import Image
except ImportError:
    sys.stderr.write("qs-theme: PIL not available\n")
    sys.exit(1)


def rgb_hex(rgb):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(c))) for c in rgb)


def lum(rgb):
    r, g, b = (c / 255.0 for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hsl(rgb):
    r, g, b = (c / 255.0 for c in rgb)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h, s, l


def hsl_to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h % 1.0, max(0.0, min(1.0, l)), max(0.0, min(1.0, s)))
    return rgb_hex((r * 255, g * 255, b * 255))


def tonal(seed_h, seed_s, t):
    """Tone ramp: full chroma at t=50, melts to black/white at the ends."""
    c = math.sin(math.pi * t / 100.0) ** 0.8
    return hsl_to_hex(seed_h, seed_s * c, t / 100.0)


def hue_dist(a, b):
    d = abs(a - b)
    return min(d, 1.0 - d) * 360


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else ""
    if not path:
        sys.stdout.write('{"fallback": true}')
        return

    try:
        img = Image.open(path).convert("RGB")
    except Exception:
        sys.stdout.write('{"fallback": true}')
        return
    img = img.resize((128, 128), Image.LANCZOS)

    q = img.quantize(colors=10, method=Image.MEDIANCUT)
    palette = q.getpalette()
    clusters = []
    for count, idx in sorted(q.getcolors(), reverse=True):
        rgb = tuple(palette[idx * 3: idx * 3 + 3])
        h, s, l = hsl(rgb)
        clusters.append({"count": count, "rgb": rgb, "lum": lum(rgb), "h": h, "s": s, "l": l})

    total = sum(c["count"] for c in clusters) or 1
    for c in clusters:
        c["w"] = c["count"] / total

    mean_lum = sum(c["w"] * c["lum"] for c in clusters)
    light = mean_lum > 0.55

    dom = clusters[0]

    # Accent candidates: saturated, not near-black/white.
    cands = sorted(
        (c for c in clusters if 0.08 < c["lum"] < 0.92),
        key=lambda c: c["s"] if c["lum"] > 0.1 else 0.0,
        reverse=True,
    )
    if not cands or cands[0]["s"] < 0.12:
        sys.stdout.write('{"fallback": true}')
        return

    primary_seed = cands[0]
    secondary_seed = tertiary_seed = None
    for c in cands[1:]:
        if secondary_seed is None and hue_dist(c["h"], primary_seed["h"]) > 30:
            secondary_seed = c
        elif (tertiary_seed is None and secondary_seed is not None
              and hue_dist(c["h"], primary_seed["h"]) > 30
              and hue_dist(c["h"], secondary_seed["h"]) > 30):
            tertiary_seed = c
    if secondary_seed is None:
        secondary_seed = {"h": (primary_seed["h"] + 0.08) % 1.0, "s": max(0.5, primary_seed["s"] * 0.85)}
    if tertiary_seed is None:
        tertiary_seed = {"h": (primary_seed["h"] + 0.33) % 1.0, "s": max(0.45, primary_seed["s"] * 0.7)}

    # Neutral seed: dominant color's hue at low chroma.
    n_h = dom["h"] if dom["s"] > 0.05 else primary_seed["h"]
    n_s = max(0.04, min(0.12, dom["s"]))

    if light:
        bg_t, surf_t = 97, 92
        low_t, mid_t, high_t, highst_t = 88, 84, 80, 76
        otl_t, otlvar_t = 55, 80
        text_t, textvar_t, textdim_t = 12, 30, 52
        acc_t, acctext_t, acccont_t, accconttext_t = 40, 100, 90, 12
    else:
        bg_t, surf_t = 6, 10
        low_t, mid_t, high_t, highst_t = 14, 18, 22, 26
        otl_t, otlvar_t = 55, 30
        text_t, textvar_t, textdim_t = 96, 82, 62
        acc_t, acctext_t, acccont_t, accconttext_t = 80, 20, 30, 92

    p = {}
    p["background"] = tonal(n_h, n_s, bg_t)
    p["surface"] = tonal(n_h, n_s, surf_t)
    p["surfaceContainerLowest"] = tonal(n_h, n_s, 4 if not light else 100)
    p["surfaceContainerLow"] = tonal(n_h, n_s, low_t)
    p["surfaceContainer"] = tonal(n_h, n_s, mid_t)
    p["surfaceContainerHigh"] = tonal(n_h, n_s, high_t)
    p["surfaceContainerHighest"] = tonal(n_h, n_s, highst_t)
    p["outline"] = tonal(n_h, n_s, otl_t)
    p["outlineVariant"] = tonal(n_h, n_s, otlvar_t)
    p["surfaceText"] = tonal(n_h, n_s, text_t)
    p["surfaceTextVariant"] = tonal(n_h, n_s, textvar_t)
    p["surfaceTextDim"] = tonal(n_h, n_s, textdim_t)

    def accent(seed):
        return {
            "a": tonal(seed["h"], seed["s"], acc_t),
            "aText": tonal(seed["h"], seed["s"], acctext_t),
            "aContainer": tonal(seed["h"], seed["s"], acccont_t),
            "aContainerText": tonal(seed["h"], seed["s"], accconttext_t),
        }

    def assign(base_key, seed):
        a = accent(seed)
        p[base_key] = a["a"]
        p[base_key + "Text"] = a["aText"]
        p[base_key + "Container"] = a["aContainer"]
        p[base_key + "ContainerText"] = a["aContainerText"]

    assign("primary", primary_seed)
    assign("secondary", secondary_seed)
    assign("tertiary", tertiary_seed)
    assign("error", {"h": 0.0, "s": 0.82})

    for base, seed in (("warning", {"h": 0.10, "s": 0.85}),
                       ("success", {"h": 0.37, "s": 0.75})):
        a = accent(seed)
        p[base] = a["a"]
        p[base + "Container"] = a["aContainer"]

    sys.stdout.write(json.dumps({"palette": p, "light": light}))


if __name__ == "__main__":
    main()
