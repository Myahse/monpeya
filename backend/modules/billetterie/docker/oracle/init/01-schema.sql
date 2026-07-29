
CREATE TABLE ticketing_ping (
    id NUMBER(19) PRIMARY KEY,
    ping_id NUMBER(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

INSERT INTO ticketing_ping (id, ping_id) VALUES (1, 1);
COMMIT;
