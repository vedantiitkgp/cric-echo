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