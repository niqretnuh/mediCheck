#!/usr/bin/env python3
import csv
import os
import pymongo

# Configuration: You can either hardcode these or load them from environment variables.
MONGO_URI = os.environ.get(
    "MONGO_URI",
    "mongodb+srv://medisaver:revasidem@medilocate.wk6ta.mongodb.net/?retryWrites=true&w=majority&appName=Medilocate"
)
DB_NAME = "medilocate"
COLLECTION_NAME = "medications"

# Create a MongoDB client.
client = pymongo.MongoClient(MONGO_URI, tls=True, tlsAllowInvalidCertificates=True)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]

# Optional: clear existing data in the collection.
collection.delete_many({})

csv_file = "medications_vectorized.csv"  # Path to your CSV file.

documents = []
with open(csv_file, "r", encoding="utf-8") as f:
    reader = csv.reader(f)
    for row in reader:
        if len(row) < 2:
            continue
        name = row[0].strip()
        # Convert the rest of the row to a list of floats.
        vector = [float(x.strip()) for x in row[1:] if x.strip()]
        document = {"name": name, "vector": vector}
        documents.append(document)

if documents:
    result = collection.insert_many(documents)
    print(f"Inserted {len(result.inserted_ids)} documents into the '{COLLECTION_NAME}' collection.")
else:
    print("No documents to insert.")
