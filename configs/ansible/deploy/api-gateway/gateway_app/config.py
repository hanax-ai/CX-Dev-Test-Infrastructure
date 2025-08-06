# config.py
import os
from pydantic_settings import BaseSettings

class GatewayConfig(BaseSettings):
    """Loads and manages configuration from environment variables."""

    def get_backend_hosts(self) -> list[str]:
        """Dynamically loads all configured OLLAMA_NODE_* hosts."""
        hosts = []
        index = 1
        while True:
            host = os.getenv(f"OLLAMA_NODE_{index}_HOST")
            port = os.getenv(f"OLLAMA_NODE_{index}_PORT")
            if not host or not port:
                break
            hosts.append(f"{host}:{port}")
            index += 1
        return hosts

    def get_model_mapping(self) -> tuple[dict, str]:
        """
        Extracts the explicit model-to-host mappings from environment variables.
        e.g., MODEL_ID_LLAMA3_8B=llama3:8b and MODEL_MAP_LLAMA3_8B=192.168.10.29:11434
        will result in the map {'llama3:8b': '192.168.10.29:11434'}.
        """
        model_map = {}
        for key, value in os.environ.items():
            if key.startswith("MODEL_MAP_") and key != "MODEL_MAP_DEFAULT":
                # Find the corresponding MODEL_ID_* variable
                id_key = key.replace("MODEL_MAP_", "MODEL_ID_")
                original_model_id = os.getenv(id_key)
                if original_model_id:
                    model_map[original_model_id] = value
        
        default_backend = os.getenv("MODEL_MAP_DEFAULT", "")
        return model_map, default_backend