import os
import sys

# Add app to path
sys.path.append(os.path.abspath("c:/Isitek/Isitek_api"))

from app.database import SessionLocal
from app.models.action_prise import ActionPrise
from app.schemas.action import ActionPriseResponse

db = SessionLocal()
try:
    # Get any action prise from the database
    prise = db.query(ActionPrise).first()
    if prise:
        print("Found a prise in database. Attempting Pydantic validation...")
        response = ActionPriseResponse.model_validate(prise)
        print("Validation succeeded:", response.model_dump())
    else:
        print("No action prises found in database. Let's create a dummy one in memory...")
        from app.models.affaire import AffaireAction
        from app.enums import RolePrise, StatutAction
        from datetime import date
        dummy_aa = AffaireAction(id=1, libelle="Test action")
        dummy_prise = ActionPrise(
            id=1,
            technicien_id=1,
            affaire_action_id=1,
            role_prise=RolePrise.responsable,
            date_prise=date.today(),
            statut=StatutAction.en_cours,
            affaire_action=dummy_aa
        )
        print("Dummy created. Attempting model_validate...")
        response = ActionPriseResponse.model_validate(dummy_prise)
        print("Validation succeeded:", response.model_dump())
except Exception as e:
    print("Error during validation:", str(e))
    import traceback
    traceback.print_exc()
finally:
    db.close()
