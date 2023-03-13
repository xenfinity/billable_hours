DROP TABLE timers;

CREATE TABLE timers (
    id serial PRIMARY KEY,
    name text NOT NULL,
    description text,
    start_time bigint NOT NULL,
    paused_time bigint,
    completed_time bigint,
    paused_duration bigint NOT NULL DEFAULT 0
);