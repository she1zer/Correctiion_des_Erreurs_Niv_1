from sqlalchemy.orm import Session

from app.models.authorized_phone import AuthorizedEmployeePhone
from app.services.phone_utils import phones_match


def is_employee_phone_authorized(db: Session, telephone: str) -> bool:
    rows = (
        db.query(AuthorizedEmployeePhone)
        .filter(AuthorizedEmployeePhone.is_active.is_(True))
        .all()
    )
    return any(phones_match(row.telephone, telephone) for row in rows)
