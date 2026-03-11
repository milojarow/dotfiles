#!/usr/bin/env python3
"""
Render a speedometer-style gauge as PNG using pycairo.
Usage: gauge-render.py <value> <min_val> <max_val> <label> <output_path>
"""
import cairo
import math
import sys


def hex_rgb(h):
    h = h.lstrip('#')
    return int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255


def draw_gauge(value, min_val, max_val, label, output, unit="°C", icon=""):
    W, H = 200, 210
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
    ctx = cairo.Context(surface)

    # Transparent background
    ctx.set_source_rgba(0, 0, 0, 0)
    ctx.paint()

    cx = W / 2
    cy = H / 2 + 20    # shift center down to make room for top labels

    R     = 68          # radius to arc center
    THICK = 10          # arc thickness

    # Gauge: 300° clockwise from 210° (7 o'clock) to 150° (5 o'clock), via top
    START = 210
    SWEEP = 300

    def to_rad(deg):
        """Degrees clockwise-from-top  →  cairo radians (CW from 3 o'clock)."""
        return math.radians(deg - 90)

    start_rad = to_rad(START)
    end_rad   = to_rad(START + SWEEP)   # to_rad(510) == to_rad(150)

    # ── Background track ──────────────────────────────────────────────────────
    ctx.arc(cx, cy, R, start_rad, end_rad)
    ctx.set_source_rgba(1, 1, 1, 0.10)
    ctx.set_line_width(THICK)
    ctx.set_line_cap(cairo.LINE_CAP_BUTT)
    ctx.stroke()

    # ── Value arc ─────────────────────────────────────────────────────────────
    clamped = max(min_val, min(max_val, value))
    frac    = (clamped - min_val) / (max_val - min_val)

    if frac < 0.60:
        arc_rgb = hex_rgb('#A3BE8C')
    elif frac < 0.80:
        arc_rgb = hex_rgb('#EBCB8B')
    else:
        arc_rgb = hex_rgb('#BF616A')

    if frac > 0:
        ctx.arc(cx, cy, R, start_rad, to_rad(START + frac * SWEEP))
        ctx.set_source_rgba(*arc_rgb, 1.0)
        ctx.set_line_width(THICK)
        ctx.set_line_cap(cairo.LINE_CAP_BUTT)
        ctx.stroke()

    # ── Temperature value ─────────────────────────────────────────────────────
    val_str = f"{int(value)}{unit}"
    ctx.set_font_size(22)
    ctx.set_source_rgba(1, 1, 1, 0.95)
    ext = ctx.text_extents(val_str)
    ctx.move_to(cx - ext.width / 2 - ext.x_bearing,
                cy - ext.height / 2 - ext.y_bearing)
    ctx.show_text(val_str)

    # ── Label (CPU / GPU / RAM) ───────────────────────────────────────────────
    ctx.set_font_size(10)
    ctx.set_source_rgba(*arc_rgb, 0.85)
    ext = ctx.text_extents(label)
    ctx.move_to(cx - ext.width / 2 - ext.x_bearing, cy + 20)
    ctx.show_text(label)

    # ── Icon ─────────────────────────────────────────────────────────────────
    if icon:
        ctx.select_font_face("JetBrainsMono Nerd Font", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
        ctx.set_font_size(20)
        ctx.set_source_rgba(1, 1, 1, 0.90)
        ext = ctx.text_extents(icon)
        ctx.move_to(cx - ext.width / 2 - ext.x_bearing,
                    cy - 38 - ext.y_bearing)
        ctx.show_text(icon)

    surface.write_to_png(output)


if __name__ == '__main__':
    value   = float(sys.argv[1])
    min_val = float(sys.argv[2]) if len(sys.argv) > 2 else 0
    max_val = float(sys.argv[3]) if len(sys.argv) > 3 else 100
    label   = sys.argv[4]        if len(sys.argv) > 4 else ""
    output  = sys.argv[5]        if len(sys.argv) > 5 else "/tmp/gauge.png"
    unit    = sys.argv[6]        if len(sys.argv) > 6 else "°C"
    icon    = sys.argv[7]        if len(sys.argv) > 7 else ""
    draw_gauge(value, min_val, max_val, label, output, unit, icon)
