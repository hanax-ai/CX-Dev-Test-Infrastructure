import httpx
import logging
import yaml  # <-- Import the YAML library
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

# ===================================================================
# --- Configuration Loader ---
# ===================================================================
MODEL_MAP = {}  # Start with an empty map

try:
    with open("config.yaml", "r") as f:
        config = yaml.safe_load(f)
        MODEL_MAP = config.get("model_map", {})
    if not MODEL_MAP:
        logging.warning("model_map in config.yaml is empty or not found.")
except FileNotFoundError:
    logging.error("CRITICAL: config.yaml not found. The gateway will not be able to route models.")
except Exception as e:
    logging.error(f"CRITICAL: Error loading config.yaml: {e}")
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
