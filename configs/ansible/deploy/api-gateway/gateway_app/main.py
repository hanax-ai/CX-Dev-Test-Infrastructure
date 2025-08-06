# main.py
import os
import logging
import asyncio
import httpx
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

from config import GatewayConfig

# === Initialize Configuration ===
config = GatewayConfig()
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
MODEL_MAP = config.get_model_mapping()  # Simplified interface

# === Logging ===
logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("citadel-gateway")

# === FastAPI App ===
app = FastAPI(title="Citadel AI Unified Gateway")

# === CORS Middleware ===
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# === Pydantic Models ===
class ChatCompletionRequest(BaseModel):
    model: str
    messages: List[Dict[str, Any]]
    stream: Optional[bool] = False
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None

class ModelInfo(BaseModel):
    id: str
    object: str = "model"

class ModelList(BaseModel):
    data: List[ModelInfo]

class OllamaNativeChatRequest(BaseModel):
    model: str
    messages: List[Dict[str, Any]]
    stream: Optional[bool] = False

# === Streaming Proxy ===
async def stream_proxied_response(backend_url: str, payload: ChatCompletionRequest):
    async with httpx.AsyncClient(timeout=300.0) as client:
        try:
            async with client.stream(
                "POST",
                backend_url,
                json=payload.dict(exclude_none=True),
                headers={"Content-Type": "application/json"},
            ) as response:
                response.raise_for_status()
                async for chunk in response.aiter_bytes():
                    yield chunk
        except httpx.HTTPStatusError as e:
            logger.error(f"Backend error {e.response.status_code} from {backend_url}")
            error_chunk = f'data: {{"error": "Backend error: {e.response.status_code}"}}\n\n'
            yield error_chunk.encode()
        except httpx.RequestError as e:
            logger.error(f"Connection failed to {backend_url}: {e}")
            error_chunk = f'data: {{"error": "Connection failed: {str(e)}"}}\n\n'
            yield error_chunk.encode()

# === Endpoints ===
@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/v1/models", response_model=ModelList)
async def list_models():
    """Returns the list of models explicitly defined in the static MODEL_MAP."""
    if not MODEL_MAP:
        logger.warning("No models are defined in the MODEL_MAP configuration.")
        return {"data": []}
    
    models = [{"id": model_id, "object": "model"} for model_id in MODEL_MAP.keys()]
    return {"data": models}

@app.get("/api/tags")
async def api_tags():
    """Provides compatibility for UIs by showing mapped models."""
    if not MODEL_MAP:
        logger.warning("No models are defined in the MODEL_MAP configuration.")
        return {"models": []}
        
    models = [{"name": model_id, "model": model_id} for model_id in MODEL_MAP.keys()]
    logger.info(f"Presenting {len(models)} models from explicit configuration.")
    return {"models": models}

@app.post("/v1/chat/completions")
async def chat_completions(payload: ChatCompletionRequest):
    """Routes chat requests ONLY for models explicitly defined in the MODEL_MAP."""
    model_id = payload.model

    if model_id in MODEL_MAP:
        backend_host = MODEL_MAP[model_id]
        logger.info(f"Routing '{model_id}' using explicit MODEL_MAP to '{backend_host}'")
        backend_url = f"http://{backend_host}/v1/chat/completions"
        return StreamingResponse(
            stream_proxied_response(backend_url, payload),
            media_type="application/x-ndjson" if payload.stream else "application/json",
        )
    else:
        logger.warning(f"Rejecting request for unmapped model_id: '{model_id}'")
        raise HTTPException(
            status_code=404,
            detail=f"Model '{model_id}' not found. This gateway only routes explicitly mapped models."
        )

@app.post("/api/chat")
async def api_chat(payload: OllamaNativeChatRequest):
    """Compatibility endpoint that forwards to the main chat logic."""
    logger.info(f"Received request on native /api/chat for model '{payload.model}'")
    openai_payload = ChatCompletionRequest(
        model=payload.model,
        messages=payload.messages,
        stream=payload.stream
    )
    return await chat_completions(openai_payload)

# === Entrypoint ===
if __name__ == "__main__":
    import uvicorn
    # This allows running the app directly for local testing
    uvicorn.run(
        "main:app",
        host=os.getenv("GATEWAY_HOST", "0.0.0.0"),
        port=int(os.getenv("GATEWAY_PORT", "8000")),
        log_level=LOG_LEVEL.lower(),
        reload=os.getenv("GATEWAY_RELOAD", "false").lower() == "true"
    )