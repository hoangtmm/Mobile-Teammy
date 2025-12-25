class TrackingScores {
  final ScoreRange range;
  final ScoreWeights weights;
  final List<MemberScore> members;

  const TrackingScores({
    required this.range,
    required this.weights,
    required this.members,
  });
}

class ScoreRange {
  final String from;
  final String to;

  const ScoreRange({
    required this.from,
    required this.to,
  });
}

class ScoreWeights {
  final int high;
  final int medium;
  final int low;

  const ScoreWeights({
    required this.high,
    required this.medium,
    required this.low,
  });
}

class MemberScore {
  final String memberId;
  final String memberName;
  final int scoreTotal;
  final int deliveryScore;
  final int qualityScore;
  final int collabScore;
  final TaskStats tasks;
  final PriorityStats byPriority;
  final List<TaskDetail> taskDetails;

  const MemberScore({
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
}

class TaskStats {
  final int assigned;
  final int done;

  const TaskStats({
    required this.assigned,
    required this.done,
  });
}

class PriorityStats {
  final PriorityStat high;
  final PriorityStat medium;
  final PriorityStat low;

  const PriorityStats({
    required this.high,
    required this.medium,
    required this.low,
  });
}

class PriorityStat {
  final int done;
  final int score;

  const PriorityStat({
    required this.done,
    required this.score,
  });
}

class TaskDetail {
  final String taskId;
  final String title;
  final String priority;
  final int weight;
  final String status;
  final DateTime? completedAt;
  final int scoreContributed;

  const TaskDetail({
    required this.taskId,
    required this.title,
    required this.priority,
    required this.weight,
    required this.status,
    this.completedAt,
    required this.scoreContributed,
  });
}

