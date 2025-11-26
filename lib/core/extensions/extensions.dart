import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';


extension Value on num {
  BorderRadiusGeometry get circular => BorderRadius.circular(toDouble());
  int get opacity => (255 * this / 100).toInt();
}

extension IntValue on int {
  BorderRadiusGeometry get circular => BorderRadius.circular(toDouble());
  int get opacity => (255 * this / 100).toInt();
}

extension Asset on String {
  AssetImage get asset => AssetImage(this);
  SvgPicture get svg => SvgPicture.asset(this);
}

extension DateTimeAgoExtension on DateTime {
  String toStringWithFormat({String? format}) {
    format = format ?? 'yyyy-MM-dd HH:mm:ss';
    if (format.contains('yy')) {
      String year = this.year.toString();
      if (format.contains('yyyy')) {
        format = format.replaceAll('yyyy', year);
      } else {
        format = format.replaceAll('yy', year.substring(year.length - 2, year.length));
      }
    }

    format = _comFormat(month, format, 'M', 'MM');
    format = _comFormat(day, format, 'd', 'dd');
    format = _comFormat(hour, format, 'H', 'HH');
    format = _comFormat(minute, format, 'm', 'mm');
    format = _comFormat(second, format, 's', 'ss');
    format = _comFormat(millisecond, format, 'S', 'SSS');

    return format;
  }

  static String _comFormat(int value, String format, String single, String full) {
    if (format.contains(single)) {
      if (format.contains(full)) {
        format = format.replaceAll(full, value < 10 ? '0$value' : value.toString());
      } else {
        format = format.replaceAll(single, value.toString());
      }
    }
    return format;
  }

  String timeAgo({bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(this);

    if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1 week ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }

  String get searchDate {
    return DateFormat("y-MM-dd").format(this);
  }

  String get filterDate {
    return DateFormat("dd/MM/y").format(this);
  }

  String get docDate {
    return DateFormat("y-M-d hh:mm:ss").format(this);
  }

  String get earningDate {
    return '$day${_getOrdinalDay(day)} ${DateFormat("MMM, yyyy - hh:mm a").format(this)}';
  }

  String get registrationDate {
    return '$day${_getOrdinalDay(day)} ${DateFormat("MMMM, yyyy").format(this)}';
  }

  String get earningDayFormat {
    return '$day${_getOrdinalDay(day)} ${DateFormat("MMM, yyyy").format(this)}';
  }

  String get symptomDate {
    return DateFormat('MMMM d, y hh:mm a').format(this);
  }

  String get slashDate {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  String get hourMinuteFormat {
    return DateFormat("hh:mm a").format(this);
  }

  String get monthFormat {
    return DateFormat("MMMM").format(this);
  }

  String get tripDate {
    return '$day${_getOrdinalDay(day)} ${DateFormat("MMM, yyyy").format(this)}';
  }

  String get calendarWeekDay {
    return DateFormat("E").format(this).substring(0, 1);
  }

  String _getOrdinalDay(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

extension DateTimeExtension on num {
  String get timeAway {
    if ((this / (3600 * 24 * 7) / 7).floor() >= 2) {
      return '${(this / (3600 * 24 * 7))} weeks away';
    } else if ((this / (3600 * 24 * 7) / 7).floor() >= 1) {
      return '1 week away';
    } else if (this / (3600 * 24) >= 2) {
      return '${(this / (3600 * 24)).toStringAsFixed(0)} days away';
    } else if (this / (3600 * 24) >= 1) {
      return '1 day away';
    } else if (this / 3600 >= 2) {
      return '${(this / 3600).toStringAsFixed(0)} hours away';
    } else if (this / 3600 >= 1) {
      return '1 hour away';
    } else if (this / 60 >= 2) {
      return '${(this / 60).toStringAsFixed(0)} mins away';
    } else if (this / 60 >= 1) {
      return '1 minute away';
    } else if (this >= 3) {
      return '${(this).toStringAsFixed(0)} seconds away';
    } else {
      return 'Around you';
    }
  }
}

extension PathParameter on String {
  String buildPath(Map<String, dynamic> variables) {
    String item = this;
    for (final key in variables.keys) {
      item = item.replaceAll("{$key}", "${variables[key]}");
    }
    return item;
  }
}

extension AmountFormatter on num {
  String get formatAmount {
    return NumberFormat.currency(name: '').format(this);
  }
}

extension StringFormatting on String {
  String get toTitleCase {
    if (isEmpty) return this;
    final firstChar = substring(0, 1);
    final remainingChars = substring(1);
    return "${firstChar.toUpperCase()}$remainingChars";
  }

  int get toInt {
    if (isEmpty) return 0;
    return int.parse(this);
  }
}

extension CapExtension on String {
  String get inCaps => '${this[0].toUpperCase()}${substring(1)}';
  String get allInCaps => toUpperCase();
  String get capitalize => '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  String get capitalizeFirstOfEach => split(" ").map((str) => str.capitalize).join(" ");
  String get capitalizeWeekdays {
    // Split the string by comma
    List<String> words = split(',');

    // Capitalize first letter of each word and trim whitespace
    List<String> capitalizedWords =
        words.map((word) {
          word = word.trim();
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1, 3).toLowerCase();
        }).toList();

    // Join back with commas
    return capitalizedWords.join(',');
  }
}

extension ParseAmountExtension on String {
  String get parseAmount {
    return replaceAll(',', '').replaceAll('₦', '').replaceAll(' ', '');
  }
}

extension Time on String {
  // TimeOfDay get stringToTimeOfDay {
  //   final format = DateFormat.jm(); //"6:00 AM"
  //   return TimeOfDay.fromDateTime(format.parse(this));
  // }

  DateTime get stringToDateTime {
    final format = DateFormat("h:mm a"); //"6:00 AM"

    return format.parse(this);
  }

  TimeOfDay get stringToTimeOfDay {
    // Remove any whitespace
    final timeString = trim();

    // Extract AM/PM
    String period = timeString.substring(timeString.length - 2).toUpperCase();

    // Remove AM/PM from time
    String time = timeString.substring(0, timeString.length - 2).trim();

    // Split hours and minutes
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    // Convert to 24-hour format if PM
    if (period == 'PM' && hours != 12) {
      hours += 12;
    }
    // Handle special case for 12 AM
    else if (period == 'AM' && hours == 12) {
      hours = 0;
    }

    return TimeOfDay(hour: hours, minute: minutes);
  }
}

enum ConversationStatus { cancelled, completed }

class DateFormatter {
  static String getVerboseDateTimeRepresentation(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final DateTime localDateTime = dateTime.toLocal();
    if (localDateTime.day == now.day && localDateTime.month == now.month && localDateTime.year == now.year) {
      return "Today";
    }
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (localDateTime.day == yesterday.day && localDateTime.month == now.month && localDateTime.year == now.year) {
      return "Yesterday";
    }
    return DateFormat.yMMMd().format(dateTime);
  }

  static String getFormattedDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}

extension StatusType on String? {
  ConversationStatus get type {
    switch (this?.toLowerCase()) {
      case "cancelled":
        return ConversationStatus.cancelled;
      case "completed":
        return ConversationStatus.completed;
      default:
        return ConversationStatus.cancelled;
    }
  }
}
