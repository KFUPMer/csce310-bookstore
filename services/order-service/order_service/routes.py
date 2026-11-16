"""The endpoints under /api/orders.

Each one: find out who is asking, check the request, call the service, return
the answer. No rules live here, and no error responses are built here: routes
raise, and errors.py answers.
"""
from flask import Blueprint, Response, jsonify, request

from .auth import SessionChecker, require_customer, require_manager, token_from
from .models import CurrentUser
from .schemas import OrderInput, PaymentStatusInput
from .services import OrderService

# The bill is shown inside the apps. This tells whatever shows it that the page may use its
# own styles and nothing else: no scripts, no images or addresses from outside.
BILL_CONTENT_POLICY = "default-src 'none'; style-src 'unsafe-inline'"


def create_routes(orders: OrderService, sessions: SessionChecker) -> Blueprint:
    routes = Blueprint("orders", __name__, url_prefix="/api/orders")

    def current_user() -> CurrentUser:
        """N4: every endpoint needs a valid session token."""
        return sessions.check(token_from(request.headers.get("Authorization")))

    def json_body():
        # silent=False: a body that is not JSON becomes a 400 through errors.py.
        return request.get_json(force=True, silent=False)

    @routes.post("")
    def place():
        """POST /api/orders (FR6-FR10). Customers only."""
        user = current_user()
        require_customer(user)
        placed = orders.place(user, OrderInput.from_json(json_body()))
        return jsonify({**placed.order.to_json(), "billHtml": placed.bill_html, "emailQueued": placed.email_queued}), 201

    @routes.get("")
    def list_all():
        """GET /api/orders (FR12). Managers only."""
        require_manager(current_user())
        return jsonify([order.to_summary_json() for order in orders.list_all()])

    @routes.get("/<int:order_id>/bill")
    def bill(order_id: int):
        """GET /api/orders/{id}/bill (FR8, FR9). The customer who placed the order, or a manager."""
        bill_html = orders.bill_for(order_id, current_user())
        return Response(bill_html, mimetype="text/html", headers={"Content-Security-Policy": BILL_CONTENT_POLICY})

    @routes.patch("/<int:order_id>/payment-status")
    def set_payment_status(order_id: int):
        """PATCH /api/orders/{id}/payment-status (FR13). Managers only."""
        require_manager(current_user())
        status = PaymentStatusInput.from_json(json_body())
        return jsonify(orders.set_payment_status(order_id, status.payment_status).to_summary_json())

    return routes
