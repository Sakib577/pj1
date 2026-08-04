import 'package:flutter/material.dart';

import '../utils/date_ranges.dart';

/// A bottom sheet listing the date-range presets. Returns the chosen [DateRange]
/// or null if dismissed.
Future<DateRange?> showStatisticsRangePicker(BuildContext context) async {
  final result = await showModalBottomSheet<DateRange>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics range',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final preset in const [
                      DateRangePreset.today,
                      DateRangePreset.last7,
                      DateRangePreset.last30,
                      DateRangePreset.thisMonth,
                      DateRangePreset.lastMonth,
                      DateRangePreset.thisYear,
                      DateRangePreset.all,
                    ])
                      _PresetTile(
                        preset: preset,
                        onTap: () => Navigator.of(
                          sheetContext,
                        ).pop(DateRange.preset(preset)),
                      ),
                    _CustomRangeTile(
                      onTap: () async {
                        final now = DateTime.now();
                        final navigator = Navigator.of(sheetContext);
                        final picked = await showDateRangePicker(
                          context: sheetContext,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 1),
                          currentDate: now,
                          helpText: 'Select custom range',
                          saveText: 'Apply',
                        );
                        if (picked != null) {
                          navigator.pop(
                            DateRange.custom(
                              start: picked.start,
                              end: picked.end,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result;
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset, required this.onTap});

  final DateRangePreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = DateRange.preset(preset).label;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.date_range_outlined),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _CustomRangeTile extends StatelessWidget {
  const _CustomRangeTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_month_outlined),
      title: const Text('Custom range'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}