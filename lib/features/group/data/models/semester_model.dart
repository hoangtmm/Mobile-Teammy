import '../../domain/entities/semester.dart';

class SemesterModel extends Semester {
  const SemesterModel({
    required super.semesterId,
    required super.season,
    required super.year,
    required super.startDate,
    required super.endDate,
    required super.isActive,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      semesterId: json['semesterId'] as String,
      season: json['season'] as String,
      year: json['year'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semesterId': semesterId,
      'season': season,
      'year': year,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
