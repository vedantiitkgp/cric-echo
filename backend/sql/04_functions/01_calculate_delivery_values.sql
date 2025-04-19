-- Create the trigger function
CREATE OR REPLACE FUNCTION calculate_delivery_values()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate total runs
    NEW.runs_total := NEW.runs_batter + NEW.runs_extras;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;