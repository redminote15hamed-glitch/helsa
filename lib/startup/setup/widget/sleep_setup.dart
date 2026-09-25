import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/listviewer.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/utils/farsi_digit.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// فقط محتوای استپ خواب — آیکون و عنوان در TitleSetup (step 7)
class SleepWakeSetup extends StatelessWidget {
  final String currentLang;
  final String? selectedSleepTime;
  final String? selectedWakeTime;
  final Function(String?) onSleepTimeSelected;
  final Function(String?) onWakeTimeSelected;

  const SleepWakeSetup({
    super.key,
    required this.currentLang,
    this.selectedSleepTime,
    this.selectedWakeTime,
    required this.onSleepTimeSelected,
    required this.onWakeTimeSelected,
  });

  static const List<String> rawSleepTimes = [
    '----',
    '21:00',
    '21:30',
    '22:00',
    '22:30',
    '23:00',
    '23:30',
    '00:00',
    '00:30',
    '01:00',
    '01:30',
    '02:00',
    '02:30',
    '03:00',
  ];

  static const List<String> rawWakeTimes = [
    '----',
    '05:00',
    '05:30',
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
  ];

  List<String> _localize(BuildContext context, List<String> raw) {
    return raw.map((time) {
      if (time == '----') return time;
      return time.toLocalizedDigits(context, languageCode: currentLang);
    }).toList();
  }

  int _initialIndex(BuildContext context, List<String> raw, String? selected) {
    if (selected == null) return 0;
    final items = _localize(context, raw);
    final localizedSelected = selected.toLocalizedDigits(
      context,
      languageCode: currentLang,
    );
    final index = items.indexOf(localizedSelected);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final sleepItems = _localize(context, rawSleepTimes);
    final wakeItems = _localize(context, rawWakeTimes);

    final sleepIndex = _initialIndex(context, rawSleepTimes, selectedSleepTime);
    final wakeIndex = _initialIndex(context, rawWakeTimes, selectedWakeTime);

    final double labelSize = context.baseScale * 0.95;
    final double listHeight = context.vM;

    return Displayer(
      index: 0,
      template: MotionTemplate.leftSlide,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ساعت خواب + ماه کوچک کنار لیبل
          Displayer(
            index: 1,
            template: MotionTemplate.zoomFade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: context.baseScale * 1.1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: context.hX2s),
                    SetupText(
                      'sleep_time_label',
                      languageCode: currentLang,
                      color: Colors.white70,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w500,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: context.vX3s),
                SizedBox(
                  height: listHeight,
                  child: ListViewer(
                    items: sleepItems,
                    languageCode: currentLang,
                    initialIndex: sleepIndex,
                    isVertical: false,
                    onSelectedItemChanged: (index) {
                      if (index == 0) {
                        onSleepTimeSelected(null);
                      } else {
                        onSleepTimeSelected(rawSleepTimes[index]);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.vM),

          // ساعت بیداری + خورشید کوچک کنار لیبل
          Displayer(
            index: 2,
            template: MotionTemplate.zoomFade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: context.baseScale * 1.1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: context.hX2s),
                    SetupText(
                      'wake_time_label',
                      languageCode: currentLang,
                      color: Colors.white70,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w500,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: context.vX3s),
                SizedBox(
                  height: listHeight,
                  child: ListViewer(
                    items: wakeItems,
                    languageCode: currentLang,
                    initialIndex: wakeIndex,
                    isVertical: false,
                    onSelectedItemChanged: (index) {
                      if (index == 0) {
                        onWakeTimeSelected(null);
                      } else {
                        onWakeTimeSelected(rawWakeTimes[index]);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
