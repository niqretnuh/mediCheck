# vectorize_medications.py
from sentence_transformers import SentenceTransformer
import csv

# Initialize the model – you can choose any suitable model.
model = SentenceTransformer('all-MiniLM-L6-v2')

# Load medication names from a CSV file (each line contains a medication name)
with open('unique_prod_names.csv', 'r', encoding='utf-8') as f:
    medications = [line.strip() for line in f if line.strip()]

# Open an output CSV to write the vectorized medications.
with open('medications_vectorized.csv', 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)
    # For each medication, compute its vector and write it out.
    for med in medications:
        vector = model.encode(med)
        row = [med] + list(vector)
        writer.writerow(row)
