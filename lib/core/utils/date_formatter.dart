import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  // Formats
  static const String formatDate = 'dd MMM yyyy';
  static const String formatDateTime = 'dd MMM yyyy, hh:mm a';
  static const String formatTime = 'hh:mm a';
  static const String formatDateFull = 'EEEE, dd MMMM yyyy';
  static const String formatDateShort = 'dd/MM/yyyy';
  static const String formatMonthYear = 'MMMM yyyy';

  // Format DateTime to String
  static String format(DateTime? dateTime, {String format = formatDate}) {
    if (dateTime == null) return '';
    return DateFormat(format).format(dateTime);
  }

  // Format to Date
  static String toDate(DateTime? dateTime) {
    return format(dateTime, format: formatDate);
  }

  // Format to DateTime
  static String toDateTime(DateTime? dateTime) {
    return format(dateTime, format: formatDateTime);
  }

  // Format to Time
  static String toTime(DateTime? dateTime) {
    return format(dateTime, format: formatTime);
  }

  // Format to Full Date
  static String toFullDate(DateTime? dateTime) {
    return format(dateTime, format: formatDateFull);
  }

  // Get Relative Time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  // Check if Same Day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Check if Today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // Check if Yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  // Get Greeting based on Time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
