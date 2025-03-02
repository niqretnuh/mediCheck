'''
To start run uvicorn app:app --host 0.0.0.0 --port 8888 --reload
'''
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
import uvicorn
from sagemaker_client import generate_response
from medication_matcher import find_closest_medications, medication_vectors, model

app = FastAPI()

@app.get("/generate")
async def generate(input: str = Query(..., description="Input text for translation to bullet points")):
    if not input:
        raise HTTPException(status_code=400, detail="Missing input query parameter")
    
    system_prompt = (
        "Translate the following medication facts into clear, concise, and easy-to-understand bullet points for a general audience. "
        "Each bullet point should summarize one key fact, using simple language without technical jargon. "
        "Ensure that the bullet points are well-structured and maintain the accuracy of the original information."
    )
    
    prompt = (
        "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n"
        f"{system_prompt} <|eot_id|><|start_header_id|>user<|end_header_id|>\n\n"
        f"{input}\n"
        "<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n"
    )
    
    try:
        result = generate_response(prompt)
        return {"response": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate response: {str(e)}")

class MedicationResponse(BaseModel):
    results: list[str]

@app.get("/api/medications", response_model=MedicationResponse)
def get_medications(query: str = Query(..., description="Keywords for medication search"),
                    k: int = Query(3, description="Number of nearest neighbors to return", gt=0)):
    if not query:
        raise HTTPException(status_code=400, detail="Query parameter is required")
    
    results = find_closest_medications(query, medication_vectors, model, k)
    return MedicationResponse(results=results)

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8888, reload=True)
