import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../join/join_chrome.dart';

const _sheet = Color(0xFFFFFBF7);
const _navy = Color(0xFF1B1340);
const _muted = Color(0xFFB4AFA6);
const _pill = Color(0xFFF7F3EE);
const _orange = Color(0xFFF5821F);
const _weekday = Color(0xFFB8B2A8);

Future<DateTime?> showEventDateTimeSheet({required DateTime initial}) {
  return Get.bottomSheet<DateTime>(
    EventDateTimeSheet(initial: initial),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class EventDateTimeSheet extends StatefulWidget {
  const EventDateTimeSheet({super.key, required this.initial});
  final DateTime initial;

  @override
  State<EventDateTimeSheet> createState() => _EventDateTimeSheetState();
}

class _EventDateTimeSheetState extends State<EventDateTimeSheet> {
  late DateTime month;
  late DateTime selected;
  late int hour12;
  late int minute;
  late bool pm;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selected = widget.initial.isBefore(now) ? now.add(const Duration(hours: 1)) : widget.initial;
    month = DateTime(selected.year, selected.month);
    final hour = selected.hour;
    pm = hour >= 12;
    hour12 = hour % 12 == 0 ? 12 : hour % 12;
    minute = selected.minute;
  }

  DateTime get _firstAllowed {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _lastAllowed => _firstAllowed.add(const Duration(days: 365));

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _canSelect(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return !date.isBefore(_firstAllowed) && !date.isAfter(_lastAllowed);
  }

  void _shiftMonth(int by) {
    final next = DateTime(month.year, month.month + by);
    final first = DateTime(_firstAllowed.year, _firstAllowed.month);
    final last = DateTime(_lastAllowed.year, _lastAllowed.month);
    if (next.isBefore(first) || next.isAfter(last)) return;
    setState(() => month = next);
  }

  void _confirm() {
    var hour = hour12 % 12;
    if (pm) hour += 12;
    final value = DateTime(selected.year, selected.month, selected.day, hour, minute);
    if (value.isBefore(DateTime.now())) {
      Get.snackbar('Error', 'event_future_required'.trFallback('Pick a future date and time'));
      return;
    }
    Get.back(result: value);
  }

  List<DateTime?> _days() {
    final first = DateTime(month.year, month.month, 1);
    final count = DateTime(month.year, month.month + 1, 0).day;
    return [
      for (var i = 0; i < first.weekday % 7; i++) null,
      for (var d = 1; d <= count; d++) DateTime(month.year, month.month, d),
    ];
  }

  Future<void> _editNumber({required int value, required int min, required int max, required ValueChanged<int> onPick}) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SizedBox(
          height: 220,
          child: ListView.builder(
            itemCount: max - min + 1,
            itemBuilder: (context, index) {
              final n = min + index;
              final label = n.toString().padLeft(2, '0');
              return ListTile(
                title: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _navy)),
                selected: n == value,
                onTap: () => Navigator.pop(context, n),
              );
            },
          ),
        );
      },
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final days = _days();
    return Material(
      color: _sheet,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE8E2D8), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'event_when'.trFallback('Date and time'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _navy),
                    ),
                  ),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded, color: _navy)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded, color: _navy)),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM().format(month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _navy),
                    ),
                  ),
                  IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded, color: _navy)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final day in _weekdays)
                    Expanded(
                      child: Text(day, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _weekday, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 40),
                itemBuilder: (context, index) {
                  final day = days[index];
                  if (day == null) return const SizedBox.shrink();
                  final selectedDay = _sameDay(day, selected);
                  final enabled = _canSelect(day);
                  return Center(
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: enabled ? () => setState(() => selected = day) : null,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedDay ? _orange : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selectedDay ? FontWeight.w600 : FontWeight.w400,
                            color: selectedDay ? Colors.white : (enabled ? _navy : _muted),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'time_section'.trFallback('TIME'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: _muted),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TimePill(
                      value: hour12.toString().padLeft(2, '0'),
                      onTap: () => _editNumber(
                        value: hour12,
                        min: 1,
                        max: 12,
                        onPick: (n) => setState(() => hour12 = n),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: _navy)),
                  ),
                  Expanded(
                    child: _TimePill(
                      value: minute.toString().padLeft(2, '0'),
                      onTap: () => _editNumber(
                        value: minute,
                        min: 0,
                        max: 59,
                        onPick: (n) => setState(() => minute = n),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(color: _pill, borderRadius: BorderRadius.circular(22)),
                    child: Row(
                      children: [
                        _Meridiem(label: 'PM', selected: pm, onTap: () => setState(() => pm = true)),
                        _Meridiem(label: 'AM', selected: !pm, onTap: () => setState(() => pm = false)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: Text('set_date_time'.trFallback('Set date and time'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x0F1B1340), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: _navy)),
        ),
      ),
    );
  }
}

class _Meridiem extends StatelessWidget {
  const _Meridiem({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 52,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? _navy : const Color(0xFF9A948C)),
        ),
      ),
    );
  }
}
