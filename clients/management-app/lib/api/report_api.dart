import 'package:bookstore_ui/bookstore_ui.dart';

import '../models/sales_report.dart';

/// order-service, the sales report: the orders of a period, its totals, and its
/// best sellers (extra credit). Needs a manager's session (N5).
class ReportApi extends ApiClient {
  ReportApi(Session session, {String baseUrl = orderServiceUrl}) : super(baseUrl, session, serviceName: 'The order service');

  /// The report of the days [from] to [to], both included. A null date leaves that side of the period open.
  /// [top] is how many best sellers to list, 1 to 50.
  Future<SalesReport> salesReport({DateTime? from, DateTime? to, int top = 10}) async {
    final query = Uri(queryParameters: {if (from != null) 'from': _day(from), if (to != null) 'to': _day(to), 'top': '$top'}).query;
    return SalesReport.fromJson(await get('/api/reports/sales?$query') as Map<String, dynamic>);
  }

  /// YYYY-MM-DD; the time of day is ignored.
  static String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
