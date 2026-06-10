# Mr Immo

Independent Flutter application module for **Mon Peya / N'TERI**.

Mirrors the NTERI pattern where `billetterie-electronique/apps/mobile` is a separate app embedded in the super-app shell.

## Structure

```
mr_immo/
  lib/
    rental/          # Mr Immo Location
    construction/    # Mr Immo Construction
    collection/      # Mr Immo Collection
    shared/          # API client, auth (via host bridge)
    host/            # ImmoHostBridge — Mon Peya injects phone/PIN auth
  assets/logo/immo/
  pubspec.yaml
```

## Integration

Mon Peya depends on this package via path:

```yaml
dependencies:
  mr_immo:
    path: packages/mr_immo
```

Before opening Mr Immo, the shell registers:

```dart
MonPeyaImmoHostAdapter.register(); // wires AuthStore → ImmoHostBridge
```

## Run standalone (future)

Add an `example/` runner with a mock [ImmoHostAuth] for isolated development.
