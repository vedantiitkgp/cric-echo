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