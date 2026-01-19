import '../../domain/entities/tracking_scores.dart';

class TrackingScoresModel {
  final ScoreRangeModel range;
  final ScoreWeightsModel weights;
  final List<MemberScoreModel> members;

  const TrackingScoresModel({
    required this.range,
    required this.weights,
    required this.members,
  });

  factory TrackingScoresModel.fromJson(Map<String, dynamic> json) {
    return TrackingScoresModel(
      range: ScoreRangeModel.fromJson(json['range'] as Map<String, dynamic>),
      weights: ScoreWeightsModel.fromJson(json['weights'] as Map<String, dynamic>),
      members: (json['members'] as List<dynamic>)
          .map((e) => MemberScoreModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  TrackingScores toEntity() {
    return TrackingScores(
      range: range.toEntity(),
      weights: weights.toEntity(),
      members: members.map((m) => m.toEntity()).toList(),
    );
  }
}

class ScoreRangeModel {
  final String from;
  final String to;

  const ScoreRangeModel({
    required this.from,
    required this.to,
  });

  factory ScoreRangeModel.fromJson(Map<String, dynamic> json) {
    return ScoreRangeModel(
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }

  ScoreRange toEntity() {
    return ScoreRange(from: from, to: to);
  }
}

class ScoreWeightsModel {
  final int high;
  final int medium;
  final int low;

  const ScoreWeightsModel({
    required this.high,
    required this.medium,
    required this.low,
  });

  factory ScoreWeightsModel.fromJson(Map<String, dynamic> json) {
    return ScoreWeightsModel(
      high: json['high'] as int,
      medium: json['medium'] as int,
      low: json['low'] as int,
    );
  }

  ScoreWeights toEntity() {
    return ScoreWeights(high: high, medium: medium, low: low);
  }
}

class MemberScoreModel {
  final String memberId;
  final String memberName;
  final int scoreTotal;
  final int deliveryScore;
  final int qualityScore;
  final int collabScore;
  final TaskStatsModel tasks;
  final PriorityStatsModel byPriority;
  final List<TaskDetailModel> taskDetails;

  const MemberScoreModel({
    required this.memberId,
    required this.memberName,
    required this.scoreTotal,
    required this.deliveryScore,
    required this.qualityScore,
    required this.collabScore,
    required this.tasks,
    required this.byPriority,
    required this.taskDetails,
  });

  factory MemberScoreModel.fromJson(Map<String, dynamic> json) {
    return MemberScoreModel(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      scoreTotal: json['scoreTotal'] as int,
      deliveryScore: json['deliveryScore'] as int,
      qualityScore: json['qualityScore'] as int,
      collabScore: json['collabScore'] as int,
      tasks: TaskStatsModel.fromJson(json['tasks'] as Map<String, dynamic>),
      byPriority: PriorityStatsModel.fromJson(json['byPriority'] as Map<String, dynamic>),
      taskDetails: (json['taskDetails'] as List<dynamic>)
          .map((e) => TaskDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  MemberScore toEntity() {
    return MemberScore(
      memberId: memberId,
      memberName: memberName,
      scoreTotal: scoreTotal,
      deliveryScore: deliveryScore,
      qualityScore: qualityScore,
      collabScore: collabScore,
      tasks: tasks.toEntity(),
      byPriority: byPriority.toEntity(),
      taskDetails: taskDetails.map((t) => t.toEntity()).toList(),
    );
  }
}

class TaskStatsModel {
  final int assigned;
  final int done;

  const TaskStatsModel({
    required this.assigned,
    required this.done,
  });

  factory TaskStatsModel.fromJson(Map<String, dynamic> json) {
    return TaskStatsModel(
      assigned: json['assigned'] as int,
      done: json['done'] as int,
    );
  }

  TaskStats toEntity() {
    return TaskStats(assigned: assigned, done: done);
  }
}

class PriorityStatsModel {
  final PriorityStatModel high;
  final PriorityStatModel medium;
  final PriorityStatModel low;

  const PriorityStatsModel({
    required this.high,
    required this.medium,
    required this.low,
  });

  factory PriorityStatsModel.fromJson(Map<String, dynamic> json) {
    return PriorityStatsModel(
      high: PriorityStatModel.fromJson(json['high'] as Map<String, dynamic>),
      medium: PriorityStatModel.fromJson(json['medium'] as Map<String, dynamic>),
      low: PriorityStatModel.fromJson(json['low'] as Map<String, dynamic>),
    );
  }

  PriorityStats toEntity() {
    return PriorityStats(
      high: high.toEntity(),
      medium: medium.toEntity(),
      low: low.toEntity(),
    );
  }
}

class PriorityStatModel {
  final int done;
  final int score;

  const PriorityStatModel({
    required this.done,
    required this.score,
  });

  factory PriorityStatModel.fromJson(Map<String, dynamic> json) {
    return PriorityStatModel(
      done: json['done'] as int,
      score: json['score'] as int,
    );
  }

  PriorityStat toEntity() {
    return PriorityStat(done: done, score: score);
  }
}

class TaskDetailModel {
  final String taskId;
  final String title;
  final String priority;
  final int weight;
  final String status;
  final DateTime? completedAt;
  final int scoreContributed;

  const TaskDetailModel({
    required this.taskId,
    required this.title,
    required this.priority,
    required this.weight,
    required this.status,
    this.completedAt,
    required this.scoreContributed,
  });

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    return TaskDetailModel(
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      priority: json['priority'] as String,
      weight: json['weight'] as int,
      status: json['status'] as String,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      scoreContributed: json['scoreContributed'] as int,
    );
  }

  TaskDetail toEntity() {
    return TaskDetail(
      taskId: taskId,
      title: title,
      priority: priority,
      weight: weight,
      status: status,
      completedAt: completedAt,
      scoreContributed: scoreContributed,
    );
  }
}

