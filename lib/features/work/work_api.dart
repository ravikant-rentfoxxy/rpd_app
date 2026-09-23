import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

/// The Work screen's own endpoint: the shift, the ladder and the three task
/// lists in one round trip, plus the duty toggle.

/// Today's shift. Everything but [onDuty] is read off work the member has
/// already recorded, so it moves without anyone maintaining it.
class WorkShift {
  const WorkShift({
    this.onDuty = false,
    this.onDutySince,
    this.sector = '',
    this.done = 0,
    this.total = 0,
    this.streakDays = 0,
  });

  final bool onDuty;
  final DateTime? onDutySince;
  final String sector;
  final int done;
  final int total;
  final int streakDays;

  /// How much of today's work is behind them, for the duty dial.
  double get saturation => total == 0 ? 0 : (done / total).clamp(0, 1).toDouble();

  factory WorkShift.fromJson(Object? raw) {
    if (raw is! Map) return const WorkShift();
    final json = Map<String, dynamic>.from(raw);
    return WorkShift(
      onDuty: json['onDuty'] == true,
      onDutySince: DateTime.tryParse('${json['onDutySince'] ?? ''}')?.toLocal(),
      sector: '${json['sector'] ?? ''}'.trim(),
      done: _int(json['done']),
      total: _int(json['total']),
      streakDays: _int(json['streakDays']),
    );
  }
}

/// Where the member stands on the points ladder.
class WorkRank {
  const WorkRank({
    this.rank = 0,
    this.totalMembers = 0,
    this.tier = 1,
    this.level = 1,
    this.levelName = '',
    this.nextLevelName = '',
    this.area = '',
    this.xp = 0,
    this.xpForNext = 0,
    this.xpToday = 0,
  });

  final int rank;
  final int totalMembers;
  final int tier;
  final int level;
  final String levelName;
  final String nextLevelName;
  final String area;
  final int xp;
  final int xpForNext;
  final int xpToday;

  int get xpRemaining => (xpForNext - xp).clamp(0, xpForNext);

  /// Full at the top of the ladder, where there is no next threshold to divide
  /// by — otherwise the meter would read empty for the best member on it.
  double get progress => xpForNext <= 0 ? 1 : (xp / xpForNext).clamp(0, 1).toDouble();

  factory WorkRank.fromJson(Object? raw) {
    if (raw is! Map) return const WorkRank();
    final json = Map<String, dynamic>.from(raw);
    return WorkRank(
      rank: _int(json['rank']),
      totalMembers: _int(json['totalMembers']),
      tier: _int(json['tier'], or: 1),
      level: _int(json['level'], or: 1),
      levelName: '${json['levelName'] ?? ''}',
      nextLevelName: '${json['nextLevelName'] ?? ''}',
      area: '${json['area'] ?? ''}',
      xp: _int(json['xp']),
      xpForNext: _int(json['xpForNext']),
      xpToday: _int(json['xpToday']),
    );
  }
}

/// The whole screen in one shape.
class WorkBoard {
  const WorkBoard({
    this.shift = const WorkShift(),
    this.rank = const WorkRank(),
    this.active = const [],
    this.completed = const [],
    this.drives = const [],
  });

  final WorkShift shift;
  final WorkRank rank;
  final List<Map<String, dynamic>> active;
  final List<Map<String, dynamic>> completed;
  final List<Map<String, dynamic>> drives;

  static List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  factory WorkBoard.fromJson(Map<String, dynamic> json) {
    final tasks = json['tasks'] is Map ? Map<String, dynamic>.from(json['tasks'] as Map) : const {};
    return WorkBoard(
      shift: WorkShift.fromJson(json['shift']),
      rank: WorkRank.fromJson(json['rank']),
      active: _rows(tasks['active']),
      completed: _rows(tasks['completed']),
      drives: _rows(tasks['drives']),
    );
  }
}

int _int(Object? raw, {int or = 0}) {
  if (raw is num) return raw.round();
  return int.tryParse('${raw ?? ''}') ?? or;
}

Future<WorkBoard> fetchWorkBoard() async {
  final res = await Get.find<ApiClient>().get('/work');
  return WorkBoard.fromJson(Map<String, dynamic>.from(res['data'] as Map));
}

/// Send the state wanted, not a toggle, so a double tap cannot leave the phone
/// and the server disagreeing about whether the member is on duty.
Future<WorkShift> setOnDuty(bool onDuty) async {
  final res = await Get.find<ApiClient>().post('/work/duty', data: {'onDuty': onDuty});
  return WorkShift.fromJson(res['data']);
}
