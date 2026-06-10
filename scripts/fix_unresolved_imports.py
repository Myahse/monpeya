#!/usr/bin/env python3
"""Resolve broken relative imports by filename lookup within package lib."""

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


def build_name_index(lib: Path) -> dict[str, str]:
    index: dict[str, str] = {}
    for f in lib.rglob("*.dart"):
        rel = f.relative_to(lib).as_posix()
        name = f.name
        if name not in index:
            index[name] = rel
    return index


def resolve_relative(importer: Path, uri: str, lib: Path) -> Path | None:
    if uri.startswith("./"):
        return (importer.parent / uri[2:]).resolve()
    base = importer.parent.resolve()
    rest = uri
    while rest.startswith("../"):
        rest = rest[3:]
        base = base.parent
    return (base / rest).resolve()


def fix_file(path: Path, indices: dict[str, dict[str, str]]) -> bool:
    info = pkg_for_file(path)
    if not info:
        return False
    pkg, lib = info
    index = indices[pkg]
    text = path.read_text(encoding="utf-8")
    changed = False

    def repl(m: re.Match[str]) -> str:
        nonlocal changed
        kind, uri = m.group(1), m.group(2)
        if uri.startswith("dart:") or uri.startswith("package:"):
            return m.group(0)

        target = resolve_relative(path, uri, lib)
        if target and target.exists():
            rel = target.relative_to(lib.resolve()).as_posix()
            changed = True
            return f"{kind} 'package:{pkg}/{rel}';"

        name = Path(uri).name
        if name in index:
            changed = True
            return f"{kind} 'package:{pkg}/{index[name]}';"

        return m.group(0)

    new_text = IMPORT_EXPORT_RE.sub(repl, text)
    if changed:
        path.write_text(new_text, encoding="utf-8")
    return changed


def main() -> None:
    indices = {pkg: build_name_index(lib) for pkg, lib in PACKAGES.items()}
    total = 0
    for _ in range(3):
        for lib in PACKAGES.values():
            for f in sorted(lib.rglob("*.dart")):
                if fix_file(f, indices):
                    total += 1
    print(f"Fixed unresolved imports in {total} passes.")


if __name__ == "__main__":
    main()
