# Info Space logo usage

The logo is a compact metal information tray with adjustable dividers and four colored paper stacks. It reflects the SDK's resizable information panels. The artwork uses continuous metal and paper materials.

The owner approved the untouched native 2048 × 2048 GPT Image 2 image on 2026-09-09 and authorized full replacement. [The Hexly study](https://github.com/nocoo/hexly.ai/tree/main/artwork/logo-family/infospace/2026-09-09-01) preserves the exact generation, prompt, references, decision, measured extraction, palette and finishing `01`. The previous `logo.svg` is retained in git history.

## Asset roles

| File | Use |
| --- | --- |
| `../../logo.png` | Canonical transparent foreground, 2048 × 2048 |
| `icon.png` | Square presentation with the independent paper field, panel outlines and shadow |
| `icon-rounded.png` | Rounded presentation used by both README headers |
| `macos-icon.png` | Whole rounded presentation at 824 px, centered in a transparent 1024 px platform canvas |
| `../../App/Resources/ToolbarMark.png` and `ToolbarMark@2x.png` | Transparent toolbar artwork at 22/44 px, displayed at 22 pt |
| `../../App/Resources/AppIcon.icns` | macOS application icon with standard 1x/2x representations |

Keep the complete selected placement and original colors. Small toolbar marks use the transparent foreground without an additional background or corner crop. Native application icons use the platform inset; that inset does not belong in the canonical foreground or README presentation.

The app's dark theme and white controls remain independent from the artwork palette. At small sizes, the four color blocks and divided silhouette carry recognition; paper grain and metal machining detail merge.

## Rebuilding consumers

After replacing the three exact master files with an approved selection, run from the repository root:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift scripts/generate-icons.swift
```

The script uses native Core Graphics and ImageIO to preserve alpha and resize the complete canvas. It creates the transparent toolbar images, native inset master and all ICNS representations, retaining its temporary iconset inputs for inspection. It needs no third-party image dependency.

These resources belong only to the demo executable. SwiftPM resolves them through `Bundle.module` and sets its runtime Dock icon; the Xcode app uses `Bundle.main` and `CFBundleIconFile`. Core and UI library consumers do not inherit a demo logo.

The toolbar loads its native `NSImage` through AppKit's bundle lookup. This handles SwiftPM's PNG pair and the multi-resolution TIFF produced by Xcode's resource build phase. Both native launch paths were checked in real windows after adoption; the README screenshot shows the new transparent toolbar mark.

Exact master hashes and source provenance are recorded in [provenance.json](provenance.json). The complete before/after comparison is available at [hexly.ai/logos/infospace](https://hexly.ai/logos/infospace).
