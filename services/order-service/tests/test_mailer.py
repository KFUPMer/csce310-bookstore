"""Emailing the bill (FR10): the message itself, and that a failure is never passed on.

`FakeSmtp` stands in for the connection to the mail server and records what it
was told to do. Sending through the real Gmail server is not tested here.
"""
import unittest

from order_service.mailer import NoMailer, SmtpMailer, build_message

from .test_bill import ORDER

BILL = "<!DOCTYPE html><html><body>the bill</body></html>"


class FakeSmtp:
    """Records the conversation with a mail server. `fail` makes the login be refused."""

    log: list = []
    fail = False

    def __init__(self, host, port, timeout):
        FakeSmtp.log.append(("connect", host, port))

    def __enter__(self):
        return self

    def __exit__(self, *_):
        FakeSmtp.log.append(("quit",))

    def starttls(self, context=None):
        FakeSmtp.log.append(("starttls",))

    def login(self, user, password):
        if FakeSmtp.fail:
            raise OSError("login refused")
        FakeSmtp.log.append(("login", user))

    def send_message(self, message):
        FakeSmtp.log.append(("send", message))


class BuildMessageTest(unittest.TestCase):
    def setUp(self):
        self.message = build_message(ORDER, BILL, "Bookstore <shop@example.com>")

    def test_is_addressed_to_the_customer(self):
        self.assertEqual(self.message["To"], "alice@example.com")
        self.assertEqual(self.message["From"], "Bookstore <shop@example.com>")
        self.assertEqual(self.message["Subject"], "Your bookstore bill: order 1042")

    def test_the_bill_is_the_html_body_with_a_plain_text_version(self):
        plain = self.message.get_body(preferencelist=("plain",)).get_content()
        html = self.message.get_body(preferencelist=("html",)).get_content()
        self.assertIn("order 1042", plain)
        self.assertIn("$88.00", plain)
        self.assertEqual(html.strip(), BILL)


class SmtpMailerTest(unittest.TestCase):
    def setUp(self):
        FakeSmtp.log = []
        FakeSmtp.fail = False
        self.mailer = SmtpMailer("smtp.example.com", 587, "shop@example.com", "app-password", "Bookstore <shop@example.com>", smtp=FakeSmtp)

    def test_sends_the_bill_over_an_encrypted_connection(self):
        self.assertTrue(self.mailer.send_bill(ORDER, BILL))
        self.mailer.close()  # waits for the background send
        steps = [entry[0] for entry in FakeSmtp.log]
        self.assertEqual(steps, ["connect", "starttls", "login", "send", "quit"])
        self.assertEqual(FakeSmtp.log[0], ("connect", "smtp.example.com", 587))
        self.assertEqual(FakeSmtp.log[3][1]["To"], "alice@example.com")

    def test_a_failed_send_is_logged_and_not_raised(self):
        FakeSmtp.fail = True
        with self.assertLogs("order_service.mailer", level="ERROR") as logs:
            self.assertTrue(self.mailer.send_bill(ORDER, BILL))
            self.mailer.close()
        self.assertIn("order 1042", logs.output[0])
        self.assertNotIn("app-password", "".join(logs.output))


class NoMailerTest(unittest.TestCase):
    def test_sends_nothing_and_says_so(self):
        self.assertFalse(NoMailer().send_bill(ORDER, BILL))


if __name__ == "__main__":
    unittest.main()
