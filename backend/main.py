import os
import mysql.connector
from fastapi import FastAPI

app = FastAPI()

MYSQL_HOST = "mysql-service"
MYSQL_USER = "root"
MYSQL_PASSWORD = os.getenv("MYSQL_ROOT_PASSWORD")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")

@app.get("/")
def read_root():
    return {"message": "FastAPI is running!"}

@app.get("/db")
def read_db():
    try:
        conn = mysql.connector.connect(
            host=MYSQL_HOST,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DATABASE
        )
        cursor = conn.cursor()
        cursor.execute("SELECT 'Connected to MySQL' AS message;")
        result = cursor.fetchone()
        conn.close()
        return {"db_message": result[0]}
    except Exception as e:
        return {"error": str(e)}
