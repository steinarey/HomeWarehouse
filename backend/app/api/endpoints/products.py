from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.product import Product as ProductModel
from app.schemas.product import Product, ProductCreate, ProductUpdate, ProductByBarcodeRequest

router = APIRouter()

@router.get("/", response_model=List[Product])
def read_products(skip: int = 0, limit: int = 100, db: Session = Depends(deps.get_db)):
    products = db.query(ProductModel).offset(skip).limit(limit).all()
    return products

@router.post("/", response_model=Product)
def create_product(product: ProductCreate, db: Session = Depends(deps.get_db)):
    db_product = ProductModel(**product.model_dump())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.get("/{product_id}", response_model=Product)
def read_product(product_id: int, db: Session = Depends(deps.get_db)):
    product = db.query(ProductModel).filter(ProductModel.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.patch("/{product_id}", response_model=Product)
def update_product(product_id: int, product_in: ProductUpdate, db: Session = Depends(deps.get_db)):
    product = db.query(ProductModel).filter(ProductModel.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    
    update_data = product_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@router.delete("/{product_id}", response_model=Product)
def delete_product(product_id: int, db: Session = Depends(deps.get_db)):
    product = db.query(ProductModel).filter(ProductModel.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    
    db.delete(product)
    db.commit()
    return product

@router.post("/by-barcode", response_model=Any)
def get_product_by_barcode(request: ProductByBarcodeRequest, db: Session = Depends(deps.get_db)):
    product = db.query(ProductModel).filter(ProductModel.barcode == request.barcode).first()
    if product:
        return Product.model_validate(product)
    return {"exists": False}
