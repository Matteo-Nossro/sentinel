CREATE SCHEMA IF NOT EXISTS ingestion;
CREATE SCHEMA IF NOT EXISTS rules_engine;
CREATE SCHEMA IF NOT EXISTS notification;

GRANT ALL ON SCHEMA ingestion TO sentinel;
GRANT ALL ON SCHEMA rules_engine TO sentinel;
GRANT ALL ON SCHEMA notification TO sentinel;
