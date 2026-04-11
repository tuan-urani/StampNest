import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_empty_tab.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CalendarTabContent extends StatelessWidget {
  const CalendarTabContent({
    super.key,
    required this.stamps,
    required this.onSelectStamp,
  });

  final List<StampDataModel> stamps;
  final ValueChanged<String> onSelectStamp;

  @override
  Widget build(BuildContext context) {
    if (stamps.isEmpty) {
      return StampverseEmptyTab(
        icon: Icons.schedule_outlined,
        title: LocaleKey.stampverseHomeMemoryEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeMemoryEmptySubtitle.tr,
      );
    }
    final Map<DateTime, List<StampDataModel>> groupedByDay = _groupByDay(
      stamps,
    );
    final DateTime today = _normalizeDay(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        0,
        24,
        StampverseLayout.contentBottomPadding,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stampverseBorderSoft),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.stampverseShadowCard,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SfCalendar(
            view: CalendarView.month,
            firstDayOfWeek: DateTime.monday,
            showDatePickerButton: true,
            headerHeight: 46,
            viewHeaderHeight: 28,
            cellBorderColor: AppColors.transparent,
            backgroundColor: AppColors.transparent,
            todayHighlightColor: AppColors.colorEF4056,
            headerStyle: CalendarHeaderStyle(
              textAlign: TextAlign.center,
              textStyle: StampverseTextStyles.body(
                color: AppColors.stampverseHeadingText,
                fontWeight: FontWeight.w700,
              ),
            ),
            viewHeaderStyle: ViewHeaderStyle(
              dayTextStyle: StampverseTextStyles.caption(
                color: AppColors.stampversePrimaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.none,
              showTrailingAndLeadingDates: false,
            ),
            monthCellBuilder: (_, MonthCellDetails details) {
              final DateTime day = _normalizeDay(details.date);
              final List<StampDataModel> dayStamps =
                  groupedByDay[day] ?? const <StampDataModel>[];
              final StampDataModel? firstStamp = dayStamps.isEmpty
                  ? null
                  : dayStamps.first;

              return _MemoryCalendarCell(
                day: day,
                firstStamp: firstStamp,
                isToday: day == today,
                isSunday: day.weekday == DateTime.sunday,
              );
            },
            onTap: (CalendarTapDetails details) {
              final DateTime? tappedDate = details.date;
              if (tappedDate == null) return;

              final DateTime day = _normalizeDay(tappedDate);
              final List<StampDataModel> dayStamps =
                  groupedByDay[day] ?? const <StampDataModel>[];
              if (dayStamps.isEmpty) return;

              _showDayStampsSheet(
                context: context,
                day: day,
                dayStamps: dayStamps,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDayStampsSheet({
    required BuildContext context,
    required DateTime day,
    required List<StampDataModel> dayStamps,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return _MemoryDayStampsSheet(
          day: day,
          dayStamps: dayStamps,
          onSelectStamp: onSelectStamp,
        );
      },
    );
  }

  Map<DateTime, List<StampDataModel>> _groupByDay(List<StampDataModel> source) {
    final Map<DateTime, List<StampDataModel>> grouped =
        <DateTime, List<StampDataModel>>{};

    for (final StampDataModel stamp in source) {
      final DateTime date =
          stamp.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime day = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(day, () => <StampDataModel>[]).add(stamp);
    }

    for (final List<StampDataModel> dayStamps in grouped.values) {
      dayStamps.sort((StampDataModel a, StampDataModel b) {
        final DateTime dateA =
            a.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB =
            b.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });
    }

    return grouped;
  }

  DateTime _normalizeDay(DateTime date) {
    final DateTime local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

class _MemoryCalendarCell extends StatelessWidget {
  const _MemoryCalendarCell({
    required this.day,
    required this.firstStamp,
    required this.isToday,
    required this.isSunday,
  });

  final DateTime day;
  final StampDataModel? firstStamp;
  final bool isToday;
  final bool isSunday;

  @override
  Widget build(BuildContext context) {
    final bool hasStamp = firstStamp != null;
    final Color dayColor = isToday
        ? AppColors.stampverseDanger
        : (isSunday
              ? AppColors.stampverseDanger.withValues(alpha: 0.78)
              : AppColors.stampversePrimaryText);

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stampverseSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday
                ? AppColors.stampverseDanger.withValues(alpha: 0.36)
                : AppColors.stampverseBorderSoft,
          ),
        ),
        child: Stack(
          children: <Widget>[
            if (hasStamp)
              Positioned.fill(
                top: 0,
                left: 4,
                right: 4,
                bottom: 4,
                child: LayoutBuilder(
                  builder: (_, BoxConstraints constraints) {
                    final double maxWidth = constraints.maxWidth;
                    final double maxHeight = constraints.maxHeight;
                    final StampShapeType shapeType = firstStamp!.shapeType;
                    final double widthByHeight =
                        maxHeight * shapeType.aspectRatio;
                    final double stampWidth = widthByHeight < maxWidth
                        ? widthByHeight
                        : maxWidth;

                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: StampverseStamp(
                        imageUrl: firstStamp!.imageUrl,
                        shapeType: shapeType,
                        applyShapeClip: false,
                        width: stampWidth,
                        showShadow: false,
                      ),
                    );
                  },
                ),
              ),
            Positioned(
              top: 5,
              left: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hasStamp
                      ? AppColors.white.withValues(alpha: 0.92)
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    '${day.day}',
                    style: StampverseTextStyles.caption(
                      color: dayColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDayStampsSheet extends StatelessWidget {
  const _MemoryDayStampsSheet({
    required this.day,
    required this.dayStamps,
    required this.onSelectStamp,
  });

  final DateTime day;
  final List<StampDataModel> dayStamps;
  final ValueChanged<String> onSelectStamp;

  @override
  Widget build(BuildContext context) {
    final List<StampDataModel> sorted = List<StampDataModel>.from(dayStamps)
      ..sort((StampDataModel a, StampDataModel b) {
        final DateTime dateA =
            a.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB =
            b.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    final double listBottomPadding =
        StampverseLayout.bottomBarReservedSpace +
        MediaQuery.paddingOf(context).bottom +
        16;

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stampverseBorderSoft,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMMM y').format(day),
                      style: StampverseTextStyles.body(
                        color: AppColors.stampverseHeadingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.stampversePrimaryText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20, 0, 20, listBottomPadding),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, int index) {
                  final StampDataModel stamp = sorted[index];
                  final DateTime time =
                      stamp.parsedDate?.toLocal() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final String collectionName = _resolveCollectionName(stamp);

                  return Material(
                    color: AppColors.stampverseBackground,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectStamp(stamp.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: <Widget>[
                            StampverseStamp(
                              imageUrl: stamp.imageUrl,
                              shapeType: stamp.shapeType,
                              applyShapeClip: false,
                              width: 70,
                              showShadow: false,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    stamp.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: StampverseTextStyles.body(
                                      color: AppColors.stampverseHeadingText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm').format(time),
                                    style: StampverseTextStyles.caption(
                                      color: AppColors.stampverseMutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    collectionName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: StampverseTextStyles.caption(
                                      color: AppColors.stampversePrimaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveCollectionName(StampDataModel stamp) {
    final String album = stamp.album?.trim() ?? '';
    if (album.isNotEmpty) {
      return album;
    }
    return LocaleKey.stampverseHomeMemoryNoCollection.tr;
  }
}
