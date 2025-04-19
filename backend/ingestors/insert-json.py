import json
import os
from datetime import datetime
from backend.extensions import DBPool
# from ingestors.helpers import transform_match_data
# from backend.ingestors.validators import validate_match_json

def insert_json_file(file_path):
    """Insert JSON match data into PostgreSQL"""
    conn = DBPool.get_conn()
    cur = conn.cursor()
    
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            
        # if not validate_match_json(data):
        #     raise ValueError("Invalid match JSON structure")
            
        # transformed = transform_match_data(data)
        transformed = data  # Placeholder for transformation logic
        
        # Insert match
        cur.execute("""
            INSERT INTO matches (
                match_id, data_version, created_date, match_date, 
                city, venue, event_name, match_type, season, 
                teams, winner, winner_by_runs, winner_by_wickets,
                toss_winner, toss_decision, player_of_match,
                officials, powerplays, raw_data
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, 
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            ) RETURNING match_id
        """, (
            transformed['match_id'],
            transformed.get('data_version'),
            transformed.get('created_date', datetime.utcnow()),
            transformed['match_date'],
            transformed.get('city'),
            transformed['venue'],
            transformed['event_name'],
            transformed['match_type'],
            transformed['season'],
            transformed['teams'],
            transformed.get('winner'),
            transformed.get('winner_by_runs'),
            transformed.get('winner_by_wickets'),
            transformed['toss_winner'],
            transformed['toss_decision'],
            transformed.get('player_of_match'),
            json.dumps(transformed.get('officials', {})),
            json.dumps(transformed.get('powerplays', {})),
            json.dumps(transformed['raw_data'])
        ))
        
        match_id = cur.fetchone()[0]
        
        # Insert innings and deliveries
        for innings in transformed['innings']:
            cur.execute("""
                INSERT INTO innings (
                    match_id, team, innings_number,
                    target_runs, target_overs
                ) VALUES (%s, %s, %s, %s, %s)
                RETURNING innings_id
            """, (
                match_id,
                innings['team'],
                innings['innings_number'],
                innings.get('target_runs'),
                innings.get('target_overs')
            ))
            
            innings_id = cur.fetchone()[0]
            
            for delivery in innings['deliveries']:
                cur.execute("""
                    INSERT INTO deliveries (
                        innings_id, match_id, over_number, ball_number,
                        batter, bowler, non_striker, runs_batter,
                        runs_extras, runs_total, is_wicket, wicket_kind,
                        wicket_player_out, wicket_fielders, extras,
                        replacements, review, raw_data
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    )
                """, (
                    innings_id,
                    match_id,
                    delivery['over'],
                    delivery['ball'],
                    delivery['batter'],
                    delivery['bowler'],
                    delivery['non_striker'],
                    delivery['runs']['batter'],
                    delivery['runs']['extras'],
                    delivery['runs']['total'],
                    delivery.get('wicket', {}).get('is_wicket', False),
                    delivery.get('wicket', {}).get('kind'),
                    delivery.get('wicket', {}).get('player_out'),
                    delivery.get('wicket', {}).get('fielders', []),
                    json.dumps(delivery.get('extras', {})),
                    json.dumps(delivery.get('replacements', {})),
                    json.dumps(delivery.get('review', {})),
                    json.dumps(delivery['raw_data'])
                ))
        
        conn.commit()
        print(f"Successfully inserted match {match_id}")
        
    except Exception as e:
        conn.rollback()
        print(f"Error inserting match: {e}")
        raise
    finally:
        cur.close()
        DBPool.put_conn(conn)

def batch_insert_from_directory(directory):
    """Process all JSON files in a directory"""
    for filename in os.listdir(directory):
        if filename.endswith('.json'):
            filepath = os.path.join(directory, filename)
            try:
                print(f"Processing {filename}...")
                insert_json_file(filepath)
            except Exception as e:
                print(f"Failed to process {filename}: {e}")
                continue