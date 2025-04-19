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