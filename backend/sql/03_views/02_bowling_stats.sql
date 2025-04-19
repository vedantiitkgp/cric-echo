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