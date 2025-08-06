# config.py
import os
import yaml
import logging
from typing import Dict, List, Optional

# Set up a logger for this module
logger = logging.getLogger(__name__)

class GatewayConfig:
    """
    A centralized class to load and manage gateway configuration from a YAML file.
    """
    def __init__(self, config_path="config.yaml"):
        self.model_map = {}
        self.backend_hosts = []

        try:
            with open(config_path, "r") as f:
                config = yaml.safe_load(f)
                
                # Load the model map directly from the yaml file
                self.model_map = config.get("model_map", {})
                logger.info(f"Successfully loaded {len(self.model_map)} model mappings from {config_path}")

                # Automatically derive the list of unique backend hosts from the model map values
                if self.model_map:
                    self.backend_hosts = sorted(list(set(self.model_map.values())))
                    logger.info(f"Discovered {len(self.backend_hosts)} unique backend hosts.")

            if not self.model_map:
                logger.warning(f"model_map in {config_path} is empty or not found.")

        except FileNotFoundError:
            logger.error(f"CRITICAL: Configuration file not found at '{config_path}'.")
        except Exception as e:
            logger.error(f"CRITICAL: Error loading or parsing {config_path}: {e}")

    def get_model_mapping(self) -> Dict[str, str]:
        """Returns the loaded model-to-host map."""
        return self.model_map

    def get_backend_hosts(self) -> List[str]:
        """Returns the list of unique backend hosts derived from the model map."""
        return self.backend_hosts

    def reload_config(self, config_path="config.yaml"):
        """Reload configuration from file."""
        logger.info(f"Reloading configuration from {config_path}")
        self.__init__(config_path)