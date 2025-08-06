import httpx
import logging
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

# ===================================================================
# --- Configuration: The Only Part You Need to Edit ---
# ===================================================================
# This dictionary is the single source of truth.
# Map your model names to the full IP:PORT of the backend server.
MODEL_MAP = {
    # Models on hx-llm-server-01 (192.168.10.29)
    "llama3.2:3b": "192.168.10.29:11434",
    "llama3:8b": "192.168.10.29:11434",

    # Models on hx-llm-server-02 (192.168.10.28)
    "llama4:16x17b": "192.168.10.28:11434",
    "mistral:7b": "192.168.10.28:11434",
    "qwen3:8b": "192.168.10.28:11434",
    
    # This model exists on both, we'll route to server 1
    "nous-hermes2:latest": "192.168.10.29:11434"
}
# ===================================================================

# --- Logging Setup ---
logging.basicConfig(level="INFO", format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("webui-gateway")

# --- FastAPI App ---
app = FastAPI(title="Custom WebUI Gateway")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

# --- Pydantic Models for Ollama's Native API ---
class OllamaChatRequest(BaseModel):
    model: str
    messages: List[Dict[str, Any]]
    stream: Optional[bool] = True

# --- Streaming Proxy Helper ---
async def stream_ollama_response(backend_url: str, payload: OllamaChatRequest):
    async with httpx.AsyncClient(timeout=300.0) as client:
        try:
            async with client.stream(
                "POST", backend_url, json=payload.dict(exclude_none=True), headers={"Content-Type": "application/json"}
            ) as response:
                response.raise_for_status()
                async for chunk in response.aiter_bytes():
                    yield chunk
        except httpx.HTTPStatusError as e:
            logger.error(f"Backend error: {e.response.status_code} - {e.response.text}")
            yield f'{{"error": "Backend server returned an error."}}'.encode()
        except httpx.RequestError as e:
            logger.error(f"Connection failed: {e}")
            yield f'{{"error": "Failed to connect to backend server."}}'.encode()

# --- API Endpoints ---
@app.get("/api/tags")
async def api_tags():
    """Returns the list of models defined in our MODEL_MAP."""
    logger.info(f"Serving model list from configuration.")
    models = [{"name": model_id, "model": model_id} for model_id in MODEL_MAP.keys()]
    return {"models": models}

@app.post("/api/chat")
async def api_chat(payload: OllamaChatRequest):
    """Routes chat requests for models in our MODEL_MAP."""
    model_id = payload.model
    
    if model_id in MODEL_MAP:
        backend_host = MODEL_MAP[model_id]
        logger.info(f"Routing '{model_id}' to '{backend_host}'")
        
        # Note: We are forwarding to Ollama's native /api/chat endpoint
        backend_url = f"http://{backend_host}/api/chat"
        
        return StreamingResponse(
            stream_ollama_response(backend_url, payload),
            media_type="application/x-ndjson",
        )
    else:
        logger.warning(f"Rejecting request for unmapped model: '{model_id}'")
        raise HTTPException(
            status_code=404, detail=f"Model '{model_id}' not found in gateway configuration."
        )

# --- Entry Point ---
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
