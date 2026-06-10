#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PKG = "immo"
BASE = ROOT / "packages" / PKG / "lib"


def write_barrel(path: Path, prefix: str, exports: list[str]) -> None:
    lines = ["library;", ""]
    for rel in exports:
        lines.append(f"export 'package:{PKG}/src/{prefix}/{rel}';")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    write_barrel(
        BASE / "src/features/rental/rental.dart",
        "features/rental",
        [
            "config/rental_api_endpoints.dart",
            "models/rental_contract.dart",
            "models/rental_property.dart",
            "models/rental_tenant.dart",
            "navigation/rental_main_navigation.dart",
            "navigation/rental_tab.dart",
            "rental_module_screen.dart",
            "screens/listings_screen.dart",
            "screens/property_detail_screen.dart",
            "services/rental_api_service.dart",
            "services/rental_property_service.dart",
            "services/rental_tenant_service.dart",
            "widgets/property_card.dart",
            "widgets/tenant_card.dart",
        ],
    )
    write_barrel(
        BASE / "src/features/construction/construction.dart",
        "features/construction",
        [
            "construction_module_screen.dart",
            "models/construction_site.dart",
            "navigation/construction_main_navigation.dart",
            "navigation/construction_tab.dart",
            "services/construction_api_service.dart",
        ],
    )
    write_barrel(
        BASE / "src/features/collection/collection.dart",
        "features/collection",
        [
            "collection_module_screen.dart",
            "models/contract.dart",
            "models/payment.dart",
            "models/property.dart",
            "navigation/collection_navigator.dart",
            "services/contract_service.dart",
            "services/payment_service.dart",
            "services/property_service.dart",
        ],
    )
    write_barrel(
        BASE / "src/shared/shared.dart",
        "shared",
        [
            "auth/immo_auth_service.dart",
            "config/immo_api_config.dart",
            "models/immo_api_response.dart",
            "services/immo_api_client.dart",
            "widgets/immo_screen_stub.dart",
        ],
    )
    print("Barrel exports fixed.")


if __name__ == "__main__":
    main()
