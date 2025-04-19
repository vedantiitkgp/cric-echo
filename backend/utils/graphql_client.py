import requests
from pathlib import Path
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

def execute_query(query_name, variables=None):
    query_path = os.path.join(os.path.dirname(__file__), "..", "graphql", "queries", f"{query_name}.graphql")
    
    with open(query_path) as f:
        query = f.read()
    
    HASURA_GRAPHQL_URL = os.getenv("HASURA_GRAPHQL_URL")
    HASURA_ADMIN_SECRET = os.getenv("HASURA_ADMIN_SECRET")

    headers = {
        "Content-Type": "application/json",
        "x-hasura-admin-secret": HASURA_ADMIN_SECRET
    }
    response = requests.post(HASURA_GRAPHQL_URL, headers=headers, json={
        "query": query,
        "variables": variables or {}
    })

    return response.json()