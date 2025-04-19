import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

# Database connection parameters
db_params = {
    'host': os.getenv("DB_HOST"),
    'database': os.getenv("DB_NAME"),
    'user': os.getenv("DB_USER"),
    'password': os.getenv("DB_PASSWORD"),
    'port': os.getenv("DB_PORT")
}


# Get absolute path to the SQL file
base_dir = os.path.dirname(os.path.abspath(__file__))
sql_path = os.path.join(base_dir, '..', 'sql', 'create-cricket-table.sql')

# Read SQL script
with open(sql_path, 'r') as file:
    sql_script = file.read()

# Execute script
try:
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()
    cursor.execute(sql_script)
    conn.commit()
    print("Tables created successfully!")
except Exception as e:
    print(f"Error: {e}")
    conn.rollback()
finally:
    if conn:
        cursor.close()
        conn.close()