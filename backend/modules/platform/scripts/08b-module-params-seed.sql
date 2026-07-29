SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DELETE FROM MP_MODULE_PARAM
WHERE PARAM_KEY IN ('iconKey', 'route', 'subtitle', 'homeVisible', 'category', 'accentColor');

INSERT INTO MP_MODULE_PARAM (ID, MODULE_ID, PARAM_KEY, PARAM_VALUE, SORT_ORDER)
SELECT MP_MODULE_PARAM_SEQ.NEXTVAL, m.ID, p.PARAM_KEY, p.PARAM_VALUE, p.SORT_ORDER
FROM MP_MODULE m
JOIN (
    SELECT 'home' AS MOD, 'iconKey' AS PARAM_KEY, 'home' AS PARAM_VALUE, 10 AS SORT_ORDER FROM DUAL UNION ALL
    SELECT 'home', 'route', '/home', 20 FROM DUAL UNION ALL
    SELECT 'home', 'subtitle', 'Accueil', 30 FROM DUAL UNION ALL
    SELECT 'home', 'homeVisible', 'false', 40 FROM DUAL UNION ALL
    SELECT 'home', 'category', 'shell', 50 FROM DUAL UNION ALL
    SELECT 'peyapay', 'iconKey', 'peyapay', 10 FROM DUAL UNION ALL
    SELECT 'peyapay', 'route', '/peyapay', 20 FROM DUAL UNION ALL
    SELECT 'peyapay', 'subtitle', 'Paiements et transferts', 30 FROM DUAL UNION ALL
    SELECT 'peyapay', 'homeVisible', 'true', 40 FROM DUAL UNION ALL
    SELECT 'peyapay', 'category', 'finance', 50 FROM DUAL UNION ALL
    SELECT 'peyapay', 'accentColor', '#0B6E4F', 60 FROM DUAL UNION ALL
    SELECT 'real-estate', 'iconKey', 'real_estate', 10 FROM DUAL UNION ALL
    SELECT 'real-estate', 'route', '/immo/location', 20 FROM DUAL UNION ALL
    SELECT 'real-estate', 'subtitle', 'Location immobiliere', 30 FROM DUAL UNION ALL
    SELECT 'real-estate', 'homeVisible', 'true', 40 FROM DUAL UNION ALL
    SELECT 'real-estate', 'category', 'immo', 50 FROM DUAL UNION ALL
    SELECT 'real-estate', 'accentColor', '#1F4B99', 60 FROM DUAL UNION ALL
    SELECT 'construction', 'iconKey', 'construction', 10 FROM DUAL UNION ALL
    SELECT 'construction', 'route', '/immo/construction', 20 FROM DUAL UNION ALL
    SELECT 'construction', 'subtitle', 'Construction', 30 FROM DUAL UNION ALL
    SELECT 'construction', 'homeVisible', 'true', 40 FROM DUAL UNION ALL
    SELECT 'construction', 'category', 'immo', 50 FROM DUAL UNION ALL
    SELECT 'construction', 'accentColor', '#1F4B99', 60 FROM DUAL UNION ALL
    SELECT 'collection', 'iconKey', 'collection', 10 FROM DUAL UNION ALL
    SELECT 'collection', 'route', '/immo/collection', 20 FROM DUAL UNION ALL
    SELECT 'collection', 'subtitle', 'Collection', 30 FROM DUAL UNION ALL
    SELECT 'collection', 'homeVisible', 'true', 40 FROM DUAL UNION ALL
    SELECT 'collection', 'category', 'immo', 50 FROM DUAL UNION ALL
    SELECT 'collection', 'accentColor', '#1F4B99', 60 FROM DUAL UNION ALL
    SELECT 'billetterie', 'iconKey', 'billetterie', 10 FROM DUAL UNION ALL
    SELECT 'billetterie', 'route', '/billetterie', 20 FROM DUAL UNION ALL
    SELECT 'billetterie', 'subtitle', 'Evenements et billets', 30 FROM DUAL UNION ALL
    SELECT 'billetterie', 'homeVisible', 'true', 40 FROM DUAL UNION ALL
    SELECT 'billetterie', 'category', 'lifestyle', 50 FROM DUAL UNION ALL
    SELECT 'billetterie', 'accentColor', '#C45C26', 60 FROM DUAL UNION ALL
    SELECT 'leadway-assurance', 'iconKey', 'leadway', 10 FROM DUAL UNION ALL
    SELECT 'leadway-assurance', 'route', '/leadway', 20 FROM DUAL UNION ALL
    SELECT 'leadway-assurance', 'subtitle', 'Assurance moto', 30 FROM DUAL UNION ALL
    SELECT 'leadway-assurance', 'homeVisible', 'true', 40 FROM DUAL UNION ALL
    SELECT 'leadway-assurance', 'category', 'insurance', 50 FROM DUAL UNION ALL
    SELECT 'leadway-assurance', 'accentColor', '#B00020', 60 FROM DUAL UNION ALL
    SELECT 'subscriptions', 'iconKey', 'subscriptions', 10 FROM DUAL UNION ALL
    SELECT 'subscriptions', 'route', '/subscriptions', 20 FROM DUAL UNION ALL
    SELECT 'subscriptions', 'subtitle', 'Abonnements Mon Peya', 30 FROM DUAL UNION ALL
    SELECT 'subscriptions', 'homeVisible', 'true', 40 FROM DUAL UNION ALL
    SELECT 'subscriptions', 'category', 'account', 50 FROM DUAL UNION ALL
    SELECT 'subscriptions', 'accentColor', '#333333', 60 FROM DUAL
) p ON p.MOD = m.CODE;

COMMIT;

SELECT COUNT(*) AS PARAM_COUNT FROM MP_MODULE_PARAM;
EXIT;
