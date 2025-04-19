-- Matches table definition
CREATE TABLE IF NOT EXISTS matches (
    match_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_version TEXT,
    created_date TIMESTAMP,
    match_date DATE NOT NULL,
    city TEXT,
    venue TEXT NOT NULL,
    event_name TEXT NOT NULL,
    match_type TEXT NOT NULL,
    season TEXT NOT NULL,
    teams TEXT[] NOT NULL,
    winner TEXT,
    winner_by_runs INTEGER,
    winner_by_wickets INTEGER,
    toss_winner TEXT NOT NULL,
    toss_decision TEXT NOT NULL,
    player_of_match TEXT,
    officials JSONB,
    powerplays JSONB,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);