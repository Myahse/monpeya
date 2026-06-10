#!/usr/bin/env python3
"""Migrate Mon Peya to apps/packages monorepo with clean architecture layout."""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run(cmd: list[str], cwd: Path | None = None) -> None:
    subprocess.run(cmd, cwd=cwd or ROOT, check=True)


def git_mv(src: Path, dst: Path) -> None:
    if not src.exists():
        return
    if dst.exists():
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    run(["git", "mv", str(src), str(dst)])


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def replace_in_tree(directory: Path, replacements: list[tuple[str, str]], glob: str = "*.dart") -> None:
    for file in directory.rglob(glob):
        if "build" in file.parts or ".dart_tool" in file.parts:
            continue
        text = file.read_text(encoding="utf-8")
        new_text = text
        for old, new in replacements:
            new_text = new_text.replace(old, new)
        if new_text != text:
            file.write_text(new_text, encoding="utf-8")


def move_physical_layout() -> None:
    ensure_dir(ROOT / "apps")
    ensure_dir(ROOT / "packages")

    moves = [
        (ROOT / "mon_peya_super_app", ROOT / "app"),
        (ROOT / "peya_pay", ROOT / "packages" / "mon_peya_peyapay"),
        (ROOT / "mr_immo", ROOT / "packages" / "mon_peya_immo"),
        (ROOT / "billetterie_electronique", ROOT / "packages" / "mon_peya_billetterie"),
    ]
    for src, dst in moves:
        if src.exists() and not dst.exists():
            git_mv(src, dst)

    orphan_android = ROOT / "android"
    if orphan_android.exists():
        shutil.rmtree(orphan_android)


def restructure_peyapay() -> None:
    lib = ROOT / "packages" / "mon_peya_peyapay" / "lib"
    src = lib / "src"
    ensure_dir(src / "core")
    ensure_dir(src / "presentation" / "screens")
    ensure_dir(src / "presentation" / "widgets")

    for name in ["host", "screens", "widgets"]:
        p = lib / name
        if p.exists():
            if name == "host":
                git_mv(p, src / "core" / "host")
            elif name == "screens":
                for f in p.iterdir():
                    git_mv(f, src / "presentation" / "screens" / f.name)
                p.rmdir()
            elif name == "widgets":
                for f in p.iterdir():
                    git_mv(f, src / "presentation" / "widgets" / f.name)
                p.rmdir()

    if (lib / "peya_pay_assets.dart").exists():
        git_mv(lib / "peya_pay_assets.dart", src / "core" / "peya_pay_assets.dart")

    old_barrel = lib / "peya_pay.dart"
    if old_barrel.exists():
        old_barrel.unlink()

    write_text(
        lib / "mon_peya_peyapay.dart",
        """/// Peya Pay — wallet module for Mon Peya / N'TERI.
library;

export 'src/core/host/peyapay_host_bridge.dart';
export 'src/core/peya_pay_assets.dart';
export 'src/presentation/screens/peyapay_add_money_screen.dart';
export 'src/presentation/screens/peyapay_review_transfer_screen.dart';
export 'src/presentation/screens/peyapay_screen.dart';
export 'src/presentation/widgets/peyapay_review_animations.dart';
export 'src/presentation/widgets/review_transfer_sheet.dart';
""",
    )


def restructure_immo() -> None:
    lib = ROOT / "packages" / "mon_peya_immo" / "lib"
    src = lib / "src"
    ensure_dir(src / "core")
    ensure_dir(src / "features")

    for name in ["host", "shared", "rental", "construction", "collection"]:
        p = lib / name
        if not p.exists():
            continue
        if name == "host":
            git_mv(p, src / "core" / "host")
        elif name == "shared":
            git_mv(p, src / "shared")
        else:
            git_mv(p, src / "features" / name)

    for fname in ["immo_brand.dart", "immo_module_keys.dart"]:
        p = lib / fname
        if p.exists():
            git_mv(p, src / "core" / fname)

    old_barrel = lib / "mr_immo.dart"
    if old_barrel.exists():
        old_barrel.unlink()

    write_text(
        lib / "mon_peya_immo.dart",
        """/// Mon Peya Immo — rental, construction, collection modules.
library;

export 'src/features/collection/collection.dart';
export 'src/features/construction/construction.dart';
export 'src/core/host/immo_host_bridge.dart';
export 'src/core/immo_brand.dart';
export 'src/core/immo_module_keys.dart';
export 'src/features/rental/rental.dart';
export 'src/shared/shared.dart';
""",
    )


def restructure_billetterie() -> None:
    lib = ROOT / "packages" / "mon_peya_billetterie" / "lib"
    src = lib / "src"
    ensure_dir(src / "core" / "constants")
    ensure_dir(src / "data" / "datasources")
    ensure_dir(src / "data" / "models")
    ensure_dir(src / "data" / "services")
    ensure_dir(src / "presentation" / "screens")
    ensure_dir(src / "presentation" / "navigation")

    if (lib / "host").exists():
        git_mv(lib / "host", src / "core" / "host")
    if (lib / "constants").exists():
        for f in (lib / "constants").iterdir():
            git_mv(f, src / "core" / "constants" / f.name)
        (lib / "constants").rmdir()
    if (lib / "models").exists():
        for f in (lib / "models").iterdir():
            git_mv(f, src / "data" / "models" / f.name)
        (lib / "models").rmdir()
    if (lib / "data").exists():
        for f in (lib / "data").iterdir():
            git_mv(f, src / "data" / "datasources" / f.name)
        (lib / "data").rmdir()
    if (lib / "services").exists():
        for f in (lib / "services").iterdir():
            git_mv(f, src / "data" / "services" / f.name)
        (lib / "services").rmdir()
    if (lib / "screens").exists():
        for f in (lib / "screens").iterdir():
            git_mv(f, src / "presentation" / "screens" / f.name)
        (lib / "screens").rmdir()
    if (lib / "navigation").exists():
        git_mv(lib / "navigation", src / "presentation" / "navigation")

    for fname in ["billetterie_brand.dart", "billetterie_module_screen.dart"]:
        p = lib / fname
        if p.exists():
            git_mv(p, src / "presentation" / fname)

    old_barrel = lib / "billetterie_electronique.dart"
    if old_barrel.exists():
        old_barrel.unlink()

    write_text(
        lib / "mon_peya_billetterie.dart",
        """/// Mon Peya Billetterie — electronic ticketing module.
library;

export 'src/presentation/billetterie_brand.dart';
export 'src/presentation/billetterie_module_screen.dart';
export 'src/core/host/billetterie_host_bridge.dart';
""",
    )


def restructure_super_app() -> None:
    lib = ROOT / "app" / "lib"
    src = lib / "src"
    ensure_dir(src / "core" / "routing")
    ensure_dir(src / "core" / "storage")
    ensure_dir(src / "core" / "widgets")
    ensure_dir(src / "core" / "assets")
    ensure_dir(src / "core" / "modules")
    ensure_dir(src / "features" / "auth" / "presentation")
    ensure_dir(src / "features" / "onboarding" / "presentation")
    ensure_dir(src / "features" / "settings" / "presentation")
    ensure_dir(src / "features" / "splash" / "presentation")
    ensure_dir(src / "features" / "reset_pin" / "presentation")
    ensure_dir(src / "features" / "shell")
    ensure_dir(src / "integration" / "adapters")
    ensure_dir(src / "integration" / "registries")

    app = lib / "app"
    if app.exists():
        for sub in ["routing", "storage", "widgets", "assets", "modules"]:
            p = app / sub
            if p.exists():
                git_mv(p, src / "core" / sub)
        if (app / "module_auth.dart").exists():
            git_mv(app / "module_auth.dart", src / "core" / "module_auth.dart")
        if (app / "app.dart").exists():
            git_mv(app / "app.dart", lib / "app.dart")
        if app.exists() and not any(app.iterdir()):
            app.rmdir()

    modules = lib / "modules"
    if modules.exists():
        adapters = modules / "adapters"
        if adapters.exists():
            for f in adapters.iterdir():
                git_mv(f, src / "integration" / "adapters" / f.name)
            adapters.rmdir()
        for name in ["immo_module_registry.dart", "billetterie_module_registry.dart"]:
            p = modules / name
            if p.exists():
                git_mv(p, src / "integration" / "registries" / name)
        if modules.exists() and not any(modules.iterdir()):
            modules.rmdir()

    screens = lib / "screens"
    if screens.exists():
        mapping = {
            "auth": src / "features" / "auth" / "presentation",
            "onboarding": src / "features" / "onboarding" / "presentation",
            "settings": src / "features" / "settings" / "presentation",
            "splash": src / "features" / "splash" / "presentation",
            "reset_pin": src / "features" / "reset_pin" / "presentation",
            "app_stack": src / "features" / "shell",
        }
        for name, dest in mapping.items():
            p = screens / name
            if p.exists():
                git_mv(p, dest)
        if screens.exists() and not any(screens.iterdir()):
            screens.rmdir()

    gate = lib / "widgets" / "mon_peya_module_gate.dart"
    if gate.exists():
        ensure_dir(src / "features" / "shell" / "widgets")
        git_mv(gate, src / "features" / "shell" / "widgets" / "mon_peya_module_gate.dart")
    widgets_dir = lib / "widgets"
    if widgets_dir.exists() and not any(widgets_dir.iterdir()):
        widgets_dir.rmdir()

    write_text(
        lib / "main.dart",
        """import 'package:flutter/widgets.dart';

import 'app.dart';

void main() => runApp(const MonPeyaSuperApp());
""",
    )


def update_pubspecs() -> None:
    super_pub = ROOT / "app" / "pubspec.yaml"
    text = super_pub.read_text(encoding="utf-8")
    text = text.replace("path: ../mr_immo", "path: ../../packages/mon_peya_immo")
    text = text.replace("path: ../billetterie_electronique", "path: ../../packages/mon_peya_billetterie")
    text = text.replace("path: ../peya_pay", "path: ../../packages/mon_peya_peyapay")
    text = text.replace("  mr_immo:\n", "  immo:\n")
    text = text.replace("  billetterie_electronique:\n", "  billetterie:\n")
    text = text.replace("  peya_pay:\n", "  peyapay:\n")
    super_pub.write_text(text, encoding="utf-8")

    peyapay_pub = ROOT / "packages" / "mon_peya_peyapay" / "pubspec.yaml"
    text = peyapay_pub.read_text(encoding="utf-8").replace("name: peya_pay", "name: peyapay")
    peyapay_pub.write_text(text, encoding="utf-8")

    immo_pub = ROOT / "packages" / "mon_peya_immo" / "pubspec.yaml"
    text = immo_pub.read_text(encoding="utf-8").replace("name: mr_immo", "name: immo")
    immo_pub.write_text(text, encoding="utf-8")

    bille_pub = ROOT / "packages" / "mon_peya_billetterie" / "pubspec.yaml"
    text = bille_pub.read_text(encoding="utf-8").replace(
        "name: billetterie_electronique", "name: billetterie"
    )
    bille_pub.write_text(text, encoding="utf-8")


def fix_package_imports() -> None:
    replacements = [
        ("package:mr_immo/", "package:immo/"),
        ("package:billetterie_electronique/", "package:billetterie/"),
        ("package:peya_pay/", "package:peyapay/"),
        ("package:immo/host/", "package:immo/src/core/host/"),
        ("package:immo/shared/", "package:immo/src/shared/"),
        ("package:billetterie/host/", "package:billetterie/src/core/host/"),
        ("package:peyapay/host/", "package:peyapay/src/core/host/"),
        ("package:peyapay/screens/", "package:peyapay/src/presentation/screens/"),
        ("package:immo/immo_module_keys.dart", "package:immo/src/core/immo_module_keys.dart"),
        ("package:immo/mr_immo.dart", "package:immo/mon_peya_immo.dart"),
        ("package:billetterie/billetterie_electronique.dart", "package:billetterie/mon_peya_billetterie.dart"),
        ("package:peyapay/peya_pay.dart", "package:peyapay/mon_peya_peyapay.dart"),
    ]
    for base in [ROOT / "apps", ROOT / "packages"]:
        replace_in_tree(base, replacements)
        replace_in_tree(base, replacements, "*.yaml")
        replace_in_tree(base, replacements, "*.md")


def fix_immo_relative_imports() -> None:
    lib = ROOT / "packages" / "mon_peya_immo" / "lib"
    patterns = [
        (re.compile(r"import '\.\./\.\./host/immo_host_bridge\.dart';"), "import 'package:immo/src/core/host/immo_host_bridge.dart';"),
        (re.compile(r"import '\.\./\.\./\.\./host/immo_host_bridge\.dart';"), "import 'package:immo/src/core/host/immo_host_bridge.dart';"),
        (re.compile(r"import '\.\./\.\./immo_brand\.dart';"), "import 'package:immo/src/core/immo_brand.dart';"),
        (re.compile(r"import '\.\./\.\./\.\./immo_brand\.dart';"), "import 'package:immo/src/core/immo_brand.dart';"),
        (re.compile(r"import '\.\./\.\./\.\./\.\./immo_brand\.dart';"), "import 'package:immo/src/core/immo_brand.dart';"),
        (re.compile(r"import '\.\./shared/"), "import 'package:immo/src/shared/"),
        (re.compile(r"import '\.\./\.\./shared/"), "import 'package:immo/src/shared/"),
        (re.compile(r"import '\.\./\.\./\.\./shared/"), "import 'package:immo/src/shared/"),
        (re.compile(r"import '\.\./\.\./\.\./\.\./shared/"), "import 'package:immo/src/shared/"),
    ]
    for file in lib.rglob("*.dart"):
        text = file.read_text(encoding="utf-8")
        new = text
        for regex, repl in patterns:
            new = regex.sub(repl, new)
        # Fix unclosed quotes from shared replacement
        new = new.replace("package:immo/src/shared/", "package:immo/src/shared/")
        new = re.sub(
            r"import 'package:immo/src/shared/([^']+)'",
            r"import 'package:immo/src/shared/\1'",
            new,
        )
        if new != text:
            file.write_text(new, encoding="utf-8")

    # Fix shared internal imports
    replace_in_tree(
        lib,
        [
            ("import '../config/", "import 'package:immo/src/shared/config/"),
            ("import '../services/", "import 'package:immo/src/shared/services/"),
            ("import '../auth/", "import 'package:immo/src/shared/auth/"),
            ("import '../models/", "import 'package:immo/src/shared/models/"),
            ("import '../widgets/", "import 'package:immo/src/shared/widgets/"),
            ("import '../../shared/services/", "import 'package:immo/src/shared/services/"),
            ("import '../../shared/config/", "import 'package:immo/src/shared/config/"),
            ("import '../../shared/auth/", "import 'package:immo/src/shared/auth/"),
            ("import '../../shared/widgets/", "import 'package:immo/src/shared/widgets/"),
        ],
    )

    # Fix feature barrel exports
    for barrel in ["collection.dart", "construction.dart", "rental.dart", "shared.dart"]:
        for f in lib.rglob(barrel):
            text = f.read_text(encoding="utf-8")
            text = text.replace("export '", "export 'package:immo/src/")
            text = text.replace("package:immo/src/package:", "package:")
            # revert over-correction - simpler manual fix per barrel
            f.write_text(text, encoding="utf-8")


def fix_billetterie_imports() -> None:
    lib = ROOT / "packages" / "mon_peya_billetterie" / "lib"
    replace_in_tree(
        lib,
        [
            ("import '../host/", "import 'package:billetterie/src/core/host/"),
            ("import '../models/", "import 'package:billetterie/src/data/models/"),
            ("import '../services/", "import 'package:billetterie/src/data/services/"),
            ("import '../data/", "import 'package:billetterie/src/data/datasources/"),
            ("import '../constants/", "import 'package:billetterie/src/core/constants/"),
            ("import '../navigation/", "import 'package:billetterie/src/presentation/navigation/"),
            ("import '../screens/", "import 'package:billetterie/src/presentation/screens/"),
        ],
    )


def fix_peyapay_imports() -> None:
    lib = ROOT / "packages" / "mon_peya_peyapay" / "lib"
    replace_in_tree(
        lib,
        [
            ("import '../host/", "import 'package:peyapay/src/core/host/"),
            ("import '../screens/", "import 'package:peyapay/src/presentation/screens/"),
            ("import '../widgets/", "import 'package:peyapay/src/presentation/widgets/"),
        ],
    )


def fix_super_app_imports() -> None:
    lib = ROOT / "app" / "lib"
    mapping = {
        "import '../modules/adapters/": "import 'package:app/src/integration/adapters/",
        "import 'routing/routes.dart'": "import 'package:app/src/core/routing/routes.dart'",
        "import '../../app/routing/": "import 'package:app/src/core/routing/",
        "import '../../../app/routing/": "import 'package:app/src/core/routing/",
        "import '../../app/storage/": "import 'package:app/src/core/storage/",
        "import '../../../app/storage/": "import 'package:app/src/core/storage/",
        "import '../../app/assets/": "import 'package:app/src/core/assets/",
        "import '../../../app/assets/": "import 'package:app/src/core/assets/",
        "import '../../app/widgets/": "import 'package:app/src/core/widgets/",
        "import '../../../app/widgets/": "import 'package:app/src/core/widgets/",
        "import '../../app/modules/": "import 'package:app/src/core/modules/",
        "import '../../../app/modules/": "import 'package:app/src/core/modules/",
        "import '../app/modules/": "import 'package:app/src/core/modules/",
        "import '../app/storage/": "import 'package:app/src/core/storage/",
        "import '../../app/module_auth.dart'": "import 'package:app/src/core/module_auth.dart'",
        "import '../app/module_auth.dart'": "import 'package:app/src/core/module_auth.dart'",
        "import '../../modules/": "import 'package:app/src/integration/",
        "import '../../../modules/": "import 'package:app/src/integration/",
        "import '../../screens/app_stack/": "import 'package:app/src/features/shell/",
        "import '../screens/app_stack/": "import 'package:app/src/features/shell/",
        "import '../../screens/auth/": "import 'package:app/src/features/auth/presentation/",
        "import '../../screens/onboarding/": "import 'package:app/src/features/onboarding/presentation/",
        "import '../../screens/reset_pin/": "import 'package:app/src/features/reset_pin/presentation/",
        "import '../../screens/settings/": "import 'package:app/src/features/settings/presentation/",
        "import '../../screens/splash/": "import 'package:app/src/features/splash/presentation/",
        "import '../../../screens/settings/": "import 'package:app/src/features/settings/presentation/",
        "import '../../widgets/mon_peya_module_gate.dart'": "import 'package:app/src/features/shell/widgets/mon_peya_module_gate.dart'",
        "import '../../../widgets/mon_peya_module_gate.dart'": "import 'package:app/src/features/shell/widgets/mon_peya_module_gate.dart'",
        "import 'prefs_keys.dart'": "import 'package:app/src/core/storage/prefs_keys.dart'",
        "import 'app_module.dart'": "import 'package:app/src/core/modules/app_module.dart'",
        "import 'bundled_modules.dart'": "import 'package:app/src/core/modules/bundled_modules.dart'",
        "import 'module_api_config.dart'": "import 'package:app/src/core/modules/module_api_config.dart'",
        "import 'module_merger.dart'": "import 'package:app/src/core/modules/module_merger.dart'",
        "import 'module_url_resolver.dart'": "import 'package:app/src/core/modules/module_url_resolver.dart'",
        "import 'module_shell_theme.dart'": "import 'package:app/src/core/modules/module_shell_theme.dart'",
        "import 'module_icon.dart'": "import 'package:app/src/core/modules/module_icon.dart'",
        "import 'module_navigation.dart'": "import 'package:app/src/core/modules/module_navigation.dart'",
        "import '../../modules/billetterie_module_registry.dart'": "import 'package:app/src/integration/registries/billetterie_module_registry.dart'",
        "import '../../modules/immo_module_registry.dart'": "import 'package:app/src/integration/registries/immo_module_registry.dart'",
        "import '../modules/billetterie_module_registry.dart'": "import 'package:app/src/integration/registries/billetterie_module_registry.dart'",
        "import '../modules/immo_module_registry.dart'": "import 'package:app/src/integration/registries/immo_module_registry.dart'",
        "export 'package:mr_immo/": "export 'package:immo/",
        "export 'package:billetterie_electronique/": "export 'package:billetterie/",
        "export 'package:peya_pay/": "export 'package:peyapay/",
    }
    replace_in_tree(lib, list(mapping.items()))

    # routes.dart feature imports
    routes = lib / "src" / "core" / "routing" / "routes.dart"
    if routes.exists():
        text = routes.read_text(encoding="utf-8")
        text = text.replace(
            "import '../../screens/app_stack/app_stack_screen.dart'",
            "import 'package:app/src/features/shell/app_stack_screen.dart'",
        )
        text = text.replace(
            "import '../../screens/auth/login_pin/login_pin_screen.dart'",
            "import 'package:app/src/features/auth/presentation/login_pin/login_pin_screen.dart'",
        )
        text = text.replace(
            "import '../../screens/auth/phone_input/phone_input_screen.dart'",
            "import 'package:app/src/features/auth/presentation/phone_input/phone_input_screen.dart'",
        )
        text = text.replace(
            "import '../../screens/auth/registration_flow/registration_flow_screen.dart'",
            "import 'package:app/src/features/auth/presentation/registration_flow/registration_flow_screen.dart'",
        )
        text = text.replace(
            "import '../../screens/onboarding/onboarding_screen.dart'",
            "import 'package:app/src/features/onboarding/presentation/onboarding_screen.dart'",
        )
        text = text.replace(
            "import '../../screens/reset_pin/reset_pin_screen.dart'",
            "import 'package:app/src/features/reset_pin/presentation/reset_pin_screen.dart'",
        )
        text = text.replace(
            "import '../../screens/settings/settings_screen.dart'",
            "import 'package:app/src/features/settings/presentation/settings_screen.dart'",
        )
        text = text.replace(
            "import '../../screens/splash/splash_screen.dart'",
            "import 'package:app/src/features/splash/presentation/splash_screen.dart'",
        )
        routes.write_text(text, encoding="utf-8")

    app_dart = lib / "app.dart"
    if app_dart.exists():
        text = app_dart.read_text(encoding="utf-8")
        text = text.replace(
            "import '../modules/adapters/billetterie_host_adapter.dart'",
            "import 'package:app/src/integration/adapters/billetterie_host_adapter.dart'",
        )
        text = text.replace(
            "import '../modules/adapters/immo_host_adapter.dart'",
            "import 'package:app/src/integration/adapters/immo_host_adapter.dart'",
        )
        text = text.replace(
            "import '../modules/adapters/peyapay_host_adapter.dart'",
            "import 'package:app/src/integration/adapters/peyapay_host_adapter.dart'",
        )
        text = text.replace(
            "import 'routing/routes.dart'",
            "import 'package:app/src/core/routing/routes.dart'",
        )
        app_dart.write_text(text, encoding="utf-8")

    # module_auth internal
    module_auth = lib / "src" / "core" / "module_auth.dart"
    if module_auth.exists():
        text = module_auth.read_text(encoding="utf-8")
        text = text.replace("import 'routing/routes.dart'", "import 'package:app/src/core/routing/routes.dart'")
        text = text.replace("import 'storage/auth_store.dart'", "import 'package:app/src/core/storage/auth_store.dart'")
        module_auth.write_text(text, encoding="utf-8")

    # Update re-export screens
    for name, pkg in [
        ("mr_immo_screens.dart", "immo/immo.dart"),
        ("billetterie_screen.dart", "billetterie/billetterie.dart"),
    ]:
        f = lib / "src" / "features" / "shell" / "services" / name
        if f.exists():
            text = f.read_text(encoding="utf-8")
            if "export" in text:
                f.write_text(f"export 'package:{pkg}';\n", encoding="utf-8")

    peyapay_tab = lib / "src" / "features" / "shell" / "tabs" / "peyapay_screen.dart"
    if peyapay_tab.exists():
        peyapay_tab.write_text("export 'package:peyapay/mon_peya_peyapay.dart';\n", encoding="utf-8")

    test_file = ROOT / "app" / "test" / "widget_test.dart"
    if test_file.exists():
        text = test_file.read_text(encoding="utf-8")
        text = text.replace("package:app/app/app.dart", "package:app/app.dart")
        text = text.replace(
            "package:app/screens/onboarding/onboarding_screen.dart",
            "package:app/src/features/onboarding/presentation/onboarding_screen.dart",
        )
        text = text.replace(
            "package:app/screens/splash/splash_screen.dart",
            "package:app/src/features/splash/presentation/splash_screen.dart",
        )
        test_file.write_text(text, encoding="utf-8")


def fix_immo_barrel_exports() -> None:
    lib = ROOT / "packages" / "mon_peya_immo" / "lib"

    def fix_barrel(path: Path, prefix: str) -> None:
        if not path.exists():
            return
        lines = []
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip().startswith("export 'package:immo/src/"):
                lines.append(line)
            elif line.strip().startswith("export '"):
                rel = line.strip().removeprefix("export '").removesuffix("';")
                lines.append(f"export 'package:immo/src/{prefix}/{rel}';")
            else:
                lines.append(line)
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    fix_barrel(lib / "src" / "features" / "rental" / "rental.dart", "features/rental")
    fix_barrel(lib / "src" / "features" / "construction" / "construction.dart", "features/construction")
    fix_barrel(lib / "src" / "features" / "collection" / "collection.dart", "features/collection")
    fix_barrel(lib / "src" / "shared" / "shared.dart", "shared")


def create_melos_and_readme() -> None:
    write_text(
        ROOT / "melos.yaml",
        """name: mon_peya
repository: https://gitlab.com/djogana-pay/monpeya

packages:
  - app
  - packages/**

command:
  bootstrap:
    runPubGetInParallel: true
""",
    )

    write_text(
        ROOT / "README.md",
        """# Mon Peya

N'TERI super-app monorepo — Flutter clean architecture.

## Structure

```
Mon Peya/
├── apps/
│   └── super_app/              # Shell application (auth, navigation, module launcher)
├── packages/
│   ├── mon_peya_peyapay/       # Wallet & payments
│   ├── mon_peya_immo/          # Rental, construction, collection
│   └── mon_peya_billetterie/   # Electronic ticketing
├── melos.yaml
└── README.md
```

Each package follows clean architecture:

```
lib/
├── <package_name>.dart         # Public API
└── src/
    ├── core/                   # Config, host bridges, constants
    ├── data/                   # Models, datasources, repositories (where applicable)
    ├── domain/                 # Entities & contracts (future)
    └── presentation/           # Screens, widgets, navigation
        └── features/           # Feature modules (immo)
```

## Prerequisites

- Flutter SDK (Dart `^3.10.8`)
- Optional: [Melos](https://melos.invertase.dev/) for workspace management

## Run

```bash
cd app
flutter pub get
flutter run
```

Or with Melos:

```bash
dart pub global activate melos
melos bootstrap
cd app && flutter run
```

Optional API URLs:

```bash
flutter run \\
  --dart-define=IMMO_API_URL=http://YOUR_IP:8081 \\
  --dart-define=BILLETTERIE_API_URL=http://YOUR_IP:8089/api/billetterie-electronique
```

See [app/README.md](app/README.md) for full documentation.
""",
    )


def main() -> None:
    print("1. Moving to apps/ and packages/ layout...")
    move_physical_layout()

    print("2. Restructuring packages...")
    restructure_peyapay()
    restructure_immo()
    restructure_billetterie()
    restructure_super_app()

    print("3. Updating pubspec files...")
    update_pubspecs()

    print("4. Fixing imports...")
    fix_package_imports()
    fix_immo_relative_imports()
    fix_immo_barrel_exports()
    fix_billetterie_imports()
    fix_peyapay_imports()
    fix_super_app_imports()

    print("5. Creating melos.yaml and README...")
    create_melos_and_readme()

    print("Done.")


if __name__ == "__main__":
    main()
