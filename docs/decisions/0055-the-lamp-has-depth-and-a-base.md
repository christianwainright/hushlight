# 0055 · The lamp has depth and a base

**Date:** 2026-09-05 · **Item:** HL-042 · **Status:** accepted and implemented · **Supersedes:** 0052's geometry and rendering method

Christian requested an app review and a better icon. The screenshots, palette and
timer interaction support the Nightstand identity: warm light and a calm, direct
instrument for the night labor starts. The previous icon's tall trapezoid and tiny
base lose the lamp's identifying features; the broad halo softens the background
without adding much light to the object.

Christian rejected the first generated dome design because it looked like a
mushroom. The replacement uses a classic table lamp: an ivory and amber
linen shade shaped as a truncated cone, with straight tapered sides, visible top
and lower rims, a separate straight brass stem, and a low round brass base. Warm
light gives the shade depth against a dark background. The shade, stem and base
remain legible in the 29-, 40- and 60-pixel browser previews across all three
appearances. Christian accepted the revision and requested it replace the icon
and be committed onto `main`.

Three raster masters are versioned in `docs/design/hushlight/icon/`, generated
with the built-in image tool. The dark master establishes the shape; referenced
edits produce the paper-background daytime and neutral tinted companions. The
exact prompts are recorded alongside them. These are intentionally rendered
artworks within the warm palette family, rather than drawings assembled from exact
UI token values. Palette changes now require an artwork review.

`scripts/make-hushlight-icon.swift` packages the masters as opaque 1024×1024 sRGB
PNGs. It preserves the appearance CLI and the separate dark marketing file from
0035. It no longer invents foreground/background exports: a future Icon Composer
migration needs real separated artwork. Re-running packaging reproduces the saved
masters; re-running image generation is not a deterministic rebuild.

The no-text, no-red, no-fetus, no-flower, no-moon and no-monogram guardrails remain.
This changes local icon assets only. The previously uploaded App Store Connect
binary retains its existing artwork until a new build is uploaded.
