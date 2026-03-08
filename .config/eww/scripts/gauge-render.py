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


def draw_gauge(value, min_val, max_val, label, output):
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

    # ── Tick marks & labels ───────────────────────────────────────────────────
    N_MAJOR = 5    # 6 marks: 0, 20, 40, 60, 80, 100
    N_MINOR = 4    # minor ticks between majors
    N_DIVS  = N_MAJOR * N_MINOR   # 20 total intervals

    R_in          = R + THICK // 2 + 2
    R_out_major   = R + THICK // 2 + 10
    R_out_minor   = R + THICK // 2 + 6
    R_label       = R + THICK // 2 + 22

    ctx.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)

    for i in range(N_DIVS + 1):
        t = i / N_DIVS
        a = to_rad(START + t * SWEEP)
        is_major = (i % N_MINOR == 0)

        r_out = R_out_major if is_major else R_out_minor
        alpha = 0.80        if is_major else 0.35
        lw    = 1.5         if is_major else 0.8

        ix, iy = cx + R_in  * math.cos(a), cy + R_in  * math.sin(a)
        ox, oy = cx + r_out * math.cos(a), cy + r_out * math.sin(a)

        ctx.move_to(ix, iy)
        ctx.line_to(ox, oy)
        ctx.set_source_rgba(1, 1, 1, alpha)
        ctx.set_line_width(lw)
        ctx.stroke()

        if is_major:
            tick_val = int(round(min_val + t * (max_val - min_val)))
            lx = cx + R_label * math.cos(a)
            ly = cy + R_label * math.sin(a)
            ctx.set_font_size(9)
            ctx.set_source_rgba(1, 1, 1, 0.60)
            ext = ctx.text_extents(str(tick_val))
            ctx.move_to(lx - ext.width / 2 - ext.x_bearing,
                        ly - ext.height / 2 - ext.y_bearing)
            ctx.show_text(str(tick_val))

    # ── Needle ────────────────────────────────────────────────────────────────
    needle_a = to_rad(START + frac * SWEEP)
    needle_r = R - THICK // 2 - 4   # tip just inside the track
    back_r   = 14                    # extension past center

    tip_x  = cx + needle_r * math.cos(needle_a)
    tip_y  = cy + needle_r * math.sin(needle_a)
    base_x = cx - back_r * math.cos(needle_a)
    base_y = cy - back_r * math.sin(needle_a)

    perp  = needle_a + math.pi / 2
    bw    = 4
    b1x   = base_x + bw * math.cos(perp);  b1y = base_y + bw * math.sin(perp)
    b2x   = base_x - bw * math.cos(perp);  b2y = base_y - bw * math.sin(perp)

    ctx.move_to(tip_x, tip_y)
    ctx.line_to(b1x, b1y)
    ctx.line_to(b2x, b2y)
    ctx.close_path()
    ctx.set_source_rgba(1, 1, 1, 0.95)
    ctx.fill()

    # ── Center cap ────────────────────────────────────────────────────────────
    ctx.arc(cx, cy, 8, 0, 2 * math.pi)
    ctx.set_source_rgba(1, 1, 1, 0.95)
    ctx.fill()
    ctx.arc(cx, cy, 5, 0, 2 * math.pi)
    ctx.set_source_rgba(*hex_rgb('#2E3440'), 1.0)
    ctx.fill()

    # ── Temperature value ─────────────────────────────────────────────────────
    val_str = f"{int(value)}°C"
    ctx.set_font_size(16)
    ctx.set_source_rgba(1, 1, 1, 0.95)
    ext = ctx.text_extents(val_str)
    ctx.move_to(cx - ext.width / 2 - ext.x_bearing, cy + 34)
    ctx.show_text(val_str)

    # ── Label (CPU / GPU) ─────────────────────────────────────────────────────
    ctx.set_font_size(10)
    ctx.set_source_rgba(*arc_rgb, 0.85)
    ext = ctx.text_extents(label)
    ctx.move_to(cx - ext.width / 2 - ext.x_bearing, cy + 48)
    ctx.show_text(label)

    surface.write_to_png(output)


if __name__ == '__main__':
    value   = float(sys.argv[1])
    min_val = float(sys.argv[2]) if len(sys.argv) > 2 else 0
    max_val = float(sys.argv[3]) if len(sys.argv) > 3 else 100
    label   = sys.argv[4]        if len(sys.argv) > 4 else ""
    output  = sys.argv[5]        if len(sys.argv) > 5 else "/tmp/gauge.png"
    draw_gauge(value, min_val, max_val, label, output)
