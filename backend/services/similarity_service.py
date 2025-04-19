from sklearn.neighbors import NearestNeighbors
import numpy as np

class SimilarityService:
    def __init__(self):
        self.match_model = NearestNeighbors(n_neighbors=3)
        self.over_model = NearestNeighbors(n_neighbors=3)
        self._train_models()
    
    def _train_models(self):
        # Load historical data via GraphQL
        historical_data = self._load_historical_data()
        self.match_model.fit(historical_data['match_features'])
        self.over_model.fit(historical_data['over_features'])
    
    def find_similar_matches(self, match_data):
        features = self._extract_match_features(match_data)
        distances, indices = self.match_model.kneighbors([features])
        return self._format_response(match_data, indices[0])
    
    def find_similar_overs(self, match_id, over_number):
        over_data = self._get_over_data(match_id, over_number)
        features = self._extract_over_features(over_data)
        distances, indices = self.over_model.kneighbors([features])
        return self._format_over_response(over_data, indices[0])

# Initialize service
similarity_service = SimilarityService()