import logging
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.user import User
from app.core.security import get_password_hash

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_db() -> None:
    db = SessionLocal()
    
    user = db.query(User).filter(User.name == "Admin").first()
    if not user:
        logger.info("Creating initial user")
        user = User(
            name="Admin",
            hashed_password=get_password_hash("admin"),
            role="admin"
        )
        db.add(user)
        db.commit()
        logger.info("Initial user created")
    else:
        logger.info("User already exists, updating password")
        user.hashed_password = get_password_hash("admin")
        db.add(user)
        db.commit()
        logger.info("Admin password updated")

def main() -> None:
    logger.info("Creating initial data")
    init_db()
    logger.info("Initial data created")

if __name__ == "__main__":
    main()
