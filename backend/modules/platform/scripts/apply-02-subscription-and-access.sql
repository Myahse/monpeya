-- Apply as MONPEYA on an existing DB that already has auth tables (01).
-- Prefer docker/oracle/init/02 for fresh volumes; use this + 03 if upgrading.

WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

@@../docker/oracle/init/02-subscription-and-access.sql
