#!/usr/bin/env python3
"""A mechanical first pass for sideways truncation. One definition, two callers.

Every screen in this app keeps `Metrics.screenMargin` (20 pt) of clear space between
content and the bezel. So the question worth asking of a screenshot is not "what
colour is the edge pixel" but "is the margin strip *uniform* at this height" — content
that spills into the margin varies across the strip, and a full-width band painted by
the design does not.

**That distinction is the whole point, and the earlier version got it wrong** (HL-039).
It compared the edge pixel against `Palette.screen` with a tolerance, which meant the
pinned Start-slab bar — `Palette.raised` plus the slab's ember glow, legitimately
edge to edge — read as a violation on **every dark screenshot ever taken**. In light
the same band sits within tolerance because `raised` is a 1.09:1 step there against a
much larger one in dark, so the noise appeared only in the appearance this app calls
primary. A check that cries wolf on every run in its most important mode is not a
check. Uniformity has no such blind spot: it does not care what colour the band is.

This is still a *proxy*, not a gate. It never fails, and it is not the check — a person
looking at the screenshots is the check. It exists so that a run of twenty-four images
tells you which three to look at first.

**What it still cannot tell apart, stated rather than tuned away.** A soft gradient in
the margin varies exactly like an intruding glyph does. The Start slab's ember glow and
the toolbar's pill both sit within a few percent of the bezel in dark, so dark runs
carry a residue of CHECK lines that are the design working correctly. The tempting fix
— narrow the strip, raise the cutoff, lift the tolerance until the run is green — would
buy silence by removing the only rows where a real violation would show. Two findings in
this repo (F-0032, F-0036) were closed as "exonerated, not confirmed" for the same
reason: a measurement you tune until it agrees with you has stopped being one.

Usage: edge-scan.py <run-directory>

Scans `<run-directory>/shots/<label>/<state>.png` for any label shape;
`scripts/pseudo-check.sh` uses `dark/`, `scripts/walk-gates.sh` uses `dark-axl/`.
"""

import glob
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("  (PIL not available — skipping the automated pass; look at the screenshots directly)")
    sys.exit(0)

# `Metrics.screenMargin` is 20 pt against a 402 pt-wide device — just under 5% of the
# width. Sampled a little narrower so the strip stays clear of content that begins
# exactly at the margin.
MARGIN_FRACTION = 0.045

# Per-channel spread across the strip that counts as "something is in here". Generous:
# gradients, the slab's glow and JPEG-ish simulator artefacts all vary slightly, and a
# glyph intruding into the margin varies a great deal more.
SPREAD_TOLERANCE = 30

# The bezel's own antialiasing and the device's rounded corners are furniture.
EDGE_INSET = 2


def strip_spread(px, x0: int, x1: int, y: int) -> int:
    """Largest per-channel difference across one horizontal run of pixels."""
    lo = [255, 255, 255]
    hi = [0, 0, 0]
    for x in range(x0, x1):
        pixel = px[x, y]
        for c in range(3):
            if pixel[c] < lo[c]:
                lo[c] = pixel[c]
            if pixel[c] > hi[c]:
                hi[c] = pixel[c]
    return max(hi[c] - lo[c] for c in range(3))


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: edge-scan.py <run-directory>", file=sys.stderr)
        return 2
    run = sys.argv[1]
    paths = sorted(glob.glob(os.path.join(run, "shots", "*", "*.png")))
    if not paths:
        print(f"  (no screenshots under {run}/shots)")
        return 0

    for path in paths:
        directory = os.path.dirname(path)
        img = Image.open(path).convert("RGB")
        w, h = img.size
        px = img.load()
        strip = max(int(w * MARGIN_FRACTION), EDGE_INSET + 4)
        # Clear of the status bar / Dynamic Island (top) and the home indicator
        # (bottom), both of which are furniture rather than content.
        top = int(h * 0.08)
        bottom = int(h * 0.97)

        worst = 0
        worst_y = None
        hits = 0
        for y in range(top, bottom, 4):
            for x0, x1 in ((EDGE_INSET, strip), (w - strip, w - EDGE_INSET)):
                spread = strip_spread(px, x0, x1, y)
                if spread > SPREAD_TOLERANCE:
                    hits += 1
                    if spread > worst:
                        worst, worst_y = spread, y

        name = f"{os.path.basename(directory)}/{os.path.basename(path)}"
        if hits:
            print(f"  CHECK  {name}: {hits} row(s) with content in the margin strip; "
                  f"worst spread {worst} at y={worst_y} ({worst_y / h:.2f} of height)")
        else:
            print(f"  clear  {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
