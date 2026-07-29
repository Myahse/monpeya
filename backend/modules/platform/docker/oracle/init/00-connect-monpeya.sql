-- Run all Monpeya DDL as APP_USER (gvenzl/oracle-xe init scripts execute as SYS).
-- NOTE: each *.sql file is a separate sqlplus session — do not rely on 00 for schema context.
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = XEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = MONPEYA;
