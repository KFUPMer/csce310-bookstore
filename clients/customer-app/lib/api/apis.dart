import 'package:bookstore_ui/bookstore_ui.dart';

import '../models/order_draft.dart';

/// order-service, the customer's side: place an order (FR6-FR10).
/// The user and book clients are shared with the management app (bookstore-ui).
class OrderApi extends ApiClient {
  OrderApi(Session session, {String baseUrl = orderServiceUrl}) : super(baseUrl, session, serviceName: 'The order service');

  Future<Order> createOrder(OrderDraft draft) async => Order.fromJson(await post('/api/orders', draft.toJson()) as Map<String, dynamic>);
}
