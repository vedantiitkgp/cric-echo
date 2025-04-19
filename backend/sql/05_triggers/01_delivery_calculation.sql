-- Create the trigger
CREATE TRIGGER trigger_calculate_delivery_values
BEFORE INSERT OR UPDATE ON deliveries
FOR EACH ROW
EXECUTE FUNCTION calculate_delivery_values();