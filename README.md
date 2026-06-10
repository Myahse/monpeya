# Mon Peya

N'TERI super-app monorepo — one GitLab repo, three sibling Flutter packages.

```
Mon peya/                     # Git repo root
├── mon_peya_super_app/       # Shell: auth, home, navigation, module launcher
├── peya_pay/                 # Wallet & payments (Peya Pay)
├── mr_immo/                  # Location, Construction, Collection
├── billetterie_electronique/ # Ticketing (events + Cars)
└── README.md
```

**Remote:** https://gitlab.com/djogana-pay/monpeya (`develop` branch)

## Run

```powershell
cd mon_peya_super_app
flutter pub get
flutter run
```

Optional API URLs:

```powershell
flutter run `
  --dart-define=IMMO_API_URL=http://YOUR_IP:8081 `
  --dart-define=BILLETTERIE_API_URL=http://YOUR_IP:8089/api/billetterie-electronique
```

See [mon_peya_super_app/README.md](mon_peya_super_app/README.md) for full documentation.

## Clone

```powershell
git clone -b develop https://gitlab.com/djogana-pay/monpeya.git "Mon peya"
cd "Mon peya/mon_peya_super_app"
flutter pub get
flutter run
```

Keep the four folders as siblings — `pubspec.yaml` uses `path: ../peya_pay`, `../mr_immo`, and `../billetterie_electronique`.
