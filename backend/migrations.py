import os
from typing import List
from backend.extensions import DBPool

def get_migrations_in_order(migration_dir: str) -> List[str]:
    """Get migration files in proper execution order"""
    migration_order = [
        '00_extensions.sql',
        '01_tables/',
        '02_indexes/',
        '03_views/',
        '04_functions/',
        '05_triggers/',
    ]
    
    migrations = []
    
    for item in migration_order:
        path = os.path.join(migration_dir, item)
        
        if item.endswith('.sql'):
            if os.path.exists(path):
                migrations.append((path, True))  # (path, is_single_file)
        elif os.path.isdir(path):
            dir_migrations = sorted(
                [os.path.join(path, f) for f in os.listdir(path) if f.endswith('.sql')],
                key=lambda x: int(os.path.basename(x).split('_')[0])
            )
            migrations.extend((m, False) for m in dir_migrations)
    
    return migrations

def run_migrations():
    """Execute all SQL files in proper order with transaction control"""
    migration_dir = os.path.join(os.path.dirname(__file__), 'sql')
    migrations = get_migrations_in_order(migration_dir)
    
    with DBPool.connection() as conn:
        for migration_path, is_single_file in migrations:
            with conn.cursor() as cur:
                try:
                    with open(migration_path, 'r') as f:
                        sql = f.read()
                        print(f"Executing migration: {os.path.basename(migration_path)}")
                        
                        # Handle transaction control differently for schema vs data
                        if is_single_file or 'functions' in migration_path or 'triggers' in migration_path:
                            # Schema changes - autocommit
                            conn.autocommit = True
                            cur.execute(sql)
                            conn.autocommit = False
                        else:
                            # Data changes - use transaction
                            cur.execute(sql)
                            
                except Exception as e:
                    print(f"Migration failed on {migration_path}: {e}")
                    raise