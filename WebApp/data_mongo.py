import pymongo
import os
from dotenv import load_dotenv
from bson.objectid import ObjectId

load_dotenv()

client = pymongo.MongoClient(os.getenv("MONGO_URI", "mongodb://localhost:27017/"))
db = client[os.getenv("MONGO_DB_NAME", "contacts_app")]
collection = db["contacts"]

def get_contacts():
    return list(collection.find())

def findByNumber(number):
    try:
        return collection.find_one({"_id": ObjectId(number)})
    except Exception:
        return None

def check_contact_exist(name, email):
    return collection.find_one({"$or": [{"name": name}, {"email": email}]}) is not None

def create_contact(name, phone, email, gender, photo):
    contact = {
        "name": name,
        "phone": phone,
        "email": email,
        "gender": gender,
        "photo": photo
    }
    collection.insert_one(contact)

def delete_contact(number):
    try:
        collection.delete_one({"_id": ObjectId(number)})
    except Exception:
        pass

def update_contact_in_db(number, name, phone, email, gender):
    try:
        collection.update_one(
            {"_id": ObjectId(number)},
            {"$set": {
                "name": name,
                "phone": phone,
                "email": email,
                "gender": gender
            }}
        )
    except Exception:
        pass

def search_contacts(name):
    return list(collection.find({"name": {"$regex": name, "$options": "i"}}))
