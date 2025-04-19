import psycopg2
from psycopg2 import pool
from flask import current_app
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class DBPool:
    _instance = None
    
    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = psycopg2.pool.SimpleConnectionPool(
                minconn=1,
                maxconn=10,
                host=os.getenv("DB_HOST"),
                database=os.getenv('DB_NAME'),
                user=os.getenv('DB_USER'),
                password=os.getenv('DB_PASSWORD'),
                port=os.getenv("DB_PORT")
            )
        return cls._instance

    @classmethod
    def get_conn(cls):
        return cls.get_instance().getconn()

    @classmethod
    def put_conn(cls, conn):
        cls.get_instance().putconn(conn)

    @classmethod
    def close_all(cls):
        cls.get_instance().closeall()