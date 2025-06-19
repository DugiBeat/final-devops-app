import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv()

def create_db():
    db = mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", "admin"),
        port=int(os.getenv("DB_PORT", 3306))
    )
    cursor = db.cursor()

    # Create database and use it
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {os.getenv('DB_NAME', 'contacts_app')}")
    cursor.execute(f"USE {os.getenv('DB_NAME', 'contacts_app')}")

    # Create tables if they don't exist
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS contacts (
        number INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255),
        phone VARCHAR(255),
        email VARCHAR(255),
        gender VARCHAR(20),
        photo VARCHAR(255)
    )
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS meetings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255),
        datetime DATETIME,
        reason TEXT,
        status VARCHAR(50) DEFAULT 'Pending'
    )
    """)

    # 🔐 Only insert contacts if table is empty
    cursor.execute("SELECT COUNT(*) FROM contacts")
    count = cursor.fetchone()[0]

    if count == 0:
        example_contacts = [
            ("Amerilio Smith", "6669996661", "Amerilio@Dugibeat.com", "Male", "AmerilioSmith.png"),
            ("Salina Gelberg", "6663333344", "Sali@Dugibeat.com", "Female", "Salina.png"),
            ("Moshe Mevorach", "6667766554", "Moshem@Dugibeat.com", "Male", "MosheM.png"),
            ("Magen Yulis", "6662223344", "MagenY@Dugibeat.com", "Female", "MagenY.png"),
            ("Anita Turnshevsky", "6663333344", "AniT@Dugibeat.com", "Female", "Anita.png"),
            ("Betty Willis", "5552223344", "BettyWill@gmail.com", "Female", "BettyW.png")
        ]
        cursor.executemany("""
        INSERT INTO contacts (name, phone, email, gender, photo)
        VALUES (%s, %s, %s, %s, %s)
        """, example_contacts)
        print("✅ Inserted sample contacts.")
    else:
        print("ℹ️ Contacts table already has data — skipping insert.")

    db.commit()
    cursor.close()
    db.close()
    print("✅ Database and tables ready.")
