import email
import imaplib
import re
from email.header import decode_header
from email.utils import parsedate_to_datetime

from app.config import settings


class EmailNotConfiguredError(Exception):
    pass


def _decode_header_value(value: str | None) -> str:
    if not value:
        return ""
    parts = decode_header(value)
    decoded = []
    for part, charset in parts:
        if isinstance(part, bytes):
            decoded.append(part.decode(charset or "utf-8", errors="replace"))
        else:
            decoded.append(part)
    return " ".join(decoded).strip()


def _extract_body(msg: email.message.Message) -> str:
    body_parts: list[str] = []
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            if content_type == "text/plain":
                payload = part.get_payload(decode=True)
                if payload:
                    charset = part.get_content_charset() or "utf-8"
                    body_parts.append(payload.decode(charset, errors="replace"))
    else:
        payload = msg.get_payload(decode=True)
        if payload:
            charset = msg.get_content_charset() or "utf-8"
            body_parts.append(payload.decode(charset, errors="replace"))
    return "\n".join(body_parts)


def _parse_from(from_header: str) -> tuple[str, str | None]:
    match = re.match(r'"?([^"<]*)"?\s*<([^>]+)>', from_header)
    if match:
        return match.group(2).strip(), match.group(1).strip() or None
    return from_header.strip(), None


def _connect_imap() -> imaplib.IMAP4_SSL:
    if not settings.imap_host or not settings.imap_user or not settings.imap_password:
        raise EmailNotConfiguredError(
            "Email non configuré. Définissez IMAP_HOST, IMAP_USER et IMAP_PASSWORD dans le fichier .env"
        )
    mail = imaplib.IMAP4_SSL(settings.imap_host, settings.imap_port)
    mail.login(settings.imap_user, settings.imap_password)
    mail.select(settings.imap_folder or "INBOX")
    return mail


def fetch_recent_emails(limit: int = 20) -> list[dict]:
    from app.services.reference_extractor import extract_references

    mail = _connect_imap()
    try:
        status, data = mail.search(None, "ALL")
        if status != "OK":
            return []

        ids = data[0].split()
        ids = ids[-limit:] if len(ids) > limit else ids
        ids.reverse()

        emails: list[dict] = []
        for msg_id in ids:
            status, msg_data = mail.fetch(msg_id, "(RFC822)")
            if status != "OK" or not msg_data or not msg_data[0]:
                continue

            raw = msg_data[0][1]
            msg = email.message_from_bytes(raw)
            subject = _decode_header_value(msg.get("Subject"))
            from_raw = _decode_header_value(msg.get("From"))
            from_address, from_name = _parse_from(from_raw)
            date_header = msg.get("Date", "")
            try:
                date_str = parsedate_to_datetime(date_header).isoformat()
            except Exception:
                date_str = date_header

            body = _extract_body(msg)
            preview = body.replace("\n", " ").strip()[:220]
            refs = extract_references(f"{subject}\n{body}")

            emails.append(
                {
                    "message_id": msg_id.decode() if isinstance(msg_id, bytes) else str(msg_id),
                    "subject": subject,
                    "from_address": from_address,
                    "from_name": from_name,
                    "date": date_str,
                    "preview": preview,
                    "body": body,
                    "references": refs,
                }
            )
        return emails
    finally:
        try:
            mail.logout()
        except Exception:
            pass


def fetch_email_by_id(message_id: str) -> dict | None:
    emails = fetch_recent_emails(limit=100)
    for item in emails:
        if item["message_id"] == message_id:
            return item
    return None
