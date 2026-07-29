-- Reuse MP_MODULE as the app services catalog: add JSON metadata for Flutter.
-- Safe to re-run: adds column only if missing, then upserts seed metadata.

WHENEVER SQLERROR CONTINUE
SET DEFINE OFF

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME = 'MP_MODULE' AND COLUMN_NAME = 'METADATA_JSON';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE MP_MODULE ADD (METADATA_JSON CLOB)';
    END IF;
END;
/

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "home",
  "route": "/home",
  "subtitle": "Accueil",
  "homeVisible": false,
  "category": "shell"
}' WHERE CODE = 'home';

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "peyapay",
  "route": "/peyapay",
  "subtitle": "Paiements et transferts",
  "homeVisible": true,
  "category": "finance",
  "accentColor": "#0B6E4F"
}' WHERE CODE = 'peyapay';

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "real_estate",
  "route": "/immo/location",
  "subtitle": "Location immobiliere",
  "homeVisible": true,
  "category": "immo",
  "accentColor": "#1F4B99"
}' WHERE CODE = 'real-estate';

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "construction",
  "route": "/immo/construction",
  "subtitle": "Construction",
  "homeVisible": true,
  "category": "immo",
  "accentColor": "#1F4B99"
}' WHERE CODE = 'construction';

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "collection",
  "route": "/immo/collection",
  "subtitle": "Collection",
  "homeVisible": true,
  "category": "immo",
  "accentColor": "#1F4B99"
}' WHERE CODE = 'collection';

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "billetterie",
  "route": "/billetterie",
  "subtitle": "Evenements et billets",
  "homeVisible": true,
  "category": "lifestyle",
  "accentColor": "#C45C26"
}' WHERE CODE = 'billetterie';

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "leadway",
  "route": "/leadway",
  "subtitle": "Assurance moto",
  "homeVisible": true,
  "category": "insurance",
  "accentColor": "#B00020"
}' WHERE CODE = 'leadway-assurance';

UPDATE MP_MODULE SET METADATA_JSON = '{
  "iconKey": "subscriptions",
  "route": "/subscriptions",
  "subtitle": "Abonnements Mon Peya",
  "homeVisible": true,
  "category": "account",
  "accentColor": "#333333"
}' WHERE CODE = 'subscriptions';

COMMIT;
