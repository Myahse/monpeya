# Billetterie électronique

Independent Flutter application module for **Mon Peya / N'TERI**.

Based on `C:\dev\NTERI\billetterie-electronique\apps\mobile`.

## Structure

```
billetterie_electronique/
  lib/
    screens/         # Events, Cars/tickets, onboarding, roles
    navigation/
    services/        # API (mock fallback), local ticket storage
    host/            # BilletterieHostBridge — Mon Peya injects Peya Pay
  pubspec.yaml
```

## Integration

```yaml
dependencies:
  billetterie_electronique:
    path: packages/billetterie_electronique
```

Before opening Billetterie:

```dart
MonPeyaBilletterieHostAdapter.register(); // wires PeyaPay → BilletterieHostBridge
```

## API

```bash
flutter run --dart-define=BILLETTERIE_API_URL=http://HOST:8089/api/billetterie-electronique
```

Until backend events/orders exist, the module uses mock data (same as the Expo app).
