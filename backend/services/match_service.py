import requests
from utils.graphql_client import execute_query

def get_match_details(match_id):
    """
    Fetch match details from the GraphQL API.
    
    Args:
        match_id (str): The ID of the match to fetch.
    
    Returns:
        dict: The match details.
    """
    query_name = "match_details"
    variables = {"match_id": match_id}
    
    response = execute_query(query_name, variables)
    
    if 'errors' in response:
        raise Exception(f"Error fetching match details: {response['errors']}")
    
    return response['data'] if 'data' in response else None

