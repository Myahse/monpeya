const fs = require("fs");
const path = require("path");

async function main() {
  let Resvg;
  try {
    ({ Resvg } = require("@resvg/resvg-js"));
  } catch (_) {
    console.error("Installing @resvg/resvg-js locally...");
    const { execSync } = require("child_process");
    execSync("npm install --no-save @resvg/resvg-js", {
      cwd: __dirname,
      stdio: "inherit",
    });
    ({ Resvg } = require("@resvg/resvg-js"));
  }

  const cardsDir = path.resolve(__dirname, "../assets/logo/cards");
  const jobs = [
    { svg: "verso.svg", png: "verso.png", width: 1436 }, // 4x of 359
    // recto SVG has embedded raster; still render vector overlays at high res if pure vector fails we skip
  ];

  for (const job of jobs) {
    const svgPath = path.join(cardsDir, job.svg);
    const outPath = path.join(cardsDir, job.png);
    if (!fs.existsSync(svgPath)) {
      console.warn("missing", svgPath);
      continue;
    }
    const svg = fs.readFileSync(svgPath);
    const resvg = new Resvg(svg, {
      fitTo: { mode: "width", value: job.width },
      background: "rgba(0,0,0,0)",
    });
    const pngData = resvg.render().asPng();
    fs.writeFileSync(outPath, pngData);
    console.log(
      `wrote ${outPath} bytes=${pngData.length} width=${job.width}`
    );
  }

  // Also rebuild recto from embedded high-res PNG inside the SVG.
  const { spawnSync } = require("child_process");
  const py = `
import base64, io, re
from pathlib import Path
from PIL import Image
svg = Path(r"${cardsDir.replace(/\\/g, "/")}/recto-carte-peya-pay.svg")
out = Path(r"${cardsDir.replace(/\\/g, "/")}/recto-carte-peya-pay.png")
text = svg.read_text(encoding="utf-8")
m = re.search(r"data:image/png;base64,([A-Za-z0-9+/=]+)", text)
if not m:
    raise SystemExit("no embedded png in recto svg")
img = Image.open(io.BytesIO(base64.b64decode(m.group(1)))).convert("RGBA")
print("recto source", img.size)
# 4x of viewBox 376x237
img = img.resize((1504, 948), Image.Resampling.LANCZOS)
img.save(out, format="PNG", optimize=True)
print("wrote", out, out.stat().st_size)
`;
  const result = spawnSync("python", ["-c", py], { encoding: "utf-8" });
  process.stdout.write(result.stdout || "");
  process.stderr.write(result.stderr || "");
  if (result.status !== 0) process.exit(result.status || 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
