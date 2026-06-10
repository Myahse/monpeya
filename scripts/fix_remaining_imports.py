#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def replace_in_tree(directory: Path, replacements: list[tuple[str, str]]) -> None:
    for file in directory.rglob("*.dart"):
        if "build" in file.parts:
            continue
        text = file.read_text(encoding="utf-8")
        new = text
        for old, new_val in replacements:
            new = new.replace(old, new_val)
        if new != text:
            file.write_text(new, encoding="utf-8")


def main() -> None:
    replace_in_tree(
        ROOT / "app" / "lib",
        [
            ("import '../app/routing/routes.dart'", "import 'package:app/src/core/routing/routes.dart'"),
            (
                "import '../../settings/settings_screen.dart'",
                "import 'package:app/src/features/settings/presentation/settings_screen.dart'",
            ),
        ],
    )

    replace_in_tree(
        ROOT / "packages" / "mon_peya_billetterie" / "lib",
        [
            (
                "import '../billetterie_brand.dart'",
                "import 'package:billetterie/src/presentation/billetterie_brand.dart'",
            ),
        ],
    )

    replace_in_tree(
        ROOT / "packages" / "mon_peya_peyapay" / "lib",
        [
            (
                "import '../peya_pay_assets.dart'",
                "import 'package:peyapay/src/core/peya_pay_assets.dart'",
            ),
            (
                "import '../utils/formatters.dart'",
                "import 'package:peyapay/utils/formatters.dart'",
            ),
            (
                "import '../utils/screen_insets.dart'",
                "import 'package:peyapay/utils/screen_insets.dart'",
            ),
        ],
    )

    print("Remaining imports fixed.")


if __name__ == "__main__":
    main()
