/// Everything the two bookstore desktop apps share.
///
/// The look (colors, type, spacing, motion, and the common widgets) and the
/// way they talk to the services (the client, the session, the book), so the
/// customer app and the management app cannot drift apart.
library;

export 'src/api/api_client.dart';
export 'src/api/session.dart';
export 'src/models/book.dart';
export 'src/models/order.dart';
export 'src/api/apis.dart';

export 'src/tokens.dart';
export 'src/theme.dart';
export 'src/glass.dart';
export 'src/book_cover.dart';
export 'src/app_button.dart';
export 'src/smooth_scroll.dart';
export 'src/status_chip.dart';
export 'src/format.dart';
export 'src/app_text_field.dart';
export 'src/toast.dart';
export 'src/bill_view.dart';
export 'src/auth_layout.dart';
export 'src/login_form.dart';
export 'src/search_field.dart';
export 'src/mooneys_sign.dart';
