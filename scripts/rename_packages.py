#!/usr/bin/env python3
"""Rename mon_peya_* packages to short names: peyapay, immo, billetterie."""

from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

RENAMES = {
    "mon_peya_peyapay": "peyapay",
    "mon_peya_immo": "immo",
    "mon_peya_billetterie": "billetterie",
}

BARREL_RENAMES = {
    "mon_peya_peyapay.dart": "peyapay.dart",
    "mon_peya_immo.dart": "immo.dart",
    "mon_peya_billetterie.dart": "billetterie.dart",
}


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, cwd=ROOT, check=True)


def git_mv(src: Path, dst: Path) -> None:
    if not src.exists():
        return
    if dst.exists():
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    run(["git", "mv", str(src), str(dst)])


def rename_directories() -> None:
    for old, new in RENAMES.items():
        git_mv(ROOT / "packages" / old, ROOT / "packages" / new)


def rename_barrels() -> None:
    for old_pkg, new_pkg in RENAMES.items():
        lib = ROOT / "packages" / new_pkg / "lib"
        old_barrel = lib / f"{old_pkg}.dart"
        new_barrel = lib / BARREL_RENAMES[f"{old_pkg}.dart"]
        if old_barrel.exists() and not new_barrel.exists():
            git_mv(old_barrel, new_barrel)


def update_pubspec_names() -> None:
    for old, new in RENAMES.items():
        pub = ROOT / "packages" / new / "pubspec.yaml"
        if pub.exists():
            pub.write_text(pub.read_text(encoding="utf-8").replace(f"name: {old}", f"name: {new}"), encoding="utf-8")

    super_pub = ROOT / "app" / "pubspec.yaml"
    if super_pub.exists():
        text = super_pub.read_text(encoding="utf-8")
        for old, new in RENAMES.items():
            text = text.replace(f"  {old}:\n", f"  {new}:\n")
            text = text.replace(f"path: ../../packages/{old}", f"path: ../../packages/{new}")
        super_pub.write_text(text, encoding="utf-8")


def replace_in_tree(directory: Path, replacements: list[tuple[str, str]], globs: list[str] | None = None) -> None:
    globs = globs or ["*.dart", "*.yaml", "*.md", "*.py"]
    for pattern in globs:
        for file in directory.rglob(pattern):
            if any(p in file.parts for p in ("build", ".dart_tool", ".git")):
                continue
            text = file.read_text(encoding="utf-8")
            new = text
            for old, new_val in replacements:
                new = new.replace(old, new_val)
            if new != text:
                file.write_text(new, encoding="utf-8")


def update_imports() -> None:
    replacements: list[tuple[str, str]] = []
    for old, new in RENAMES.items():
        replacements.append((f"package:{old}/", f"package:{new}/"))
        replacements.append((f"packages/{old}/", f"packages/{new}/"))
        replacements.append((f"`{old}`", f"`{new}`"))
        replacements.append((f"name: {old}", f"name: {new}"))

    replace_in_tree(ROOT / "apps", replacements)
    replace_in_tree(ROOT / "packages", replacements)
    replace_in_tree(ROOT, replacements, ["*.md", "*.yaml", "*.py"])


def update_readme() -> None:
    readme = ROOT / "README.md"
    if not readme.exists():
        return
    text = readme.read_text(encoding="utf-8")
    text = text.replace("mon_peya_peyapay", "peyapay")
    text = text.replace("mon_peya_immo", "immo")
    text = text.replace("mon_peya_billetterie", "billetterie")
    readme.write_text(text, encoding="utf-8")


def main() -> None:
    print("Renaming package directories...")
    rename_directories()
    print("Renaming barrel files...")
    rename_barrels()
    print("Updating pubspec names...")
    update_pubspec_names()
    print("Updating imports and docs...")
    update_imports()
    update_readme()
    print("Done.")


if __name__ == "__main__":
    main()
