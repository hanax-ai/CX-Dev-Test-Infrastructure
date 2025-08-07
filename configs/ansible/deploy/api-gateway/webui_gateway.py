import httpx
import logging
import os
import sys
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

# --- The only configuration logic needed is to import and instantiate the class ---
from gateway_app.config import GatewayConfig

# ===================================================================
# --- Centralized Configuration with Dynamic Path Resolution ---
# ===================================================================
# Get the directory of this script for consistent file location
script_dir = Path(__file__).parent.absolute()
config_path = script_dir / "gateway_app" / "config.yaml"

try:
    config = GatewayConfig(config_path=str(config_path))
    MODEL_MAP = config.get_model_mapping()
    
    # Enhanced validation for MODEL_MAP entries
    if not MODEL_MAP:
        logging.error("CRITICAL: No model mappings found in configuration!")
        raise RuntimeError("Configuration validation failed: Empty model map")
    
    # Validate each MODEL_MAP entry
    invalid_entries = []
    for model_name, backend_host in MODEL_MAP.items():
        # Check model name is a non-empty string
        if not isinstance(model_name, str) or not model_name.strip():
            invalid_entries.append(f"Invalid model name: '{model_name}' (must be non-empty string)")
        
        # Check backend host format (should be host:port)
        if not isinstance(backend_host, str) or not backend_host.strip():
            invalid_entries.append(f"Invalid backend host for '{model_name}': '{backend_host}' (must be non-empty string)")
        elif ':' not in backend_host or len(backend_host.split(':')) != 2:
            invalid_entries.append(f"Invalid backend host format for '{model_name}': '{backend_host}' (expected format: host:port)")
        else:
            # Validate port is numeric
            try:
                host, port = backend_host.split(':')
                if not host.strip():
                    invalid_entries.append(f"Empty host in '{model_name}': '{backend_host}'")
                port_num = int(port)
                if not (1 <= port_num <= 65535):
                    invalid_entries.append(f"Invalid port range for '{model_name}': {port_num} (must be 1-65535)")
            except ValueError:
                invalid_entries.append(f"Non-numeric port for '{model_name}': '{backend_host}'")
    
    # Log validation results
    if invalid_entries:
        for error in invalid_entries:
            logging.error(f"Configuration validation error: {error}")
        raise RuntimeError(f"Configuration validation failed: {len(invalid_entries)} invalid entries found")
    else:
        logging.info(f"Configuration validation passed: {len(MODEL_MAP)} valid model mappings loaded")
        for model, host in MODEL_MAP.items():
            logging.info(f"  ✓ {model} → {host}")

except Exception as e:
    logging.error(f"CRITICAL: Failed to load or validate configuration: {e}")
    # Exit with error to prevent running with invalid configuration
    sys.exit(1)
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
    models = [{"name": model_id, "model": model_id} for model_id in MODEL_MAP]
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
