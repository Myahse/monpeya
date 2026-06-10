#!/usr/bin/env python3
"""Fix Dart imports/exports after file convention rename."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PACKAGES = {
    "app": ROOT / "app" / "lib",
    "immo": ROOT / "packages" / "immo" / "lib",
    "peyapay": ROOT / "packages" / "peyapay" / "lib",
    "billetterie": ROOT / "packages" / "billetterie" / "lib",
}

IMPORT_RE = re.compile(r"(import|export)\s+'([^']+)'")


def rel_from_lib(pkg: str, path: Path) -> str:
    lib = PACKAGES[pkg]
    return path.relative_to(lib).as_posix()


def build_index() -> dict[str, dict[str, str]]:
    """pkg -> {filename -> lib-relative path}"""
    index: dict[str, dict[str, str]] = {}
    for pkg, lib in PACKAGES.items():
        index[pkg] = {}
        for f in lib.rglob("*.dart"):
            rel = rel_from_lib(pkg, f)
            name = f.name
            if name not in index[pkg]:
                index[pkg][name] = rel
    return index


def resolve_uri(uri: str, index: dict[str, dict[str, str]]) -> str:
    if uri.startswith("package:"):
        pkg, _, rel = uri.removeprefix("package:").partition("/")
        if pkg not in PACKAGES:
            return uri
        lib = PACKAGES[pkg]
        if (lib / rel).exists():
            return uri
        name = Path(rel).name
        if name in index[pkg]:
            return f"package:{pkg}/{index[pkg][name]}"
        # double extension fixes
        for bad, good in [
            (".model.model.dart", ".model.dart"),
            (".contract.model.dart", ".contract.dart"),
            (".property.model.dart", ".property.dart"),
            (".payment.model.dart", ".payment.dart"),
            (".site.model.dart", ".site.dart"),
            (".message.model.dart", ".message.dart"),
            (".item.model.dart", ".item.dart"),
            (".event.model.dart", ".event.dart"),
            (".ticket.model.dart", ".ticket.dart"),
        ]:
            if bad in name:
                alt = name.replace(bad, good)
                if alt in index[pkg]:
                    return f"package:{pkg}/{index[pkg][alt]}"
        # path segment fixes
        for old, new in [
            ("src/integration/immo_module.registry.dart", "src/integration/registries/immo_module.registry.dart"),
            ("src/integration/billetterie_module.registry.dart", "src/integration/registries/billetterie_module.registry.dart"),
            ("src/shared/scopes/rental_session.scope.dart", "src/features/rental/auth/scopes/rental_session.scope.dart"),
            ("src/shared/services/rental_api.service.dart", "src/features/rental/services/rental_api.service.dart"),
            ("src/shared/services/rental_payment.service.dart", "src/features/rental/services/rental_payment.service.dart"),
            ("src/shared/models/rental.property.dart", "src/features/rental/models/rental.property.dart"),
            ("src/shared/models/rental.tenant.dart", "src/features/rental/models/rental.tenant.dart"),
            ("src/shared/models/rental.contract.dart", "src/features/rental/models/rental.contract.dart"),
            ("src/shared/models/create_listing.draft.dart", "src/features/rental/models/create_listing.draft.dart"),
            ("src/shared/models/create_tenant.draft.dart", "src/features/rental/models/create_tenant.draft.dart"),
            ("src/shared/widgets/property_card.widget.dart", "src/features/rental/widgets/property_card.widget.dart"),
            ("src/shared/widgets/tenant_card.widget.dart", "src/features/rental/widgets/tenant_card.widget.dart"),
            ("src/shared/widgets/rental_layout_widgets.widget.dart", "src/features/rental/widgets/rental_layout_widgets.widget.dart"),
            ("src/shared/widgets/creation_shell.widget.dart", "src/features/rental/creation/widgets/creation_shell.widget.dart"),
            ("src/shared/models/payment.model.dart", "src/features/collection/models/payment.model.dart"),
            ("src/shared/models/property.model.dart", "src/features/collection/models/property.model.dart"),
            ("src/shared/models/contract.model.dart", "src/features/collection/models/contract.model.dart"),
            ("core/constants/immo.brand.dart", "src/core/constants/immo.brand.dart"),
            ("core/constants/immo_module.keys.dart", "src/core/constants/immo_module.keys.dart"),
            ("core/constants/peya_pay.assets.dart", "src/core/constants/peya_pay.assets.dart"),
            ("src/core/modules/module_icon.module.dart", "src/core/modules/widgets/module.icon.dart"),
            ("src/features/onboarding/presentation/onboarding_screen.dart", "src/features/onboarding/presentation/screens/onboarding.screen.dart"),
            ("src/features/splash/presentation/splash_screen.dart", "src/features/splash/presentation/screens/splash.screen.dart"),
        ]:
            if rel.endswith(old) or rel == old:
                fixed = rel.replace(old, new)
                if (lib / fixed).exists():
                    return f"package:{pkg}/{fixed}"
        return uri

    return uri


def fix_file(path: Path, index: dict[str, dict[str, str]]) -> bool:
    text = path.read_text(encoding="utf-8")
    changed = False

    def repl(m: re.Match[str]) -> str:
        nonlocal changed
        kind, uri = m.group(1), m.group(2)
        new_uri = resolve_uri(uri, index)
        if new_uri != uri:
            changed = True
        return f"{kind} '{new_uri}'"

    new_text = IMPORT_RE.sub(repl, text)
    if changed:
        path.write_text(new_text, encoding="utf-8")
    return changed


def rename_module_icon() -> None:
    src = ROOT / "app/lib/src/core/modules/module_icon.module.dart"
    dst = ROOT / "app/lib/src/core/modules/widgets/module.icon.dart"
    if src.exists() and not dst.exists():
        dst.parent.mkdir(parents=True, exist_ok=True)
        src.rename(dst)


def move_misplaced_rental_payment() -> None:
    src = ROOT / "packages/immo/lib/src/features/rental/models/services/rental.payment.dart"
    dst = ROOT / "packages/immo/lib/src/features/rental/services/rental.payment.dart"
    if src.exists():
        dst.parent.mkdir(parents=True, exist_ok=True)
        src.rename(dst)
        src.parent.rmdir()
        (src.parent.parent / "services").rmdir() if False else None


def regenerate_barrels() -> None:
  # immo.dart
    immo = ROOT / "packages/immo/lib/immo.dart"
    immo.write_text(
        """/// Mon Peya Immo — rental, construction, collection modules.
library;

export 'src/features/collection/collection.dart';
export 'src/features/construction/construction.dart';
export 'src/core/host/immo_host.bridge.dart';
export 'src/core/constants/immo.brand.dart';
export 'src/core/constants/immo_module.keys.dart';
export 'src/features/rental/rental.dart';
export 'src/shared/shared.dart';
""",
        encoding="utf-8",
    )

    billetterie = ROOT / "packages/billetterie/lib/billetterie.dart"
    billetterie.write_text(
        """/// Mon Peya Billetterie — electronic ticketing module.
library;

export 'src/presentation/constants/billetterie.brand.dart';
export 'src/presentation/screens/billetterie_module.screen.dart';
export 'src/core/host/billetterie_host.bridge.dart';
""",
        encoding="utf-8",
    )

    # rental.dart
    rental_exports = [
        "config/rental_api.endpoints.dart",
        "models/rental.contract.dart",
        "models/rental.property.dart",
        "models/rental.tenant.dart",
        "navigation/rental_main.navigation.dart",
        "navigation/rental.tab.dart",
        "screens/rental_module.screen.dart",
        "screens/listings.screen.dart",
        "screens/property_detail.screen.dart",
        "services/rental_api.service.dart",
        "services/rental_property.service.dart",
        "services/rental_tenant.service.dart",
        "widgets/property_card.widget.dart",
        "widgets/tenant_card.widget.dart",
    ]
    rental = ROOT / "packages/immo/lib/src/features/rental/rental.dart"
    lines = ["library;", ""]
    for e in rental_exports:
        lines.append(f"export 'package:immo/src/features/rental/{e}';")
    lines.append("")
    rental.write_text("\n".join(lines), encoding="utf-8")

    construction_exports = [
        "screens/construction_module.screen.dart",
        "models/construction.site.dart",
        "navigation/construction_main.navigation.dart",
        "navigation/construction.tab.dart",
        "services/construction_api.service.dart",
    ]
    c = ROOT / "packages/immo/lib/src/features/construction/construction.dart"
    lines = ["library;", ""]
    for e in construction_exports:
        lines.append(f"export 'package:immo/src/features/construction/{e}';")
    lines.append("")
    c.write_text("\n".join(lines), encoding="utf-8")

    collection_exports = [
        "screens/collection_module.screen.dart",
        "models/contract.model.dart",
        "models/payment.model.dart",
        "models/property.model.dart",
        "navigation/collection.navigator.dart",
        "services/contract.service.dart",
        "services/payment.service.dart",
        "services/property.service.dart",
    ]
    col = ROOT / "packages/immo/lib/src/features/collection/collection.dart"
    lines = ["library;", ""]
    for e in collection_exports:
        lines.append(f"export 'package:immo/src/features/collection/{e}';")
    lines.append("")
    col.write_text("\n".join(lines), encoding="utf-8")

    shared_exports = [
        "auth/immo_auth.service.dart",
        "config/immo_api.config.dart",
        "models/immo_api.response.dart",
        "services/immo_api.client.dart",
        "widgets/immo_screen_stub.widget.dart",
    ]
    s = ROOT / "packages/immo/lib/src/shared/shared.dart"
    lines = ["library;", ""]
    for e in shared_exports:
        lines.append(f"export 'package:immo/src/shared/{e}';")
    lines.append("")
    s.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    rename_module_icon()
    move_misplaced_rental_payment()
    regenerate_barrels()
    index = build_index()
    count = 0
    for lib in PACKAGES.values():
        for f in lib.rglob("*.dart"):
            if fix_file(f, index):
                count += 1
    # second pass
    index = build_index()
    for lib in PACKAGES.values():
        for f in lib.rglob("*.dart"):
            fix_file(f, index)
    print(f"Fixed imports in {count} files.")


if __name__ == "__main__":
    main()
