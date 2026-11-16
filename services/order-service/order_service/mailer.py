"""Emails the bill to the customer (FR10, extra credit).

The email is a copy; the saved bill file is the required part. So sending
must never fail or slow down an order: `SmtpMailer` hands the message to a
background thread and returns at once, and a failed send is logged, not
raised (architecture decision 6).

`Mailer` is the interface. `SmtpMailer` sends through a mail server such as
Gmail. `NoMailer` is used when no mail account is configured.
"""
import logging
import smtplib
import ssl
from abc import ABC, abstractmethod
from concurrent.futures import ThreadPoolExecutor
from email.message import EmailMessage

from .bill import money
from .models import Order

log = logging.getLogger(__name__)

# How long to wait for the mail server at each step, in seconds.
TIMEOUT = 15


def build_message(order: Order, bill_html: str, mail_from: str) -> EmailMessage:
    """The email: the bill as the HTML body, with a short plain-text version for mail programs that show no HTML."""
    message = EmailMessage()
    message["From"] = mail_from
    message["To"] = order.email
    message["Subject"] = f"Your bookstore bill: order {order.id}"
    message.set_content(
        f"Hello {order.username},\n\n"
        f"Thank you for your order. This is the bill for order {order.id}.\n"
        f"Total amount due: {money(order.total)}\n\n"
        "The full bill is in the HTML part of this email.\n"
    )
    message.add_alternative(bill_html, subtype="html")
    return message


class Mailer(ABC):
    @abstractmethod
    def send_bill(self, order: Order, bill_html: str) -> bool:
        """Email the bill to the customer who placed the order.

        Returns True if the email was handed over for sending, False if email is switched off.
        True is not a promise of delivery: the send itself happens afterwards."""


class NoMailer(Mailer):
    """Email is not configured: nothing is sent."""

    def send_bill(self, order: Order, bill_html: str) -> bool:
        return False


class SmtpMailer(Mailer):
    """Sends through an SMTP server over an encrypted connection (STARTTLS), in the background."""

    def __init__(self, host: str, port: int, user: str, password: str, mail_from: str, smtp=smtplib.SMTP):
        self._host, self._port, self._user, self._password, self._mail_from = host, port, user, password, mail_from
        self._smtp = smtp  # the class that opens the connection; tests pass a stand-in
        # One worker: emails leave one at a time, in order, without holding up any request.
        self._worker = ThreadPoolExecutor(max_workers=1, thread_name_prefix="mail")

    def send_bill(self, order: Order, bill_html: str) -> bool:
        self._worker.submit(self._send, order, bill_html)
        return True

    def close(self) -> None:
        """Wait for emails still being sent, then stop."""
        self._worker.shutdown(wait=True)

    def _send(self, order: Order, bill_html: str) -> None:
        try:
            message = build_message(order, bill_html, self._mail_from)
            with self._smtp(self._host, self._port, timeout=TIMEOUT) as server:
                server.starttls(context=ssl.create_default_context())
                server.login(self._user, self._password)
                server.send_message(message)
            log.info("Emailed the bill for order %s", order.id)
        except Exception as error:  # noqa: BLE001 - nothing may escape: there is nobody left to tell
            # The error's own text only: no traceback, which could show the arguments of login().
            log.error("Could not email the bill for order %s: %s: %s", order.id, type(error).__name__, error)
