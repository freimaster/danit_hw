import mysql.connector
import time

class Mysql():
    def __init__(self, host, user, pw):
        max_retries = 30
        retries = 0

        # Keep trying to connect until max_retries
        while retries < max_retries:
            try:
                self.mydb = mysql.connector.connect(
                    host=host,
                    user=user,
                    password=pw
                )
                print("MySQL is ready.")
                break
            except mysql.connector.Error as err:
                print(f"Waiting for MySQL... ({err})")
                time.sleep(1)
                retries += 1

        if retries >= max_retries:
            print("Unable to connect to MySQL. Exiting.")
            exit(1)

    # Helper method to execute queries with connection management
    def query(self, text):
        result = []
        try:
            # Open a cursor for executing the query
            with self.mydb.cursor() as cursor:
                cursor.execute(text)
                try:
                    # Attempt to fetch all results if query returns rows
                    result = cursor.fetchall()
                except mysql.connector.errors.InterfaceError:
                    # No rows to fetch
                    pass
                try:
                    # Commit changes to the database (INSERT, UPDATE, DELETE)
                    self.mydb.commit()
                except Exception as e:
                    print(f"Commit failed: {e}")
        except mysql.connector.Error as err:
            print(f"Query failed: {err}")
        return result

    # Ensure connection is properly closed when no longer needed
    def close_connection(self):
        if self.mydb.is_connected():
            self.mydb.close()
            print("MySQL connection closed.")

