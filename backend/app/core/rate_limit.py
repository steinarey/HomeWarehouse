"""Global rate limiter instance.

Single Limiter shared by the app so handlers can decorate themselves with
`@limiter.limit("5/minute")`. Keys on remote IP via `get_remote_address`.
In-memory storage is fine for a single-worker dev setup; for multi-worker
deploys configure a Redis backend via `RATE_LIMIT_STORAGE_URI`.
"""

import os

from slowapi import Limiter
from slowapi.util import get_remote_address


limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=os.getenv("RATE_LIMIT_STORAGE_URI", "memory://"),
)
