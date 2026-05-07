enum DateFilterType { daily, monthly, allTime }

class DateFilter {
  final DateFilterType type;
  final DateTime date;

  DateFilter({required this.type, required this.date});
}
