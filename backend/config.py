import os
from dotenv import load_dotenv

# Load environment variables from .env file if present
load_dotenv()

class Config:
    # Flask config
    DEBUG = True

    # PostgreSQL database config
    DB_NAME = os.getenv("DB_NAME")
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_HOST = os.getenv("DB_HOST")
    DB_PORT = os.getenv("DB_PORT")

    # Optional: SQLAlchemy support if used
    POSTGRES_DATABASE_URI = (
        f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Hasura GraphQL integration
    HASURA_GRAPHQL_URL = os.getenv("HASURA_GRAPHQL_URL", "https://your-app.hasura.app/v1/graphql")
    HASURA_ADMIN_SECRET = os.getenv("HASURA_ADMIN_SECRET", "your-secret-key")

    # Optional: HuggingFace API keys or other service configs
    HF_API_KEY = os.getenv("HF_API_KEY")