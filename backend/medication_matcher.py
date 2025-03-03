# medication_matcher.py
import numpy as np
from sentence_transformers import SentenceTransformer
from typing import List
from motor.motor_asyncio import AsyncIOMotorDatabase

class MedicationVector:
    def __init__(self, name: str, vector: np.ndarray):
        self.name = name
        self.vector = vector

def cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return float(np.dot(vec1, vec2) / (norm1 * norm2))

def find_closest_medications(query: str, medication_vectors: List[MedicationVector], model, k: int = 3) -> List[str]:
    query_embedding = model.encode(query)
    similarities = []
    for med in medication_vectors:
        sim = cosine_similarity(query_embedding, med.vector)
        similarities.append((med.name, sim))
    similarities.sort(key=lambda x: x[1], reverse=True)
    return [name for name, sim in similarities[:k]]

# Initialize the SentenceTransformer model.
model = SentenceTransformer('all-MiniLM-L6-v2')

async def get_medication_vectors_from_db(db: AsyncIOMotorDatabase) -> List[MedicationVector]:
    """
    Asynchronously retrieves all medication documents from the "medications" collection,
    converting each document's vector field into a numpy array.
    """
    medication_vectors = []
    cursor = db["medications"].find({})
    async for doc in cursor:
        name = doc.get("name")
        vector = doc.get("vector")
        if name and vector:
            # Ensure the vector is stored as a numpy array (float32)
            medication_vectors.append(MedicationVector(name, np.array(vector, dtype=np.float32)))
    return medication_vectors
