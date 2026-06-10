#!/usr/bin/env python3
"""
Rename Dart files to {name}.{kind}.dart inside kind folders across the monorepo.

Examples:
  home_screen.dart           -> screens/home.screen.dart
  app_stack_types.dart       -> types/app_stack.types.dart
  auth_store.dart            -> storage/auth.store.dart
  screens/foo.dart (in screens/) -> screens/foo.screen.dart
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

LIB_ROOTS = [
    ROOT / "app" / "lib",
    ROOT / "packages" / "immo" / "lib",
    ROOT / "packages" / "peyapay" / "lib",
    ROOT / "packages" / "billetterie" / "lib",
]

# suffix (after last _) -> folder name
SUFFIX_TO_FOLDER: dict[str, str] = {
    "screen": "screens",
    "screens": "services",
    "service": "services",
    "types": "types",
    "type": "types",
    "navigation": "navigation",
    "navigator": "navigation",
    "tab": "navigation",
    "controller": "controllers",
    "adapter": "adapters",
    "registry": "registries",
    "bridge": "host",
    "theme": "themes",
    "config": "config",
    "store": "storage",
    "session": "auth",
    "scope": "scopes",
    "wizard": "wizards",
    "repository": "repositories",
    "resolver": "resolvers",
    "merger": "mergers",
    "module": "modules",
    "modules": "modules",
    "endpoints": "config",
    "prefs": "constants",
    "paths": "constants",
    "keys": "constants",
    "brand": "constants",
    "assets": "constants",
    "auth": "auth",
    "client": "services",
    "payment": "services",
    "events": "datasources",
    "draft": "models",
    "item": "models",
    "tenant": "models",
    "contract": "models",
    "message": "models",
    "property": "models",
    "event": "models",
    "ticket": "models",
    "site": "models",
    "response": "models",
    "helper": "utils",
    "insets": "utils",
    "formatters": "utils",
    "icon": "widgets",
    "scaffold": "widgets",
    "shell": "widgets",
    "sheet": "widgets",
    "keypad": "widgets",
    "bar": "widgets",
    "card": "widgets",
    "carousel": "widgets",
    "gate": "widgets",
    "grid": "widgets",
    "bubble": "widgets",
    "layout": "widgets",
    "widgets": "widgets",
    "stub": "widgets",
    "panel": "widgets",
    "button": "widgets",
    "states": "widgets",
    "confirm": "widgets",
    "dialog": "widgets",
    "animations": "widgets",
    "stack": "widgets",
    "badge": "widgets",
    "preview": "widgets",
}

# parent folder -> extension when filename has no recognized suffix
FOLDER_TO_EXT: dict[str, str] = {
    "screens": "screen",
    "services": "service",
    "models": "model",
    "widgets": "widget",
    "navigation": "navigation",
    "types": "types",
    "controllers": "controller",
    "adapters": "adapter",
    "registries": "registry",
    "themes": "theme",
    "config": "config",
    "constants": "constant",
    "utils": "util",
    "datasources": "datasource",
    "auth": "auth",
    "storage": "store",
    "scopes": "scope",
    "wizards": "wizard",
    "bridges": "bridge",
    "host": "bridge",
    "repositories": "repository",
    "resolvers": "resolver",
    "mergers": "merger",
    "modules": "module",
    "presentation": "presentation",
}

SKIP_NAMES = {
    "main",
    "app",
    "peyapay",
    "immo",
    "billetterie",
    "rental",
    "construction",
    "collection",
    "shared",
    "routes",
}

STRONG_SUFFIXES = {
    "screen",
    "screens",
    "service",
    "types",
    "type",
    "controller",
    "adapter",
    "registry",
    "bridge",
    "navigation",
    "navigator",
    "tab",
    "store",
    "session",
    "scope",
    "theme",
    "config",
    "repository",
    "endpoints",
    "wizard",
    "module",
    "modules",
    "merger",
    "resolver",
    "prefs",
    "paths",
    "keys",
    "brand",
    "assets",
    "auth",
    "client",
    "payment",
    "events",
    "draft",
    "item",
    "tenant",
    "contract",
    "message",
    "property",
    "event",
    "ticket",
    "site",
    "response",
}


def is_skipped(path: Path) -> bool:
    if path.name in ("main.dart", "app.dart"):
        return True
    if path.stem in SKIP_NAMES:
        return True
    return False


def match_longest_suffix(stem: str) -> tuple[str, str] | None:
    for suffix in sorted(SUFFIX_TO_FOLDER, key=len, reverse=True):
        token = f"_{suffix}"
        if stem.endswith(token):
            return stem[: -len(token)], suffix
    return None


def already_dot_named(stem: str) -> bool:
    return bool(re.search(r"\.[a-z]+$", stem))


def classify(path: Path) -> tuple[str, str, str] | None:
    """Return (base_name, kind, folder) or None to skip."""
    stem = path.stem
    parent_name = path.parent.name

    if already_dot_named(stem):
        return None

    matched = match_longest_suffix(stem)
    if parent_name in FOLDER_TO_EXT:
        ext = FOLDER_TO_EXT[parent_name]
        if matched is None or matched[1] not in STRONG_SUFFIXES:
            return stem, ext, parent_name

    if matched:
        base, suffix = matched
        folder = SUFFIX_TO_FOLDER[suffix]
        if suffix == "bridge" and parent_name == "host":
            folder = "host"
        return base, suffix, folder

    return None


def target_path(path: Path, base: str, kind: str, folder: str) -> Path:
    parent = path.parent
    if parent.name == folder:
        scope = parent.parent
    else:
        scope = parent
    new_name = f"{base}.{kind}.dart"
    return scope / folder / new_name


def collect_moves() -> dict[Path, Path]:
    moves: dict[Path, Path] = {}
    for lib_root in LIB_ROOTS:
        if not lib_root.exists():
            continue
        for path in sorted(lib_root.rglob("*.dart")):
            if is_skipped(path):
                continue
            classified = classify(path)
            if not classified:
                continue
            base, kind, folder = classified
            dst = target_path(path, base, kind, folder)
            if dst == path:
                continue
            if dst in moves.values():
                raise RuntimeError(f"Collision for {dst} from {path}")
            moves[path] = dst
    return moves


def git_mv(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        raise FileExistsError(dst)
    subprocess.run(["git", "mv", str(src), str(dst)], cwd=ROOT, check=True)


def apply_moves(moves: dict[Path, Path]) -> None:
    # deepest paths first to avoid directory issues
    for src in sorted(moves, key=lambda p: len(p.parts), reverse=True):
        dst = moves[src]
        if not src.exists():
            continue
        try:
            git_mv(src, dst)
        except subprocess.CalledProcessError:
            dst.parent.mkdir(parents=True, exist_ok=True)
            src.rename(dst)


def build_import_replacements(moves: dict[Path, Path]) -> list[tuple[str, str]]:
    reps: list[tuple[str, str]] = []
    for src, dst in moves.items():
        src_rel = src.as_posix()
        dst_rel = dst.as_posix()

        # package: imports — derive from lib/
        for lib_root in LIB_ROOTS:
            lib_pos = lib_root.as_posix() + "/"
            if src_rel.startswith(lib_pos):
                pkg_suffix_old = src_rel.split("/lib/", 1)[1]
                pkg_suffix_new = dst_rel.split("/lib/", 1)[1]
                if "app" in lib_root.as_posix():
                    pkg = "app"
                elif "immo" in lib_root.as_posix():
                    pkg = "immo"
                elif "peyapay" in lib_root.as_posix():
                    pkg = "peyapay"
                else:
                    pkg = "billetterie"
                reps.append((f"package:{pkg}/{pkg_suffix_old}", f"package:{pkg}/{pkg_suffix_new}"))
                break

        reps.append((src.name, dst.name))
        # relative import paths (posix)
        old_parts = src.parts
        new_parts = dst.parts
        reps.append(("/".join(old_parts[-3:]), "/".join(new_parts[-3:])))
        reps.append(("/".join(old_parts[-2:]), "/".join(new_parts[-2:])))

    # longest first
    reps = sorted(set(reps), key=lambda x: len(x[0]), reverse=True)
    return reps


def update_imports(moves: dict[Path, Path]) -> None:
    reps = build_import_replacements(moves)
    for lib_root in LIB_ROOTS:
        if not lib_root.exists():
            continue
        for file in lib_root.rglob("*.dart"):
            text = file.read_text(encoding="utf-8")
            new = text
            for old, new_val in reps:
                new = new.replace(old, new_val)
            if new != text:
                file.write_text(new, encoding="utf-8")


def cleanup_empty_dirs() -> None:
    for lib_root in LIB_ROOTS:
        if not lib_root.exists():
            continue
        for d in sorted(lib_root.rglob("*"), key=lambda p: len(p.parts), reverse=True):
            if d.is_dir() and not any(d.iterdir()):
                d.rmdir()


def main() -> None:
    moves = collect_moves()
    print(f"Planned moves: {len(moves)}")
    for src, dst in sorted(moves.items())[:15]:
        print(f"  {src.relative_to(ROOT)} -> {dst.relative_to(ROOT)}")
    if len(moves) > 15:
        print(f"  ... and {len(moves) - 15} more")

    apply_moves(moves)
    update_imports(moves)
    cleanup_empty_dirs()
    print("Done.")


if __name__ == "__main__":
    main()
