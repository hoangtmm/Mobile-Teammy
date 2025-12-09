import '../../domain/entities/major.dart';

class MajorModel extends Major {
  const MajorModel({
    required super.majorId,
    required super.majorName,
  });

  factory MajorModel.fromJson(Map<String, dynamic> json) {
    return MajorModel(
      majorId: json['majorId'] as String,
      majorName: json['majorName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'majorId': majorId,
      'majorName': majorName,
    };
  }
}
