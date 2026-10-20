from decimal import Decimal
from typing import Annotated
from pydantic import PlainSerializer

# Money is stored as NUMERIC; serialise it as a JSON number, not a string.
Money = Annotated[Decimal, PlainSerializer(lambda v: float(v) if v is not None else None, return_type=float)]

# Shared input rules (Unicode letter classes so Marathi names are accepted too)
NAME_PATTERN = r"^[\p{L}\p{M}][\p{L}\p{M} .'\-]*$"     # letters, spaces, . ' -
CITY_PATTERN = r"^[\p{L}\p{M}][\p{L}\p{M} .\-]*$"      # letters, spaces, . -
MOBILE_PATTERN = r"^[6-9][0-9]{9}$"                      # Indian mobile: 10 digits starting 6-9
PINCODE_PATTERN = r"^[1-9][0-9]{5}$"
