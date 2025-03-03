# app.py
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from typing import List
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
from pymongo import ReturnDocument
import uvicorn
import requests
import json

from sagemaker_client import generate_response  # Handles SageMaker API calls
from medication_matcher import find_closest_medications, model, get_medication_vectors_from_db
from user_utils import serialize_user, User, UserUpdate, MedicationUpdate

app = FastAPI()

# MongoDB Configuration
MONGO_URI = "mongodb+srv://medisaver:revasidem@medilocate.wk6ta.mongodb.net/?retryWrites=true&w=majority&appName=Medilocate"
DB_NAME = "medilocate"
COLLECTION_NAME = "users"
client = AsyncIOMotorClient(MONGO_URI, tls=True, tlsAllowInvalidCertificates=True)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]

def translate_text(text: str, max_new_tokens: int = 500, top_p: float = 0.9, temperature: float = 0.6) -> str:
    """
    Constructs the translation prompt and calls the SageMaker endpoint.
    """
    system_prompt = (
        "Provide me with the following in bullet point form using the information from the FDA that is clear, concise, and easy-to understand." 
        "This current user is 60 year old female that is pregnant." 
        "I want: Drug Name, Ingredients, Purpose and Usage, Dosage and Administration (based on the Age of the patient, do not give irrelevant information that does not fit patient's age)."
        "Adverse Ingredients (use ask_doctor_or_pharmacist for this), Warnings and Adverse Reaction (use the warnings section)"
        "SHOW ONLY IF THE USER IS PREGNANT or breastfeeding (use the warnings section)"
    )

    prompt = (
        "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n"
        f"{system_prompt} <|eot_id|><|start_header_id|>user<|end_header_id|>\n\n"
        f"{text}\n"
        "<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n"
    )
    
    return generate_response(prompt, max_new_tokens, top_p, temperature)

class MedicationResponse(BaseModel):
    results: List[str]

@app.get("/api/medications", response_model=MedicationResponse)
async def get_medications(query: str = Query(..., description="Keywords for medication search"),
                          k: int = Query(3, description="Number of nearest neighbors to return", gt=0)):
    if not query:
        raise HTTPException(status_code=400, detail="Query parameter is required")
    # Load medication vectors from MongoDB collection "medications"
    medication_vectors_db = await get_medication_vectors_from_db(db)
    results = find_closest_medications(query, medication_vectors_db, model, k)
    return MedicationResponse(results=results)

@app.get("/api/fda_translate")
def fda_translate(medication: str = Query(..., description="Medication name to query FDA API"),
                  max_new_tokens: int = Query(256, description="Max tokens for translation"),
                  top_p: float = Query(0.9, description="Top p for translation"),
                  temperature: float = Query(0.6, description="Temperature for translation")):
    # Query FDA API using openFDA's drug label endpoint.
    fda_url = f"https://api.fda.gov/drug/label.json?search=openfda.brand_name:{medication}&limit=1"
    try:
        fda_response = requests.get(fda_url)
        fda_response.raise_for_status()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch FDA data: {str(e)}")
    
    data = fda_response.json()
    if "results" not in data or len(data["results"]) == 0:
        raise HTTPException(status_code=404, detail="No FDA data found for the provided medication")
    
    result = data["results"][0]
    
    def extract_field(key: str):
        value = result.get(key, "")
        if isinstance(value, list):
            return " ".join(value)
        return value

    combined_text = (
        f"Purpose: {extract_field('purpose')}\n"
        f"Indication and Usage: {extract_field('indication_and_usage')}\n"
        f"Active Ingredient: {extract_field('active_ingredient')}\n"
        f"Do not use: {extract_field('do_not_use')}\n"
        f"Warnings: {extract_field('warnings')}\n"
        f"Instruction For Use: {extract_field('instruction_for_use')}\n"
        f"Drug Interactions: {extract_field('drug_interactions')}"
        f"Dosage: {extract_field('dosage_and_administration')}"
        f"Pregnancy or Breastfeeding: {extract_field('pregnancy_or_breast_feeding')}"
        f"Ask Doctor: {extract_field('ask_doctor')}"
        f"Ask Doctor or Pharmacist: {extract_field('ask_doctor_or_pharmacist')}"
    )
    
    try:
        translation_result = translate_text(combined_text, max_new_tokens, top_p, temperature)
        return translation_result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate translation: {str(e)}")

# User-related endpoints remain unchanged
@app.post("/api/users", response_model=dict)
async def get_or_create_user(user: User):
    existing_user = await collection.find_one({"email": user.email})
    if existing_user:
        return {"user": serialize_user(existing_user), "message": "User already exists"}
    
    new_user = await collection.insert_one(user.dict())
    created_user = await collection.find_one({"_id": new_user.inserted_id})
    return {"user": serialize_user(created_user), "message": "User created successfully"}

@app.get("/api/users/{id}", response_model=dict)
async def get_user_by_id(id: str):
    user = await collection.find_one({"_id": ObjectId(id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return serialize_user(user)

@app.put("/api/users/{id}", response_model=dict)
async def update_user(id: str, updates: UserUpdate):
    update_data = {k: v for k, v in updates.dict(exclude_unset=True).items()}
    updated_user = await collection.find_one_and_update(
        {"_id": ObjectId(id)},
        {"$set": update_data},
        return_document=ReturnDocument.AFTER
    )
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user": serialize_user(updated_user), "message": "User updated successfully"}

@app.delete("/api/users/{id}", response_model=dict)
async def delete_user(id: str):
    user = await collection.find_one({"_id": ObjectId(id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await collection.delete_one({"_id": ObjectId(id)})
    return {"message": "User deleted successfully"}

@app.patch("/api/users/{id}/medications", response_model=dict)
async def update_medications(id: str, medication_update: MedicationUpdate):
    user = await collection.find_one({"_id": ObjectId(id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    current_medications = set(user.get("medications", []))
    current_medications.difference_update(medication_update.medicationsToRemove)
    current_medications.update(medication_update.medicationsToAdd)
    
    updated_user = await collection.find_one_and_update(
        {"_id": ObjectId(id)},
        {"$set": {"medications": list(current_medications)}},
        return_document=ReturnDocument.AFTER
    )
    return {"user": serialize_user(updated_user), "message": "Medications updated successfully"}

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8888, reload=True)
