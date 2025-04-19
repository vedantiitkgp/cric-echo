from flask import Flask, jsonify, request
from services import match_service, similarity_service
import os

app = Flask(__name__)
HASURA_URL = os.getenv('HASURA_URL')
HASURA_ADMIN_KEY = os.getenv('HASURA_ADMIN_KEY')

@app.route('/match/<match_id>', methods=['GET'])
def get_match(match_id):
    """Endpoint 1: Get match details"""
    return jsonify(match_service.get_match_details(match_id))

@app.route('/similar/current', methods=['GET'])
def similar_to_current():
    """Endpoint 2: Find similar to current match"""
    current_match = match_service.get_current_match()
    return jsonify(similarity_service.find_similar_matches(current_match))

@app.route('/similar/match/<match_id>', methods=['GET'])
def similar_to_match(match_id):
    """Endpoint 3: Find similar to specified match"""
    target_match = match_service.get_match_details(match_id)
    return jsonify(similarity_service.find_similar_matches(target_match))

@app.route('/similar/over', methods=['GET'])
def similar_over():
    """Endpoint 4: Find similar overs"""
    over_number = float(request.args.get('over_number'))
    match_id = request.args.get('match_id')
    return jsonify(similarity_service.find_similar_overs(match_id, over_number))

if __name__ == '__main__':
    app.run()