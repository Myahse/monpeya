-- Create ticketing schema user (monpeya user is created by gvenzl APP_USER env).
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = XEPDB1;

DECLARE
  user_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = 'TICKETING';
  IF user_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER ticketing IDENTIFIED BY ticketing';
    EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE TO ticketing';
    EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO ticketing';
  END IF;
END;
/
