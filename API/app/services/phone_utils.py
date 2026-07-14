import re


def normalize_phone_digits(phone: str) -> str:
    return re.sub(r"\D", "", phone or "")


def phone_suffix(phone: str, length: int = 10) -> str:
    digits = normalize_phone_digits(phone)
    if len(digits) <= length:
        return digits
    return digits[-length:]


def phones_match(phone_a: str, phone_b: str) -> bool:
    a = normalize_phone_digits(phone_a)
    b = normalize_phone_digits(phone_b)
    if not a or not b:
        return False
    if a == b:
        return True
    min_len = min(len(a), len(b), 10)
    if min_len >= 8:
        return a[-min_len:] == b[-min_len:]
    return False
