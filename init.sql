CREATE TABLE conditions (
    id INTEGER PRIMARY KEY,
    value text DEFAULT 'hello worl blah blah !'
);

SELECT create_hypertable('conditions', 'id', chunk_time_interval => 1000); -- simulating a case with many chunks

COPY conditions (id) FROM PROGRAM 'seq 5000000' WITH (
	FORMAT csv,
	ON_ERROR ignore,
	LOG_VERBOSITY verbose
);

