from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api import deps
from app.core.time import utc_now
from app.models.invite import Invite as InviteModel
from app.models.warehouse_member import WarehouseMember
from app.schemas.invite import Invite, InviteCreate

router = APIRouter()


@router.post("/", response_model=Invite)
def create_invite(
    invite_in: InviteCreate,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
) -> Any:
    """Create an invite for the current warehouse. Admin only."""
    if current_member.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    if invite_in.max_uses is not None and invite_in.max_uses < 1:
        raise HTTPException(status_code=400, detail="max_uses must be >= 1")

    invite = InviteModel(
        warehouse_id=current_member.warehouse_id,
        role=invite_in.role,
        created_by_user_id=current_member.user_id,
        max_uses=invite_in.max_uses,
    )
    db.add(invite)
    db.commit()
    db.refresh(invite)
    return invite


@router.get("/", response_model=List[Invite])
def list_invites(
    include_revoked: bool = False,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
) -> Any:
    """List invites for the current warehouse. Admin only."""
    if current_member.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    query = db.query(InviteModel).filter(
        InviteModel.warehouse_id == current_member.warehouse_id
    )
    if not include_revoked:
        query = query.filter(InviteModel.revoked == False)  # noqa: E712
    return query.order_by(InviteModel.created_at.desc()).all()


@router.delete("/{invite_id}", response_model=Invite)
def revoke_invite(
    invite_id: int,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
) -> Any:
    """Revoke an invite by id. Admin only."""
    if current_member.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    invite = db.query(InviteModel).filter(
        InviteModel.id == invite_id,
        InviteModel.warehouse_id == current_member.warehouse_id,
    ).first()
    if invite is None:
        raise HTTPException(status_code=404, detail="Invite not found")

    invite.revoked = True
    db.add(invite)
    db.commit()
    db.refresh(invite)
    return invite


@router.get("/{code}", response_model=Invite)
def get_invite(code: str, db: Session = Depends(deps.get_db)) -> Any:
    """Look up an invite by code. Public — used by registration to validate."""
    invite = db.query(InviteModel).filter(InviteModel.code == code).first()
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")

    if invite.revoked:
        raise HTTPException(status_code=400, detail="Invite revoked")
    if invite.expires_at < utc_now():
        raise HTTPException(status_code=400, detail="Invite expired")
    if invite.max_uses is not None and invite.uses >= invite.max_uses:
        raise HTTPException(status_code=400, detail="Invite exhausted")

    return invite
