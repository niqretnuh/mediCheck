import numpy as np
from sentence_transformers import SentenceTransformer
from typing import List, Optional
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


model = SentenceTransformer('all-MiniLM-L6-v2')
# Cache
_cached_medication_vectors: Optional[List[MedicationVector]] = None

async def get_medication_vectors_from_db(db: AsyncIOMotorDatabase) -> List[MedicationVector]:
    """
    Asynchronously retrieves all medication documents from the "medications" collection,
    converting each document's vector field into a numpy array. Results are cached for subsequent calls.
    """
    global _cached_medication_vectors
    if _cached_medication_vectors is not None:
        return _cached_medication_vectors

    medication_vectors = []
    # Use projection to only retrieve 'name' and 'vector'
    cursor = db["medications"].find({}, {"name": 1, "vector": 1}).batch_size(1000)
    async for doc in cursor:
        name = doc.get("name")
        vector = doc.get("vector")
        if name and vector:
            medication_vectors.append(MedicationVector(name, np.array(vector, dtype=np.float32)))
    _cached_medication_vectors = medication_vectors
    return medication_vectors
