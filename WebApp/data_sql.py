import mysql.connector
from dotenv import load_dotenv
import os
from datetime import datetime

load_dotenv()

db = mysql.connector.connect(
    host=os.getenv("DB_HOST", "localhost"),
    user=os.getenv("DB_USER", "root"),
    password=os.getenv("DB_PASSWORD", "admin"),
    database=os.getenv("DB_NAME", "contacts_app"),
    port=int(os.getenv("DB_PORT", 3306))
)

cursor = db.cursor(dictionary=True)

# ------------------ Contacts ------------------
def get_contacts():
    cursor.execute("SELECT * FROM contacts")
    return cursor.fetchall()

def findByNumber(number):
    cursor.execute("SELECT * FROM contacts WHERE number = %s", (number,))
    return cursor.fetchone()

def check_contact_exist(name, email):
    cursor.execute("SELECT * FROM contacts WHERE name = %s OR email = %s", (name, email))
    return bool(cursor.fetchone())

def create_contact(name, phone, email, gender, photo):
    cursor.execute("INSERT INTO contacts (name, phone, email, gender, photo) VALUES (%s, %s, %s, %s, %s)",
                   (name, phone, email, gender, photo))
    db.commit()

def update_contact_in_db(number, name, phone, email, gender):
    cursor.execute("UPDATE contacts SET name = %s, phone = %s, email = %s, gender = %s WHERE number = %s",
                   (name, phone, email, gender, number))
    db.commit()

def delete_contact(number):
    cursor.execute("DELETE FROM contacts WHERE number = %s", (number,))
    db.commit()

def search_contacts(search_name):
    cursor.execute("SELECT * FROM contacts WHERE name LIKE %s", ('%' + search_name + '%',))
    return cursor.fetchall()

# ------------------ Meetings ------------------
def create_meeting(name, email, datetime_str, reason, status="Pending"):
    cursor.execute("""
        INSERT INTO meetings (name, email, datetime, reason, status)
        VALUES (%s, %s, %s, %s, %s)
    """, (name, email, datetime_str, reason, status))
    db.commit()

def get_all_meetings():
    cursor.execute("SELECT * FROM meetings ORDER BY datetime DESC")
    meetings = cursor.fetchall()
    for m in meetings:
        if isinstance(m['datetime'], datetime):
            m['datetime'] = m['datetime'].strftime("%Y-%m-%d %H:%M")
        else:
            m['datetime'] = str(m['datetime'])
    return meetings
