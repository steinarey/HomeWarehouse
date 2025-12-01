import pytest
from typing import Generator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.main import app
from app.api.deps import get_db
from app.core import security
from passlib.context import CryptContext

# Use in-memory SQLite for tests
SQLALCHEMY_DATABASE_URL = "sqlite://"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="session")
def db_engine():
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def db(db_engine):
    connection = db_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)
    yield session
    session.close()
    transaction.rollback()
    connection.close()

@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c

@pytest.fixture(scope="function")
def override_get_db(db):
    def _get_db_override():
        return db
    app.dependency_overrides[get_db] = _get_db_override
    yield
    app.dependency_overrides = {}

@pytest.fixture(scope="session", autouse=True)
def override_password_hasher():
    # Use md5_crypt for faster tests and to avoid bcrypt issues
    security.pwd_context = CryptContext(schemes=["md5_crypt"], deprecated="auto")
    yield
    # Restore original (optional, but good practice if tests were running in same process as app)
    security.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
