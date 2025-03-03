from fastapi import FastAPI, HTTPException, Query, Body
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
import uvicorn
import json
import requests


from sagemaker_client import generate_response 
from medication_matcher import find_closest_medications, medication_vectors, model

app = FastAPI()
# MongoDB Configuration
MONGO_URI = "mongodb+srv://medisaver:revasidem@medilocate.wk6ta.mongodb.net/?retryWrites=true&w=majority&appName=Medilocate"
DB_NAME = "medilocate"
COLLECTION_NAME = "users"
client = AsyncIOMotorClient(MONGO_URI, tls = True, tlsAllowInvalidCertificates = True)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]


def translate_text(text: str, max_new_tokens: int = 256, top_p: float = 0.9, temperature: float = 0.6) -> str:
    """
    Constructs the translation prompt using a system prompt and the given text,
    then calls the SageMaker endpoint via generate_response.
    """
    system_prompt = (
        "Translate the following medication facts into clear, concise, and easy-to-understand bullet points that are personable, instructive, and professional. "
        "Each bullet point should summarize one key fact—whether it is a description, active ingredient, adverse reaction, instruction, or drug interactions for use—in a friendly and engaging tone. "
        "For every line, if no information is provided, put 'Seek medical professionals for advice'."
        "Output each bullet point on a separate line so that the response can be returned as an array of strings."
    )
    
    prompt = (
        "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n"
        f"{system_prompt} <|eot_id|><|start_header_id|>user<|end_header_id|>\n\n"
        f"{text}\n"
        "<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n"
    )
    
    return generate_response(prompt, max_new_tokens, top_p, temperature)

class MedicationResponse(BaseModel):
    results: list[str]

@app.get("/api/medications", response_model=MedicationResponse)
def get_medications(query: str = Query(..., description="Keywords for medication search"),
                    k: int = Query(3, description="Number of nearest neighbors to return", gt=0)):
    if not query:
        raise HTTPException(status_code=400, detail="Query parameter is required")
    
    results = find_closest_medications(query, medication_vectors, model, k)
    return MedicationResponse(results=results)

@app.get("/fda_translate")
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

    description = extract_field("description")
    active_ingredient = extract_field("active_ingredient")
    adverse_reaction = extract_field("adverse_reaction")
    instruction_for_use = extract_field("instruction_for_use")
    drug_interactions = extract_field("drug_interactions")
    
    combined_text = (
        f"Description: {description}\n"
        f"Active Ingredient: {active_ingredient}\n"
        f"Adverse Reaction: {adverse_reaction}\n"
        f"Instruction For Use: {instruction_for_use}"
        f"Drug Interactions: {drug_interactions}"
    )
    
    try:
        translation_result = translate_text(combined_text, max_new_tokens, top_p, temperature)
        return translation_result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate translation: {str(e)}")

class User(BaseModel):
    name: str
    email: EmailStr
    medications: List[str]
    gender: str
    dateofbirth: str
    pregnant: bool

class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    medications: Optional[List[str]] = None
    gender: Optional[str] = None
    dateofbirth: Optional[str] = None
    pregnant: Optional[bool] = None

class MedicationUpdate(BaseModel):
    medicationsToAdd: Optional[List[str]] = []
    medicationsToRemove: Optional[List[str]] = []

def serialize_user(user):
    user["id"] = str(user["_id"])
    del user["_id"]
    return user

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
        return_document=True
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
        return_document=True
    )
    return {"user": serialize_user(updated_user), "message": "Medications updated successfully"}
uvicorn.run("app:app", host="0.0.0.0", port=8888, reload=True)
