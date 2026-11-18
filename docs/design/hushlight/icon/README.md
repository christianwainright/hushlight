# Hushlight icon artwork

The app icon is a classic table lamp: an ivory and amber linen
shade with straight tapered sides and visible rims, a separate straight brass
stem, and a low round brass base. Warm light carries the Nightstand identity.
See [decision 0055](../../../decisions/0055-the-lamp-has-depth-and-a-base.md).
The four exports are integrated locally. Small-size browser previews, export
format checks, `./scripts/gate.sh` (including the app build), and all 21 DesignKit
tests pass. Christian accepted this artwork on 2026-09-05; no release was performed.

The three `source-*.png` files are the full-resolution artwork from the built-in
image generation tool, created 2026-09-05. The light and tinted versions are
referenced edits of the dark original. [prompts.md](prompts.md) records the exact
prompts. No external API key or CLI image generation was used.

Export the complete asset set from the repository root:

```sh
swift scripts/make-hushlight-icon.swift Hushlight/Assets.xcassets/AppIcon.appiconset/icon-1024.png
swift scripts/make-hushlight-icon.swift Hushlight/Assets.xcassets/AppIcon.appiconset/icon-1024-dark.png --layer dark
swift scripts/make-hushlight-icon.swift Hushlight/Assets.xcassets/AppIcon.appiconset/icon-1024-tinted.png --layer tinted
swift scripts/make-hushlight-icon.swift Hushlight/Assets.xcassets/AppIcon.appiconset/icon-1024-marketing.png --layer marketing
```

The exporter converts the saved artwork to 1024×1024 opaque sRGB PNGs. Dark and
marketing use the same source. Outer corners stay square for the system mask.
These flattened masters contain no editable lighting or foreground layers.

`preview.html` shows the previous dark icon next to the replacement, the three
appearance variants, and small-size previews. It is a visual review aid; the
actual system tint and mask still depend on the user's home-screen settings.
