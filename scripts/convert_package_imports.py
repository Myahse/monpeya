#!/usr/bin/env python3
"""Convert relative Dart imports/exports to package: URIs."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PACKAGES: dict[str, Path] = {
    "app": ROOT / "app" / "lib",
    "immo": ROOT / "packages" / "immo" / "lib",
    "peyapay": ROOT / "packages" / "peyapay" / "lib",
    "billetterie": ROOT / "packages" / "billetterie" / "lib",
}

IMPORT_EXPORT_RE = re.compile(r"^(import|export)\s+'([^']+)';", re.MULTILINE)


def pkg_for_file(path: Path) -> tuple[str, Path] | None:
    for pkg, lib in PACKAGES.items():
        try:
            path.resolve().relative_to(lib.resolve())
            return pkg, lib
        except ValueError:
            continue
    return None


def resolve_uri(importer: Path, uri: str, pkg: str, lib: Path) -> str:
    if uri.startswith("dart:"):
        return uri
    if uri.startswith("package:"):
        return uri

    if uri == "app.dart" and pkg == "app":
        return "package:app/app.dart"

    if uri.startswith("./"):
        target = (importer.parent / uri[2:]).resolve()
    else:
        base = importer.parent.resolve()
        rest = uri
        while rest.startswith("../"):
            rest = rest[3:]
            base = base.parent
        target = (base / rest).resolve()

    rel = target.relative_to(lib.resolve()).as_posix()
    return f"package:{pkg}/{rel}"


def process_file(path: Path) -> bool:
    info = pkg_for_file(path)
    if info is None:
        return False
    pkg, lib = info
    text = path.read_text(encoding="utf-8")
    changed = False

    def repl(m: re.Match[str]) -> str:
        nonlocal changed
        kind, uri = m.group(1), m.group(2)
        if uri.startswith("dart:") or uri.startswith("package:"):
            return m.group(0)
        new_uri = resolve_uri(path, uri, pkg, lib)
        target = lib / new_uri.split(f"package:{pkg}/", 1)[1]
        if not target.exists():
            return m.group(0)
        if new_uri != uri:
            changed = True
        return f"{kind} '{new_uri}';"

    new_text = IMPORT_EXPORT_RE.sub(repl, text)
    if changed:
        path.write_text(new_text, encoding="utf-8")
    return changed


def fix_barrels() -> None:
    (ROOT / "packages/peyapay/lib/peyapay.dart").write_text(
        """/// Peya Pay — wallet module for Mon Peya / N'TERI.
library;

export 'src/core/host/peyapay_host.bridge.dart';
export 'src/core/constants/peya_pay.assets.dart';
export 'src/core/utils/formatters.util.dart';
export 'src/core/utils/screen_insets.util.dart';
export 'src/data/models/fund_source.item.dart';
export 'src/data/models/transaction.item.dart';
export 'src/presentation/screens/peyapay_add_money.screen.dart';
export 'src/presentation/screens/peyapay_review_transfer.screen.dart';
export 'src/presentation/screens/peyapay.screen.dart';
export 'src/presentation/widgets/peyapay_review_animations.widget.dart';
export 'src/presentation/widgets/review_transfer_sheet.widget.dart';
""",
        encoding="utf-8",
    )

    app_module = ROOT / "app/lib/src/core/modules/app.module.dart"
    text = app_module.read_text(encoding="utf-8")
    text = text.replace("import 'package:app/src/core/modules/app.module.dart';\n\n", "")
    app_module.write_text(text, encoding="utf-8")


def main() -> None:
    fix_barrels()
    count = 0
    for lib in PACKAGES.values():
        for f in sorted(lib.rglob("*.dart")):
            if process_file(f):
                count += 1
    # second pass for chained fixes
    for lib in PACKAGES.values():
        for f in sorted(lib.rglob("*.dart")):
            process_file(f)
    print(f"Converted imports in {count} files.")


if __name__ == "__main__":
    main()
