-- Batting statistics view
CREATE OR REPLACE VIEW batting_stats AS
SELECT 
    batter AS player,
    COUNT(*) AS balls_faced,
    SUM(runs_batter) AS runs_scored,
    SUM(CASE WHEN is_wicket THEN 1 ELSE 0 END) AS times_out,
    ROUND(SUM(runs_batter) * 100.0 / NULLIF(COUNT(*), 0), 2) AS strike_rate
FROM deliveries
GROUP BY batter;