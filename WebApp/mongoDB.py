import pymongo

client = pymongo.MongoClient("mongodb://localhost:27017/")
db = client["contacts_app"]
col = db["contacts"]

example_contacts = [
    {"name": "Anna Rivera", "phone": "1234567890", "email": "anna@example.com", "gender": "Female", "photo": "hodor.jpg"},
    {"name": "John White", "phone": "5551234567", "email": "johnw@example.com", "gender": "Male", "photo": "john.jpg"}
]

col.insert_many(example_contacts)

print("Inserted example contacts into MongoDB")
