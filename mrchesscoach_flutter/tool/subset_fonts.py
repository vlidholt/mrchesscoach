"""Builds the app's bundled fonts in assets/fonts: static weights, Latin
subset, no hinting.

Usage: python3 tool/subset_fonts.py <source dir> assets/fonts

The source dir holds the upstream files from https://github.com/google/fonts
(ofl/manrope, ofl/cormorantgaramond, ofl/ibmplexmono): Manrope[wght].ttf,
CormorantGaramond[wght].ttf, CormorantGaramond-Italic[wght].ttf,
IBMPlexMono-Medium.ttf and IBMPlexMono-Bold.ttf. Needs fonttools.
"""
import os, sys
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset

src, out = sys.argv[1], sys.argv[2]
# Latin + Latin-1, the punctuation and arrows the app uses. Rarer characters
# fall back to the platform (or Noto on the web).
U = ("U+0020-007E,U+00A0-00FF,U+0131,U+0152-0153,U+2013-2014,U+2018-201A,"
     "U+201C-201E,U+2022,U+2026,U+2030,U+2039-203A,U+20AC,U+2122,"
     "U+2190-2193,U+2212,U+2248")
jobs = [("Manrope[wght].ttf", w, f"Manrope-{n}.ttf") for w, n in
        [(400, "Regular"), (500, "Medium"), (600, "SemiBold"), (700, "Bold"), (800, "ExtraBold")]]
jobs += [
    ("CormorantGaramond[wght].ttf", 700, "CormorantGaramond-Bold.ttf"),
    ("CormorantGaramond-Italic[wght].ttf", 600, "CormorantGaramond-SemiBoldItalic.ttf"),
    ("IBMPlexMono-Medium.ttf", None, "IBMPlexMono-Medium.ttf"),
    ("IBMPlexMono-Bold.ttf", None, "IBMPlexMono-Bold.ttf"),
]
opts = subset.Options()
opts.unicodes = subset.parse_unicodes(U)
opts.layout_features = ["kern", "liga", "ccmp", "locl", "mark", "mkmk"]
opts.hinting = False
opts.name_IDs = [0, 1, 2, 3, 4, 5, 6]
opts.name_languages = [0x409]
opts.glyph_names = False
opts.drop_tables += ["DSIG", "STAT", "meta"]
total = 0
for name, weight, dst in jobs:
    font = TTFont(os.path.join(src, name))
    if weight is not None:
        font = instantiateVariableFont(font, {"wght": weight})
        font["OS/2"].usWeightClass = weight
    s = subset.Subsetter(opts)
    s.populate(unicodes=opts.unicodes)
    s.subset(font)
    path = os.path.join(out, dst)
    font.save(path)
    size = os.path.getsize(path)
    total += size
    print(f"{dst:40s} {size / 1024:6.1f} KB")
print(f"total {total / 1024:.1f} KB")
