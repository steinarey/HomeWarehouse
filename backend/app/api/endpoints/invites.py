from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.invite import Invite as InviteModel
from app.models.warehouse_member import WarehouseMember
from app.schemas.invite import Invite, InviteCreate

router = APIRouter()

@router.post("/", response_model=Invite)
def create_invite(
    invite_in: InviteCreate,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member)
) -> Any:
    """
    Create an invite code for the current warehouse.
    Only admins can create invites.
    """
    if current_member.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    invite = InviteModel(
        warehouse_id=current_member.warehouse_id,
        role=invite_in.role,
        created_by_user_id=current_member.user_id
    )
    db.add(invite)
    db.commit()
    db.refresh(invite)
    return invite

@router.get("/{code}", response_model=Invite)
def get_invite(
    code: str,
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Get invite by code. Public endpoint to validate code before registration.
    """
    invite = db.query(InviteModel).filter(InviteModel.code == code).first()
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")
    
    from datetime import datetime
    if invite.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invite expired")
        
    return invite
