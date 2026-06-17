from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.user import User as UserModel
from app.models.warehouse_member import WarehouseMember
from app.schemas.user import User, UserCreate, UserUpdate
from app.schemas.warehouse_member import WarehouseMemberOut

router = APIRouter()

@router.get("/me", response_model=User)
def read_current_user(
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    # The legacy `User.role` column defaults to "user" and was never updated
    # when warehouse roles became authoritative. Surface the warehouse-scoped
    # role so the mobile UI can gate admin features correctly.
    user = current_member.user
    return User(
        id=user.id,
        name=user.name,
        role=current_member.role,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


@router.get("/", response_model=List[User])
def read_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
):
    users = db.query(UserModel).offset(skip).limit(limit).all()
    return users

from app.core.security import get_password_hash

from app.models.warehouse import Warehouse
from app.models.invite import Invite
from app.core.time import utc_now

@router.post("/", response_model=User)
def create_user(user: UserCreate, db: Session = Depends(deps.get_db)):
    db_user = db.query(UserModel).filter(UserModel.name == user.name).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")

    db_user = UserModel(
        name=user.name, 
        role=user.role,
        hashed_password=get_password_hash(user.password)
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    if user.invite_code:
        invite = db.query(Invite).filter(Invite.code == user.invite_code).first()
        if not invite:
            db.delete(db_user)
            db.commit()
            raise HTTPException(status_code=404, detail="Invite code not found")

        # Validate state before consuming. Each failure rolls back the user we
        # just created — caller asked for invite-gated signup, not a free one.
        if invite.revoked:
            db.delete(db_user)
            db.commit()
            raise HTTPException(status_code=400, detail="Invite revoked")
        if invite.expires_at < utc_now():
            db.delete(db_user)
            db.commit()
            raise HTTPException(status_code=400, detail="Invite code expired")
        if invite.max_uses is not None and invite.uses >= invite.max_uses:
            db.delete(db_user)
            db.commit()
            raise HTTPException(status_code=400, detail="Invite exhausted")

        member = WarehouseMember(
            user_id=db_user.id,
            warehouse_id=invite.warehouse_id,
            role=invite.role,
        )
        db.add(member)
        invite.uses += 1
        db.commit()
    else:
        # Create new warehouse for user
        warehouse = Warehouse(name=f"{user.name}'s Warehouse")
        db.add(warehouse)
        db.commit()
        db.refresh(warehouse)
        
        member = WarehouseMember(
            user_id=db_user.id,
            warehouse_id=warehouse.id,
            role="admin"
        )
        db.add(member)
        db.commit()

    return db_user

@router.get("/{user_id}", response_model=User)
def read_user(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.patch("/{user_id}", response_model=User)
def update_user(
    user_id: int,
    user_in: UserUpdate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = user_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)

    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.delete("/{user_id}", response_model=User)
def delete_user(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(user)
    db.commit()
    return user

@router.get("/members/list", response_model=List[WarehouseMemberOut])
def get_members(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    """List members of the current warehouse."""
    rows = (
        db.query(WarehouseMember, UserModel)
        .join(UserModel, UserModel.id == WarehouseMember.user_id)
        .filter(WarehouseMember.warehouse_id == current_member.warehouse_id)
        .all()
    )
    return [
        WarehouseMemberOut(
            id=user.id,
            name=user.name,
            role=member.role,
            joined_at=member.joined_at,
        )
        for member, user in rows
    ]

@router.delete("/members/{user_id}", response_model=Any)
def remove_member(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
):
    """
    Remove a member from the current warehouse.
    Only admin can remove members.
    Cannot remove yourself (use leave endpoint if needed, but for now simple).
    """
    if current_member.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    member_to_remove = db.query(WarehouseMember).filter(
        WarehouseMember.warehouse_id == current_member.warehouse_id,
        WarehouseMember.user_id == user_id
    ).first()
    
    if not member_to_remove:
        raise HTTPException(status_code=404, detail="Member not found")
        
    if member_to_remove.user_id == current_member.user_id:
        raise HTTPException(status_code=400, detail="Cannot remove yourself")

    db.delete(member_to_remove)
    db.commit()
    return {"message": "Member removed"}
