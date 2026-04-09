import psycopg2
try:
    conn = psycopg2.connect(
        dbname="POS_DB",
        user="postgres",
        password="1234",
        host="localhost",
        port="5432"
    )
    print("Connection successful!")
    conn.close()
except Exception as e:
    print(f"Error: {e}")
