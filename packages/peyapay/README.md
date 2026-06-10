# Peya Pay

Independent Flutter wallet module for **Mon Peya / N'TERI**.

## Structure

```
peya_pay/
  lib/
    host/            # PeyapayHostBridge — Mon Peya injects auth + routes
    screens/         # Dashboard, transfer, bills, source of funds
    widgets/         # Draggable sheets, card preview, slide panels
    models/
    utils/           # Formatters, screen_insets (status bar padding)
  assets/logo/       # Bank & card logos
  pubspec.yaml
```

## Screens

| Screen | Description |
|--------|-------------|
| `peyapay_screen.dart` | Wallet dashboard — balance, quick actions, recent transactions |
| `peyapay_transfer_*` | Contact picker, amount, review, confirm |
| `peyapay_payment_services_screen.dart` | CIE / SODECI bills, domiciliation (French UI, adaptive theme) |
| `peyapay_source_of_funds_screen.dart` | Link banks & debit cards, add-money entry |
| `peyapay_add_money_screen.dart` | Top-up flow (PIN keypad, same layout as transfer) |

## Bottom sheets

Draggable modals use `PeyapayDraggableBottomSheet` with height factors tuned per flow:

| Sheet | Height | Notes |
|-------|--------|-------|
| Mode de transfert | 30% | Bank account vs debit card |
| Ajouter une carte | 68% | Full-size animated card preview |
| Choisir une banque | 72% | Scrollable bank list |
| Carte liée (succès) | 48% | Opens after card sheet dismisses |

## Edge-to-edge layout

Headers sit below the status bar via `peyapayStatusBarTop()` (`MediaQuery.viewPaddingOf`), not `SafeArea` — required on full-screen Android layouts where `padding.top` can be zero.

## Integration

```yaml
dependencies:
  peya_pay:
    path: ../peya_pay
```

Before opening Peya Pay:

```dart
MonPeyaPeyapayHostAdapter.register();
```

The shell tab re-exports the entry screen:

```dart
// app/lib/screens/app_stack/tabs/peyapay_screen.dart
export 'package:peyapay/peyapay.dart';
```

Other modules (e.g. Billetterie) use exported review/payment screens from this package.

## Run / analyze

From the shell app (sibling folder required):

```powershell
cd ../app
flutter pub get
flutter run
```

Analyze this package alone:

```powershell
cd peya_pay
flutter analyze
```
