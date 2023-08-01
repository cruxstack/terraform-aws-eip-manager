import os

LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")

POOL_TAG_KEY = os.environ.get("POOL_TAG_KEY", "elastic-ip-manager-pool")
POOL_TAG_VALUES = [x.strip() for x in os.environ.get("POOL_TAG_VALUES", "").split(",")]
POOL_FILTER_ENABLED = len(POOL_TAG_VALUES) != 0
