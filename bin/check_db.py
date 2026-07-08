import sqlite3
import os

db_path = r'C:\Users\Ayman_Tegany\Documents\SpartaGym\sparta_gym_v1.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()
cursor.execute("SELECT * FROM employees")
rows = cursor.fetchall()
print('Employees:', rows)
conn.close()
