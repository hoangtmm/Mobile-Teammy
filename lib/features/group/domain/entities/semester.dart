class Semester {
  final String semesterId;
  final String season;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const Semester({
    required this.semesterId,
    required this.season,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });
}
