import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/event/widgets/event_radial_datetime_picker.widget.dart';
import 'package:billetterie/src/features/event/widgets/event_ui_chrome.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

enum EventDateTimeRangeField { start, end }

class EventDateTimeRangeResult {
  const EventDateTimeRangeResult({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

String formatEventDateTime(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm · $hh:$min';
}

/// Modal bottom sheet with the module radial date/time wheel (début + fin).
Future<EventDateTimeRangeResult?> showEventDateTimeRangeSheet({
  required BuildContext context,
  required DateTime initialStart,
  required DateTime initialEnd,
  EventDateTimeRangeField initialField = EventDateTimeRangeField.start,
  String title = 'Dates',
  String confirmLabel = 'Confirmer',
  int dayCount = 75,
  int timeStepMinutes = 60,
}) {
  final brand = BilletterieBrand.eventOf(context);
  final chrome = EventUiChrome.of(context);

  return showModalBottomSheet<EventDateTimeRangeResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: chrome.scaffold,
    barrierColor: Colors.black.withValues(alpha: chrome.isLight ? 0.35 : 0.55),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => EventDateTimeRangeSheet(
      brand: brand,
      initialStart: initialStart,
      initialEnd: initialEnd,
      initialField: initialField,
      title: title,
      confirmLabel: confirmLabel,
      dayCount: dayCount,
      timeStepMinutes: timeStepMinutes,
    ),
  );
}

class EventDateTimeRangeSheet extends StatefulWidget {
  const EventDateTimeRangeSheet({
    super.key,
    required this.brand,
    required this.initialStart,
    required this.initialEnd,
    this.initialField = EventDateTimeRangeField.start,
    this.title = 'Dates',
    this.confirmLabel = 'Confirmer',
    this.dayCount = 75,
    this.timeStepMinutes = 60,
  });

  final BilletterieBrand brand;
  final DateTime initialStart;
  final DateTime initialEnd;
  final EventDateTimeRangeField initialField;
  final String title;
  final String confirmLabel;
  final int dayCount;
  final int timeStepMinutes;

  @override
  State<EventDateTimeRangeSheet> createState() =>
      _EventDateTimeRangeSheetState();
}

class _EventDateTimeRangeSheetState extends State<EventDateTimeRangeSheet> {
  late DateTime _draftStart;
  late DateTime _draftEnd;
  late EventDateTimeRangeField _field;

  @override
  void initState() {
    super.initState();
    _draftStart = widget.initialStart;
    _draftEnd = widget.initialEnd;
    _field = widget.initialField;
  }

  DateTime get _activeDraft =>
      _field == EventDateTimeRangeField.start ? _draftStart : _draftEnd;

  void _setDraft(DateTime dt) {
    setState(() {
      if (_field == EventDateTimeRangeField.start) {
        _draftStart = dt;
        if (!_draftEnd.isAfter(_draftStart)) {
          _draftEnd = _draftStart.add(const Duration(hours: 1));
        }
      } else {
        _draftEnd = dt;
      }
    });
  }

  void _selectField(EventDateTimeRangeField field) {
    if (_field == field) return;
    setState(() => _field = field);
  }

  void _apply() {
    if (!_draftEnd.isAfter(_draftStart)) {
      showBilletterieResultDialog(
        context,
        title: 'Plage invalide',
        message: 'La date de fin doit être après la date de début.',
        kind: BilletterieResultKind.error,
        brand: widget.brand,
      );
      return;
    }
    Navigator.of(context).pop(
      EventDateTimeRangeResult(start: _draftStart, end: _draftEnd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    final chrome = EventUiChrome.of(context);
    final editingStart = _field == EventDateTimeRangeField.start;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: chrome.handle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: chrome.text,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          editingStart
                              ? 'Choisissez le début'
                              : 'Choisissez la fin',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: chrome.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: chrome.iconOnSurface),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _RangeChip(
                      brand: brand,
                      label: 'Début',
                      value: formatEventDateTime(_draftStart),
                      selected: editingStart,
                      onTap: () =>
                          _selectField(EventDateTimeRangeField.start),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RangeChip(
                      brand: brand,
                      label: 'Fin',
                      value: formatEventDateTime(_draftEnd),
                      selected: !editingStart,
                      onTap: () => _selectField(EventDateTimeRangeField.end),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).width * 0.92,
                      child: ClipRect(
                        child: OverflowBox(
                          maxHeight: MediaQuery.sizeOf(context).width * 1.35,
                          alignment: Alignment.topCenter,
                          child: Transform.translate(
                            offset: const Offset(0, 56),
                            child: Transform.scale(
                              scale: 1.14,
                              alignment: Alignment.topCenter,
                              child: EventRadialDateTimePicker(
                                key: ValueKey(_field),
                                initialDateTime: _activeDraft,
                                dayCount: widget.dayCount,
                                timeStepMinutes: widget.timeStepMinutes,
                                onChanged: _setDraft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: FilledButton(
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: brand.primaryDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          widget.confirmLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.brand,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final BilletterieBrand brand;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? brand.primaryDark.withValues(alpha: 0.12)
          : brand.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? brand.primaryDark : brand.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? brand.primaryDark : brand.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: brand.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
