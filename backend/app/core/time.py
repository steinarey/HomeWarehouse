"""UTC time helpers.

`datetime.utcnow()` is deprecated in Python 3.12 because it returns a naive
datetime that's actually UTC, which lies about the timezone. Use
`utc_now()` everywhere instead. We still store naive values in the DB to
avoid a schema migration; the helper just centralizes the awareness gap.
"""

from datetime import datetime, timezone


def utc_now() -> datetime:
    """Current UTC instant as a naive datetime (DB columns are naive)."""
    return datetime.now(timezone.utc).replace(tzinfo=None)
