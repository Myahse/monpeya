#!/usr/bin/env python3
"""Complete partial monorepo migration (move remaining files)."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, cwd=ROOT, check=True)


def git_mv(src: Path, dst: Path) -> None:
    if not src.exists():
        return
    if dst.exists():
        if dst.is_dir() and not any(dst.iterdir()):
            dst.rmdir()
        elif dst.exists():
            return
    dst.parent.mkdir(parents=True, exist_ok=True)
    run(["git", "mv", str(src), str(dst)])


def remove_empty_dirs(path: Path) -> None:
    if not path.exists():
        return
    for child in sorted(path.rglob("*"), reverse=True):
        if child.is_dir() and not any(child.iterdir()):
            child.rmdir()


def complete_immo() -> None:
    lib = ROOT / "packages" / "mon_peya_immo" / "lib"
    empty_shared = lib / "src" / "shared"
    if empty_shared.exists() and not any(empty_shared.iterdir()):
        empty_shared.rmdir()
    git_mv(lib / "shared", lib / "src" / "shared")


def complete_super_app() -> None:
    lib = ROOT / "app" / "lib"
    src = lib / "src"

    # Remove empty placeholder dirs that blocked git mv
    for rel in [
        "core/routing",
        "core/storage",
        "core/widgets",
        "core/assets",
        "core/modules",
        "features/auth/presentation",
        "features/onboarding/presentation",
        "features/settings/presentation",
        "features/splash/presentation",
        "features/reset_pin/presentation",
    ]:
        p = src / rel
        if p.exists() and p.is_dir() and not any(p.iterdir()):
            p.rmdir()

    app = lib / "app"
    if app.exists():
        for sub in ["routing", "storage", "widgets", "assets", "modules"]:
            git_mv(app / sub, src / "core" / sub)
        if (app / "module_auth.dart").exists() and not (src / "core" / "module_auth.dart").exists():
            git_mv(app / "module_auth.dart", src / "core" / "module_auth.dart")
        if app.exists() and not any(app.iterdir()):
            app.rmdir()

    screens = lib / "screens"
    if screens.exists():
        simple_mapping = {
            "auth": src / "features" / "auth" / "presentation",
            "onboarding": src / "features" / "onboarding" / "presentation",
            "settings": src / "features" / "settings" / "presentation",
            "splash": src / "features" / "splash" / "presentation",
            "reset_pin": src / "features" / "reset_pin" / "presentation",
        }
        for name, dest in simple_mapping.items():
            git_mv(screens / name, dest)

        app_stack = screens / "app_stack"
        shell = src / "features" / "shell"
        if app_stack.exists():
            shell.mkdir(parents=True, exist_ok=True)
            for item in app_stack.iterdir():
                target = shell / item.name
                if item.name == "widgets" and target.exists():
                    for w in item.iterdir():
                        git_mv(w, target / w.name)
                    if not any(item.iterdir()):
                        item.rmdir()
                else:
                    git_mv(item, target)
            if app_stack.exists() and not any(app_stack.iterdir()):
                app_stack.rmdir()

        if screens.exists() and not any(screens.iterdir()):
            screens.rmdir()

    remove_empty_dirs(src)


def main() -> None:
    print("Completing immo shared move...")
    complete_immo()
    print("Completing super_app moves...")
    complete_super_app()
    print("Done.")


if __name__ == "__main__":
    main()
