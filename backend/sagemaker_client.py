import json
from config import sagemaker_runtime, ENDPOINT_NAME

def generate_response(prompt: str, max_new_tokens: int = 256, top_p: float = 0.9, temperature: float = 0.6) -> str:
    payload = {
        "inputs": prompt,
        "parameters": {
            "max_new_tokens": max_new_tokens,
            "top_p": top_p,
            "temperature": temperature
        }
    }
    
    response = sagemaker_runtime.invoke_endpoint(
        EndpointName=ENDPOINT_NAME,
        Body=json.dumps(payload),
        ContentType="application/json"
    )
    # The response Body is a stream; read and decode it.
    result = response['Body'].read().decode('utf-8')
    return json.loads(result)
