from typing import Generator, Optional
from datetime import datetime
from fastapi import Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.core import security
from app.models.user import User
from app.models.warehouse_member import WarehouseMember
from app.schemas.token import TokenPayload

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl="/login/access-token"
)

def get_db() -> Generator:
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()

def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(reusable_oauth2)
) -> User:
    try:
        payload = jwt.decode(
            token, security.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = TokenPayload(**payload)
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )
    user = db.query(User).filter(User.id == token_data.sub).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

from app.models.warehouse import Warehouse

def get_current_warehouse_member(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    x_warehouse_id: Optional[int] = Header(None, alias="X-Warehouse-Id")
) -> WarehouseMember:
    if x_warehouse_id is None:
        # If no header, try to find the first warehouse the user is a member of
        member = db.query(WarehouseMember).filter(WarehouseMember.user_id == current_user.id).first()
        if not member:
             # SELF-HEAL: If user has no memberships, add them to the default warehouse (ID 1)
             # This handles the migration gap for existing users.
             default_warehouse = db.query(Warehouse).filter(Warehouse.id == 1).first()
             if default_warehouse:
                 member = WarehouseMember(
                     user_id=current_user.id, 
                     warehouse_id=default_warehouse.id, 
                     role="admin",
                     joined_at=datetime.utcnow()
                 )
                 db.add(member)
                 db.commit()
                 db.refresh(member)
                 return member
             
             raise HTTPException(status_code=400, detail="User is not a member of any warehouse")
        return member
    
    member = db.query(WarehouseMember).filter(
        WarehouseMember.user_id == current_user.id,
        WarehouseMember.warehouse_id == x_warehouse_id
    ).first()
    
    if not member:
        raise HTTPException(status_code=403, detail="Not a member of this warehouse")
    
    return member

