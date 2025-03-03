from pydantic import BaseModel, EmailStr
from typing import Optional, List
from bson import ObjectId

def serialize_user(user: dict) -> dict:
    user["id"] = str(user["_id"])
    del user["_id"]
    return user

# Pydantic Models for User operations
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
