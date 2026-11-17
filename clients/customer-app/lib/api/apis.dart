import 'package:bookstore_ui/bookstore_ui.dart';

import '../models/order_draft.dart';

/// order-service, the customer's side. The user and book clients are shared
/// with the management app (bookstore-ui).
class OrderApi extends ApiClient {
  OrderApi(Session session, {String baseUrl = orderServiceUrl}) : super(baseUrl, session, serviceName: 'The order service');

  /// FR6-FR10: place the order.
  Future<Order> createOrder(OrderDraft draft) async => Order.fromJson(await post('/api/orders', draft.toJson()) as Map<String, dynamic>);

  /// The customer's own orders with their items, newest first (account page).
  Future<List<Order>> myOrders() async => [for (final o in await get('/api/orders/mine') as List) Order.fromJson(o as Map<String, dynamic>)];

  /// The pretend checkout: marks the customer's own order as paid. No card details are sent.
  Future<Order> pay(int orderId) async => Order.fromJson(await post('/api/orders/$orderId/pay') as Map<String, dynamic>);
}
