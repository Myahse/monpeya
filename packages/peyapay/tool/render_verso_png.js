const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

function loadResvg() {
  try {
    return require("@resvg/resvg-js").Resvg;
  } catch (_) {
    console.log("Installing @resvg/resvg-js...");
    execSync("npm install --no-save @resvg/resvg-js", {
      cwd: __dirname,
      stdio: "inherit",
    });
    return require("@resvg/resvg-js").Resvg;
  }
}

const Resvg = loadResvg();
const cardsDir = path.resolve(__dirname, "../assets/logo/cards");
const svgPath = path.join(cardsDir, "verso.svg");
const outPath = path.join(cardsDir, "verso.png");

const svg = fs.readFileSync(svgPath);
const resvg = new Resvg(svg, {
  fitTo: { mode: "width", value: 1436 }, // 4x of 359 for sharp phones
  background: "rgba(0,0,0,0)",
});
const png = resvg.render().asPng();
fs.writeFileSync(outPath, png);
console.log(`wrote ${outPath} bytes=${png.length}`);
