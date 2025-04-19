CREATE INDEX IF NOT EXISTS idx_deliveries_match ON deliveries(match_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_innings ON deliveries(innings_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_over ON deliveries(over_number);
CREATE INDEX IF NOT EXISTS idx_deliveries_batter ON deliveries(batter);
CREATE INDEX IF NOT EXISTS idx_deliveries_bowler ON deliveries(bowler);
CREATE INDEX IF NOT EXISTS idx_deliveries_wicket ON deliveries(wicket_player_out) WHERE is_wicket = TRUE;