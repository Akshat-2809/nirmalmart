from decimal import Decimal
from typing import Annotated
from pydantic import PlainSerializer

# Money is stored as NUMERIC; serialise it as a JSON number, not a string.
Money = Annotated[Decimal, PlainSerializer(lambda v: float(v) if v is not None else None, return_type=float)]
