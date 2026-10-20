"""Carton Sans: Inter (rsms/inter, SIL Open Font License 1.1), renamed.
A plain screen sans between San Francisco, Helvetica and Lato, which is the brief (Joshua, 2026-10-20: "just basic
sans serif"). Figures are proportional by default. Same method as Quip Sans and Samantha Sans: pinned release,
renamed, OFL shipped beside the fonts, original copyright kept in the name table. Latin only, same bytes every build.

    uv run --with fonttools --with brotli scripts/gen_font.py           # fonts/CartonSans-{Regular,Medium,Semibold,Bold}.{ttf,woff2} + OFL.txt
    uv run --with fonttools --with brotli scripts/gen_font.py --check   # named Carton Sans, OFL present, proportional, I l 1 O 0 distinct
"""
import io
import os
import sys
import urllib.request

from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "fonts")
SOURCE = "https://cdn.jsdelivr.net/npm/@fontsource/inter@5.3.0/"
WEIGHTS = {"Regular": 400, "Medium": 500, "Semibold": 600, "Bold": 700}


def fetch(path):
    """Bytes of one file from the pinned release."""
    with urllib.request.urlopen(SOURCE + path, timeout=60) as r:
        return r.read()


def rename(font, style):
    """Give the outlines the Carton Sans name; copyright (0) and license (13, 14) stay as the authors wrote them."""
    names = {1: "Carton Sans", 2: style, 3: f"CartonSans-{style}", 4: f"Carton Sans {style}",
             5: "Version 1.000", 6: f"CartonSans-{style}", 16: "Carton Sans", 17: style}
    table = font["name"]
    table.names = [n for n in table.names if n.nameID in (0, 13, 14)]
    for nid, text in names.items():
        table.setName(text, nid, 3, 1, 0x409)
        table.setName(text, nid, 1, 0, 0)
    font["head"].created = font["head"].modified = 3_700_000_000   # fixed, so every build is the same bytes
    font["OS/2"].achVendID = "CRTN"


def to_bytes(font, flavor):
    font.flavor = flavor
    buf = io.BytesIO()
    font.save(buf, reorderTables=False)
    return buf.getvalue()


def check():
    """Self-check of the shipped files."""
    assert os.path.exists(os.path.join(OUT, "OFL.txt")), "the OFL must ship with the fonts"
    for style in WEIGHTS:
        for ext in ("ttf", "woff2"):
            f = TTFont(os.path.join(OUT, f"CartonSans-{style}.{ext}"))
            assert f["name"].getDebugName(1) == "Carton Sans" and f["name"].getDebugName(6) == f"CartonSans-{style}"
            assert f["name"].getDebugName(0), "the original copyright must stay in the name table"
            cmap = f.getBestCmap()
            assert all(ord(c) in cmap for c in "0123456789CARTONdays"), "missing glyphs the app uses"
            shapes = {f["glyf"][cmap[ord(c)]].coordinates.array.tobytes() for c in "Il1O0"}
            assert len(shapes) == 5, "two of I l 1 O 0 are drawn the same"
            hmtx = f["hmtx"]
            assert hmtx[cmap[ord("1")]][0] < hmtx[cmap[ord("0")]][0], "figures are not proportional"
            assert hmtx[cmap[ord("i")]][0] < hmtx[cmap[ord("m")]][0], "letters are not proportional"
            glyf = f["glyf"]
            assert len({glyf[cmap[ord(c)]].coordinates.array.tobytes() for c in "0123456789"}) == 10, "two digits drawn the same"
    print(f"font ok: Carton Sans (Inter, OFL), {len(WEIGHTS)} weights")


def main():
    if "--check" in sys.argv:
        return check()
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "OFL.txt"), "wb") as f:
        f.write(fetch("LICENSE"))
    for style, weight in WEIGHTS.items():
        font = TTFont(io.BytesIO(fetch(f"files/inter-latin-{weight}-normal.woff2")))
        rename(font, style)
        for ext, flavor in (("ttf", None), ("woff2", "woff2")):
            with open(os.path.join(OUT, f"CartonSans-{style}.{ext}"), "wb") as f:
                f.write(to_bytes(font, flavor))
        print(f"CartonSans-{style}: Inter {weight}")


if __name__ == "__main__":
    main()
