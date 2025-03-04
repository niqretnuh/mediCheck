#!/usr/bin/env python3
import csv
import os
import pymongo

MONGO_URI = os.environ.get(
    "MONGO_URI",
    "mongodb+srv://medisaver:revasidem@medilocate.wk6ta.mongodb.net/?retryWrites=true&w=majority&appName=Medilocate"
)
DB_NAME = "medilocate"
COLLECTION_NAME = "medications"

# Create a MongoDB client
client = pymongo.MongoClient(MONGO_URI, tls=True, tlsAllowInvalidCertificates=True)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]

collection.delete_many({})

csv_file = "unique_prod_names.csv"  

documents = []
with open(csv_file, "r", encoding="utf-8") as f:
    reader = csv.reader(f)
    for row in reader:
        if row and row[0].strip():
            documents.append({"name": row[0].strip()})

if documents:
    result = collection.insert_many(documents)
    print(f"Inserted {len(result.inserted_ids)} documents into the '{COLLECTION_NAME}' collection.")
else:
    print("No documents to insert.")
