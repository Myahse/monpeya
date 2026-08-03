import base64
import io
import re
from pathlib import Path

from PIL import Image

cards = Path(__file__).resolve().parents[1] / "assets/logo/cards"
svg_path = cards / "recto-carte-peya-pay.svg"
out_path = cards / "recto-carte-peya-pay.png"

text = svg_path.read_text(encoding="utf-8")
match = re.search(r"data:image/png;base64,([A-Za-z0-9+/=]+)", text)
if not match:
    raise SystemExit("No embedded PNG found in recto SVG")

img = Image.open(io.BytesIO(base64.b64decode(match.group(1)))).convert("RGBA")
print(f"recto source {img.size}")
# 4x of viewBox 376x237 for sharp phone displays
img = img.resize((1504, 948), Image.Resampling.LANCZOS)
img.save(out_path, format="PNG", optimize=True)
print(f"wrote {out_path} size={out_path.stat().st_size}")
