-- 2. Players table
CREATE TABLE IF NOT EXISTS players (
    player_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    uuid TEXT UNIQUE,
    teams TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);