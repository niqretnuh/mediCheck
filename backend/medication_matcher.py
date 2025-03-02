# medication_matcher.py
import csv
import numpy as np
from sentence_transformers import SentenceTransformer

class MedicationVector:
    def __init__(self, name: str, vector: np.ndarray):
        self.name = name
        self.vector = vector

def load_medication_vectors(csv_file: str):
    medication_vectors = []
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) < 2:
                    continue
                name = row[0].strip()
                # Convert remaining columns to floats.
                vector = np.array([float(x.strip()) for x in row[1:] if x.strip() != ""], dtype=np.float32)
                medication_vectors.append(MedicationVector(name, vector))
        print(f"Loaded {len(medication_vectors)} medication vectors.")
    except Exception as e:
        print("Error loading CSV file:", e)
    return medication_vectors

def cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return float(np.dot(vec1, vec2) / (norm1 * norm2))

def find_closest_medications(query: str, medication_vectors, model, k: int = 3):
    query_embedding = model.encode(query)
    similarities = []
    for med in medication_vectors:
        sim = cosine_similarity(query_embedding, med.vector)
        similarities.append((med.name, sim))
    similarities.sort(key=lambda x: x[1], reverse=True)
    return [name for name, sim in similarities[:k]]

# Initialize the SentenceTransformer model
model = SentenceTransformer('all-MiniLM-L6-v2')

medication_vectors = load_medication_vectors("medications_vectorized.csv")
