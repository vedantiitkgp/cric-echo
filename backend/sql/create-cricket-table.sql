CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Matches table
CREATE TABLE IF NOT EXISTS matches (
    match_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_version TEXT,
    created_date TIMESTAMP,
    match_date DATE NOT NULL,
    city TEXT,
    venue TEXT NOT NULL,
    event_name TEXT NOT NULL,
    match_type TEXT NOT NULL CHECK (match_type IN ('T20', 'ODI', 'Test', 'T10', 'Other')),
    season TEXT NOT NULL,
    teams TEXT[] NOT NULL,
    winner TEXT,
    winner_by_runs INTEGER,
    winner_by_wickets INTEGER,
    toss_winner TEXT NOT NULL,
    toss_decision TEXT NOT NULL CHECK (toss_decision IN ('bat', 'field')),
    player_of_match TEXT,
    officials JSONB,
    powerplays JSONB,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Players table
CREATE TABLE IF NOT EXISTS players (
    player_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    uuid TEXT UNIQUE,
    teams TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Innings table
CREATE TABLE IF NOT EXISTS innings (
    innings_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    team TEXT NOT NULL,
    innings_number INTEGER NOT NULL CHECK (innings_number BETWEEN 1 AND 4),
    target_runs INTEGER,
    target_overs INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_innings_per_match UNIQUE (match_id, innings_number)
);

-- 4. Deliveries table (modified for older PostgreSQL)
CREATE TABLE IF NOT EXISTS deliveries (
    delivery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    innings_id UUID NOT NULL REFERENCES innings(innings_id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    over_number DECIMAL(4,1) NOT NULL CHECK (over_number >= 0),
    ball_number INTEGER NOT NULL,
    batter TEXT NOT NULL,
    bowler TEXT NOT NULL,
    non_striker TEXT NOT NULL,
    runs_batter INTEGER NOT NULL DEFAULT 0 CHECK (runs_batter BETWEEN 0 AND 6),
    runs_extras INTEGER NOT NULL DEFAULT 0,
    runs_total INTEGER NOT NULL,
    is_wicket BOOLEAN DEFAULT FALSE,
    wicket_kind TEXT,
    wicket_player_out TEXT,
    wicket_fielders TEXT[],
    extras JSONB,
    replacements JSONB,
    review JSONB,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_over_ball CHECK (
        (over_number >= 0 AND over_number <= 50))
);

-- Create the trigger function
CREATE OR REPLACE FUNCTION calculate_delivery_values()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate total runs
    NEW.runs_total := NEW.runs_batter + NEW.runs_extras;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trigger_calculate_delivery_values
BEFORE INSERT OR UPDATE ON deliveries
FOR EACH ROW
EXECUTE FUNCTION calculate_delivery_values();

-- [Rest of your indexes and views can remain the same]

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_matches_date ON matches(match_date);
CREATE INDEX IF NOT EXISTS idx_matches_season ON matches(season);
CREATE INDEX IF NOT EXISTS idx_matches_teams ON matches USING GIN(teams);
CREATE INDEX IF NOT EXISTS idx_players_name ON players(name);
CREATE INDEX IF NOT EXISTS idx_players_teams ON players USING GIN(teams);
CREATE INDEX IF NOT EXISTS idx_innings_match ON innings(match_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_match ON deliveries(match_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_innings ON deliveries(innings_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_over ON deliveries(over_number);
CREATE INDEX IF NOT EXISTS idx_deliveries_batter ON deliveries(batter);
CREATE INDEX IF NOT EXISTS idx_deliveries_bowler ON deliveries(bowler);
CREATE INDEX IF NOT EXISTS idx_deliveries_wicket ON deliveries(wicket_player_out) WHERE is_wicket = TRUE;

-- Create a view for basic batting statistics
CREATE OR REPLACE VIEW batting_stats AS
SELECT 
    batter AS player,
    COUNT(*) AS balls_faced,
    SUM(runs_batter) AS runs_scored,
    SUM(CASE WHEN is_wicket THEN 1 ELSE 0 END) AS times_out,
    ROUND(SUM(runs_batter) * 100.0 / NULLIF(COUNT(*), 0), 2) AS strike_rate
FROM deliveries
GROUP BY batter;

-- Create a view for basic bowling statistics
CREATE OR REPLACE VIEW bowling_stats AS
SELECT 
    bowler AS player,
    COUNT(*) AS balls_bowled,
    SUM(runs_total) AS runs_conceded,
    SUM(CASE WHEN is_wicket THEN 1 ELSE 0 END) AS wickets_taken,
    ROUND(SUM(runs_total) * 6.0 / NULLIF(COUNT(*), 0), 2) AS economy_rate
FROM deliveries
GROUP BY bowler;

-- First, drop the existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_update_match_summary ON deliveries;

-- Then drop the function if it exists
DROP FUNCTION IF EXISTS update_match_summary();

-- Create the corrected trigger function
CREATE OR REPLACE FUNCTION update_match_summary()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if this is the second innings
    IF EXISTS (
        SELECT 1 FROM innings 
        WHERE innings_id = NEW.innings_id AND innings_number = 2
    ) THEN
        -- Update match outcome only if winner isn't already set
        UPDATE matches m
        SET 
            winner = CASE 
                WHEN (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = 
                    (SELECT innings_id FROM innings WHERE match_id = NEW.match_id AND innings_number = 1)) >
                    (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = NEW.innings_id)
                THEN (SELECT team FROM innings WHERE match_id = NEW.match_id AND innings_number = 1)
                ELSE (SELECT team FROM innings WHERE innings_id = NEW.innings_id)
            END,
            winner_by_runs = CASE 
                WHEN (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = 
                    (SELECT innings_id FROM innings WHERE match_id = NEW.match_id AND innings_number = 1)) >
                    (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = NEW.innings_id)
                THEN (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = 
                    (SELECT innings_id FROM innings WHERE match_id = NEW.match_id AND innings_number = 1)) -
                    (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = NEW.innings_id)
                ELSE NULL
            END,
            winner_by_wickets = CASE 
                WHEN (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = 
                    (SELECT innings_id FROM innings WHERE match_id = NEW.match_id AND innings_number = 1)) <
                    (SELECT SUM(runs_total) FROM deliveries WHERE innings_id = NEW.innings_id)
                THEN 10 - (SELECT COUNT(*) FROM deliveries 
                          WHERE innings_id = NEW.innings_id
                          AND is_wicket = TRUE)
                ELSE NULL
            END
        WHERE m.match_id = NEW.match_id
        AND m.winner IS NULL; -- Only update if winner isn't already set
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER trigger_update_match_summary
AFTER INSERT ON deliveries
FOR EACH ROW
EXECUTE FUNCTION update_match_summary();