#!/usr/bin/env python3
"""
Generate macOS DocumentIcon.icns for Osh documents.
Extracts Apple's standard document sheet canvas from CoreTypes,
composites the Osh app badge and MARKDOWN label matching macOS HIG,
and compiles into DocumentIcon.icns using iconutil.
"""

import os
import shutil
import subprocess
import sys
import tempfile
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORETYPES_DOC = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns"
APP_ICON_1024 = os.path.join(REPO_ROOT, "Sources/OshApp/Assets.xcassets/AppIcon.appiconset/1024-mac.png")
OUTPUT_ICNS = os.path.join(REPO_ROOT, "Sources/OshApp/DocumentIcon.icns")

def main():
    if not os.path.exists(CORETYPES_DOC):
        print(f"Error: Base document icon not found at {CORETYPES_DOC}", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(APP_ICON_1024):
        print(f"Error: AppIcon not found at {APP_ICON_1024}", file=sys.stderr)
        sys.exit(1)

    temp_dir = tempfile.mkdtemp(prefix="osh_doc_icon_")
    try:
        generic_iconset = os.path.join(temp_dir, "generic.iconset")
        subprocess.run(["iconutil", "-c", "iconset", CORETYPES_DOC, "-o", generic_iconset], check=True)

        app_icon = Image.open(APP_ICON_1024).convert("RGBA")

        doc_iconset = os.path.join(temp_dir, "DocumentIcon.iconset")
        os.makedirs(doc_iconset, exist_ok=True)

        resolutions = [
            ("icon_16x16.png", 16, False),
            ("icon_16x16@2x.png", 32, False),
            ("icon_32x32.png", 32, False),
            ("icon_32x32@2x.png", 64, False),
            ("icon_128x128.png", 128, True),
            ("icon_128x128@2x.png", 256, True),
            ("icon_256x256.png", 256, True),
            ("icon_256x256@2x.png", 512, True),
            ("icon_512x512.png", 512, True),
            ("icon_512x512@2x.png", 1024, True),
        ]

        # Find SF Pro font or fallback
        font_path = None
        for fp in ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Helvetica.ttc", "/Library/Fonts/Arial.ttf"]:
            if os.path.exists(fp):
                font_path = fp
                break

        for filename, size, has_text in resolutions:
            base_file = os.path.join(generic_iconset, filename)
            sheet = Image.open(base_file).convert("RGBA")

            if has_text:
                badge_size = int(round(size * (390.0 / 1024.0)))
                badge_y = int(round(size * (500.0 / 1024.0)))
            else:
                badge_size = int(round(size * 0.48))
                badge_y = size // 2

            badge = app_icon.resize((badge_size, badge_size), Image.Resampling.LANCZOS)
            badge_x = (size - badge_size) // 2
            badge_y_pos = badge_y - badge_size // 2
            sheet.paste(badge, (badge_x, badge_y_pos), badge)

            if has_text and font_path:
                draw = ImageDraw.Draw(sheet)
                font_size = max(8, int(round(size * (76.0 / 1024.0))))
                font = ImageFont.truetype(font_path, font_size)
                spaced_text = " ".join(list("MARKDOWN"))
                bbox = draw.textbbox((0, 0), spaced_text, font=font)
                tw = bbox[2] - bbox[0]
                th = bbox[3] - bbox[1]
                tx = (size - tw) // 2
                ty = int(round(size * (850.0 / 1024.0))) - th // 2
                # Apple neutral document gray #B8B8B8
                draw.text((tx, ty), spaced_text, font=font, fill=(184, 184, 184, 255))

            sheet.save(os.path.join(doc_iconset, filename), "PNG")

        subprocess.run(["iconutil", "-c", "icns", doc_iconset, "-o", OUTPUT_ICNS], check=True)
        print(f"Successfully generated {OUTPUT_ICNS}")
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

if __name__ == "__main__":
    main()
