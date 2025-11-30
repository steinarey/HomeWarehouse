from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

hash_from_migration = "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW"
password = "admin"

try:
    is_valid = pwd_context.verify(password, hash_from_migration)
    print(f"Hash valid: {is_valid}")
except Exception as e:
    print(f"Error verifying: {e}")

new_hash = pwd_context.hash(password)
print(f"New hash for 'admin': {new_hash}")
