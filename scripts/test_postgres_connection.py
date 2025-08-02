#!/usr/bin/env python3
"""
Remote PostgreSQL connectivity test for Citadel LLM Database
Target: 192.168.10.35:5432
"""

import psycopg2

host = "192.168.10.35"
port = 5432
database = "citadel_llm_db"
user = "citadel_llm_user"
password = "CitadelLLM#2025$SecurePass!"

try:
    print(f"Connecting to PostgreSQL at {host}:{port} as user '{user}'...")
    conn = psycopg2.connect(
        host=host,
        port=port,
        database=database,
        user=user,
        password=password,
        connect_timeout=5
    )
    print("✅ Connection successful.")
    conn.close()
except Exception as e:
    print("❌ Connection failed.")
    print(f"Error: {e}")
