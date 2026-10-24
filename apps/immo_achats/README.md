# Immo Achats

Moyens généraux : commande les demandes validées auprès des fournisseurs.

Une des quatre applications Mr Immo Construction (une par rôle). Les écrans viennent de
`packages/immo` ; l'application ne fait que la connexion, comme Mon Peya : le code client
(numéro de téléphone du compte) puis le code PIN à 4 chiffres, et ouvre les onglets du rôle.

```bash
flutter run --dart-define=IMMO_API_URL=http://<IP du PC>:8082
```

Sans `IMMO_API_URL`, l'émulateur Android joint le backend de la machine hôte
(`http://10.0.2.2:8082`). Compte de démo (backend lancé avec `SEED_DEMO_DATA=true`) : code client `0700000204`,
code PIN `1234`.
