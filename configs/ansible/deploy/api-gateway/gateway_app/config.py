# config.py
import yaml
import logging
from typing import Dict, Tuple, Optional

logger = logging.getLogger(__name__)

class GatewayConfig:
    def __init__(self, config_file: str = "config.yaml"):
        self.config_file = config_file
        self._model_map = {}
        self._load_config()

    def _load_config(self):
        """Load configuration from YAML file."""
        try:
            with open(self.config_file, "r") as f:
                config = yaml.safe_load(f)
                self._model_map = config.get("model_map", {})
            
            if not self._model_map:
                logger.warning(f"model_map in {self.config_file} is empty or not found.")
            else:
                logger.info(f"Loaded {len(self._model_map)} model mappings from {self.config_file}")
                
        except FileNotFoundError:
            logger.error(f"CRITICAL: {self.config_file} not found. Gateway will not be able to route models.")
        except yaml.YAMLError as e:
            logger.error(f"CRITICAL: Invalid YAML in {self.config_file}: {e}")
        except Exception as e:
            logger.error(f"CRITICAL: Error loading {self.config_file}: {e}")

    def get_model_mapping(self) -> Tuple[Dict[str, str], Optional[str]]:
        """
        Returns the model mapping and any default backend.
        
        Returns:
            Tuple of (model_map, default_backend)
            model_map: Dict mapping model names to backend hosts
            default_backend: None (we only use explicit mappings)
        """
        return self._model_map, None

    def reload_config(self):
        """Reload configuration from file."""
        logger.info(f"Reloading configuration from {self.config_file}")
        self._load_config()