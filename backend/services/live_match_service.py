# services/live_match_service.py
import requests
from datetime import datetime
from flask import current_app
from functools import lru_cache
import os
from dotenv import load_dotenv

# Load environment variables from .env file 
load_dotenv()

class LiveMatchService:
    def __init__(self):
        self.base_url = "https://api.cricapi.com/v1"
        self.api_key = os.getenv('CRICAPI_KEY')
        self.cache_timeout = 15  # seconds (cricket balls occur every 30-60s)

    @lru_cache(maxsize=8)
    def get_live_ipl_matches(self):
        """Get list of currently live IPL matches"""
        try:
            response = requests.get(
                f"{self.base_url}/currentMatches",
                params={"apikey": self.api_key},
                timeout=3
            )
            response.raise_for_status()
            return [
                m for m in response.json()['data']
                if 'IPL' in m.get('series_name', '') and m.get('status') == 'Live'
            ]
        except (requests.RequestException, KeyError) as e:
            current_app.logger.error(f"CricAPI error: {str(e)}")
            return []

    def get_ball_by_ball(self, match_id):
        """Get ball-by-ball data for specific match"""
        try:
            response = requests.get(
                f"{self.base_url}/match_balls",
                params={
                    "apikey": self.api_key,
                    "id": match_id
                },
                timeout=3
            )
            response.raise_for_status()
            return self._transform_ball_data(response.json().get('data', []))
        except requests.RequestException as e:
            current_app.logger.error(f"CricAPI error: {str(e)}")
            return []

    def _transform_ball_data(self, ball_data):
        """Transform CricAPI data to match our schema"""
        return [{
            'over': float(ball['over']),
            'ball': int(ball['ball']),
            'batter': ball['batsman'],
            'bowler': ball['bowler'],
            'runs': int(ball['runs']),
            'extras': int(ball.get('extras', 0)),
            'is_wicket': bool(ball.get('wicket', '')),
            'commentary': ball.get('comment', '')
        } for ball in ball_data if all(k in ball for k in ['over', 'ball', 'batsman'])]