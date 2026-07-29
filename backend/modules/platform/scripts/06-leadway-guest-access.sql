-- Leadway: guest browse; registration (AUTH) only for payment / my-contracts actions.
UPDATE MP_MODULE
SET DESCRIPTION = 'Insurance browse; payment needs registration',
    DEFAULT_ACTION_LEVEL = 'GUEST'
WHERE CODE = 'leadway-assurance';

UPDATE MP_SERVICE_ACTION
SET NAME = 'Souscrire / payer assurance',
    ACCESS_LEVEL = 'AUTH'
WHERE CODE = 'policy.checkout'
  AND MODULE_ID = (SELECT ID FROM MP_MODULE WHERE CODE = 'leadway-assurance');

UPDATE MP_SERVICE_ACTION
SET ACCESS_LEVEL = 'AUTH'
WHERE CODE = 'policy.list'
  AND MODULE_ID = (SELECT ID FROM MP_MODULE WHERE CODE = 'leadway-assurance');

COMMIT;
