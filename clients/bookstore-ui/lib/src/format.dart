/// How both apps write money and dates, the same way the HTML bill does.
library;

/// An amount: $1,234.50. Rounded to the cent half up, as order-service rounds a
/// charge, so the apps never show a cent different from the bill.
String money(double amount) {
  final cents = toCents(amount);
  final whole = (cents ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  return '\$$whole.${(cents % 100).toString().padLeft(2, '0')}';
}

/// [amount] in whole cents. Going through the printed form avoids float error:
/// 35.55 is stored as 35.5499999..., which would otherwise round down.
int toCents(double amount) => (double.parse(amount.toStringAsFixed(6)) * 100).round();

const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/// "24 November 2026"
String formatDay(DateTime day) => '${day.day} ${_months[day.month - 1]} ${day.year}';

/// "13 November 2026, 10:05"
String formatMoment(DateTime moment) => '${formatDay(moment)}, ${moment.hour.toString().padLeft(2, '0')}:${moment.minute.toString().padLeft(2, '0')}';
