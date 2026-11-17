import 'package:bookstore_ui/bookstore_ui.dart';

/// order-service, the manager's side: every order, one order, its bill, and its
/// payment status (FR8, FR9, FR12, FR13). Every call needs a manager's session (N5).
class OrderApi extends ApiClient {
  OrderApi(Session session, {String baseUrl = orderServiceUrl}) : super(baseUrl, session, serviceName: 'The order service');

  /// FR12: every order, newest first. The rows have no items.
  Future<List<Order>> listOrders() async {
    final json = await get('/api/orders') as List;
    return [for (final o in json) Order.fromJson(o as Map<String, dynamic>)];
  }

  /// One order with its items and the customer's email.
  Future<Order> getOrder(int id) async => Order.fromJson(await get('/api/orders/$id') as Map<String, dynamic>);

  /// FR13: PAID, or back to PENDING to correct a mistake. Returns the order as a list row.
  Future<Order> setPaymentStatus(int id, String status) async =>
      Order.fromJson(await patch('/api/orders/$id/payment-status', {'paymentStatus': status}) as Map<String, dynamic>);

  /// FR9: the saved HTML bill, for printing.
  Future<String> billHtml(int id) async => await get('/api/orders/$id/bill') as String;
}
