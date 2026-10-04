// lib/startup/setup/widget/restriction_setup.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// حساسیت غذایی — فقط یک وجه داخل مربع؛ هیچ چیزی پشتش دیده نمی‌شود
class RestrictionSetup extends StatefulWidget {
  final String currentLang;
  final List<int> selectedRestrictions;
  final ValueChanged<List<int>> onChanged;

  const RestrictionSetup({
    super.key,
    required this.currentLang,
    required this.selectedRestrictions,
    required this.onChanged,
  });

  static const int kNone = 0;

  static const List<Map<String, dynamic>> items = [
    {'id': 0, 'icon': Icons.block_rounded, 'title': 'restrict_none'},
    {'id': 1, 'icon': Icons.local_drink_rounded, 'title': 'restrict_dairy'},
    {'id': 2, 'icon': Icons.egg_outlined, 'title': 'restrict_eggs'},
    {'id': 3, 'icon': Icons.spa_rounded, 'title': 'restrict_nuts'},
    {'id': 4, 'icon': Icons.crisis_alert_rounded, 'title': 'restrict_peanuts'},
    {'id': 5, 'icon': Icons.bakery_dining_rounded, 'title': 'restrict_gluten'},
    {'id': 6, 'icon': Icons.grain_rounded, 'title': 'restrict_wheat'},
    {'id': 7, 'icon': Icons.set_meal_rounded, 'title': 'restrict_seafood'},
    {'id': 8, 'icon': Icons.phishing_rounded, 'title': 'restrict_fish'},
    {'id': 9, 'icon': Icons.water_rounded, 'title': 'restrict_shellfish'},
    {'id': 10, 'icon': Icons.grass_rounded, 'title': 'restrict_soy'},
    {'id': 11, 'icon': Icons.brightness_1_rounded, 'title': 'restrict_sesame'},
    {'id': 12, 'icon': Icons.science_rounded, 'title': 'restrict_mustard'},
    {'id': 13, 'icon': Icons.eco_rounded, 'title': 'restrict_celery'},
    {'id': 14, 'icon': Icons.bubble_chart_rounded, 'title': 'restrict_sulfites'},
    {'id': 15, 'icon': Icons.local_florist_rounded, 'title': 'restrict_lupin'},
    {'id': 16, 'icon': Icons.agriculture_rounded, 'title': 'restrict_corn'},
    {'id': 17, 'icon': Icons.hive_rounded, 'title': 'restrict_honey'},
    {'id': 18, 'icon': Icons.opacity_rounded, 'title': 'restrict_lactose'},
    {'id': 19, 'icon': Icons.science_outlined, 'title': 'restrict_casein'},
    {'id': 20, 'icon': Icons.park_rounded, 'title': 'restrict_almond'},
    {'id': 21, 'icon': Icons.forest_rounded, 'title': 'restrict_hazelnut'},
    {'id': 22, 'icon': Icons.nature_rounded, 'title': 'restrict_walnut'},
    {'id': 23, 'icon': Icons.spa_outlined, 'title': 'restrict_cashew'},
    {'id': 24, 'icon': Icons.yard_rounded, 'title': 'restrict_pistachio'},
    {'id': 25, 'icon': Icons.public_rounded, 'title': 'restrict_brazil_nut'},
    {'id': 26, 'icon': Icons.circle_outlined, 'title': 'restrict_macadamia'},
    {'id': 27, 'icon': Icons.brightness_low_rounded, 'title': 'restrict_pecan'},
    {'id': 28, 'icon': Icons.beach_access_rounded, 'title': 'restrict_coconut'},
    {'id': 29, 'icon': Icons.set_meal_outlined, 'title': 'restrict_shrimp'},
    {'id': 30, 'icon': Icons.cruelty_free_rounded, 'title': 'restrict_crab'},
    {'id': 31, 'icon': Icons.water_drop_rounded, 'title': 'restrict_lobster'},
    {'id': 32, 'icon': Icons.waves_rounded, 'title': 'restrict_oyster'},
    {'id': 33, 'icon': Icons.water_outlined, 'title': 'restrict_clam'},
    {'id': 34, 'icon': Icons.phishing_rounded, 'title': 'restrict_squid'},
    {'id': 35, 'icon': Icons.local_pizza_rounded, 'title': 'restrict_tomato'},
    {'id': 36, 'icon': Icons.favorite_rounded, 'title': 'restrict_strawberry'},
    {'id': 37, 'icon': Icons.brightness_5_rounded, 'title': 'restrict_citrus'},
    {'id': 38, 'icon': Icons.emoji_nature_rounded, 'title': 'restrict_kiwi'},
    {'id': 39, 'icon': Icons.sentiment_satisfied_rounded, 'title': 'restrict_banana'},
    {'id': 40, 'icon': Icons.spa, 'title': 'restrict_avocado'},
    {'id': 41, 'icon': Icons.filter_vintage_rounded, 'title': 'restrict_peach'},
    {'id': 42, 'icon': Icons.apple, 'title': 'restrict_apple'},
    {'id': 43, 'icon': Icons.cake_rounded, 'title': 'restrict_chocolate'},
    {'id': 44, 'icon': Icons.coffee_maker_rounded, 'title': 'restrict_cocoa'},
    {'id': 45, 'icon': Icons.coffee_rounded, 'title': 'restrict_coffee'},
    {'id': 46, 'icon': Icons.bolt_rounded, 'title': 'restrict_caffeine'},
    {'id': 47, 'icon': Icons.bubble_chart_outlined, 'title': 'restrict_yeast'},
    {'id': 48, 'icon': Icons.bloodtype_rounded, 'title': 'restrict_histamine'},
    {'id': 49, 'icon': Icons.restaurant_rounded, 'title': 'restrict_fodmap'},
    {'id': 50, 'icon': Icons.water_drop_outlined, 'title': 'restrict_fructose'},
    {'id': 51, 'icon': Icons.warning_amber_rounded, 'title': 'restrict_histamine_rich'},
    {'id': 52, 'icon': Icons.spa_rounded, 'title': 'restrict_garlic'},
    {'id': 53, 'icon': Icons.radio_button_checked, 'title': 'restrict_onion'},
    {'id': 54, 'icon': Icons.local_fire_department_rounded, 'title': 'restrict_pepper'},
    {'id': 55, 'icon': Icons.whatshot_rounded, 'title': 'restrict_chili'},
    {'id': 56, 'icon': Icons.cloud_rounded, 'title': 'restrict_mushroom'},
    {'id': 57, 'icon': Icons.grain_outlined, 'title': 'restrict_legumes'},
    {'id': 58, 'icon': Icons.circle, 'title': 'restrict_chickpea'},
    {'id': 59, 'icon': Icons.blur_on_rounded, 'title': 'restrict_lentil'},
    {'id': 60, 'icon': Icons.crop_rounded, 'title': 'restrict_bean'},
    {'id': 61, 'icon': Icons.eco_outlined, 'title': 'restrict_pea'},
    {'id': 62, 'icon': Icons.ramen_dining_rounded, 'title': 'restrict_rice'},
    {'id': 63, 'icon': Icons.grass_outlined, 'title': 'restrict_oat'},
    {'id': 64, 'icon': Icons.horizontal_split_rounded, 'title': 'restrict_barley'},
    {'id': 65, 'icon': Icons.view_week_rounded, 'title': 'restrict_rye'},
    {'id': 66, 'icon': Icons.change_history_rounded, 'title': 'restrict_buckwheat'},
    {'id': 67, 'icon': Icons.square_rounded, 'title': 'restrict_potato'},
    {'id': 68, 'icon': Icons.kebab_dining_rounded, 'title': 'restrict_red_meat'},
    {'id': 69, 'icon': Icons.breakfast_dining_rounded, 'title': 'restrict_pork'},
    {'id': 70, 'icon': Icons.lunch_dining_rounded, 'title': 'restrict_beef'},
    {'id': 71, 'icon': Icons.fastfood_rounded, 'title': 'restrict_chicken'},
    {'id': 72, 'icon': Icons.egg_outlined, 'title': 'restrict_egg_white'},
    {'id': 73, 'icon': Icons.egg, 'title': 'restrict_egg_yolk'},
    {'id': 74, 'icon': Icons.cookie_rounded, 'title': 'restrict_gelatin'},
    {'id': 75, 'icon': Icons.science, 'title': 'restrict_msg'},
    {'id': 76, 'icon': Icons.medication_rounded, 'title': 'restrict_aspartame'},
    {'id': 77, 'icon': Icons.inventory_2_rounded, 'title': 'restrict_preservatives'},
    {'id': 78, 'icon': Icons.palette_rounded, 'title': 'restrict_food_coloring'},
    {'id': 79, 'icon': Icons.cloud_queue_rounded, 'title': 'restrict_sulfur'},
    {'id': 80, 'icon': Icons.local_bar_rounded, 'title': 'restrict_alcohol'},
    {'id': 81, 'icon': Icons.opacity, 'title': 'restrict_vinegar'},
    {'id': 82, 'icon': Icons.scatter_plot_rounded, 'title': 'restrict_spice_mix'},
  ];

  @override
  State<RestrictionSetup> createState() => _RestrictionSetupState();
}

class _RestrictionSetupState extends State<RestrictionSetup>
    with SingleTickerProviderStateMixin {
  static const int kNone = RestrictionSetup.kNone;

  late final PageController _pageController;
  late final AnimationController _flipCtrl;
  int _currentPage = 0;
  int _flipDir = 1; // 1 = next, -1 = prev

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // viewportFraction پیش‌فرض ۱ — چیزی از کنار دیده نمی‌شود
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggle(int id) {
    final List<int> next = List<int>.from(widget.selectedRestrictions);
    if (id == kNone) {
      widget.onChanged([kNone]);
      return;
    }
    next.remove(kNone);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onChanged(next);
  }

  List<List<Map<String, dynamic>>> _pages(int perPage) {
    final source = RestrictionSetup.items;
    final out = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < source.length; i += perPage) {
      out.add(source.sublist(i, math.min(i + perPage, source.length)));
    }
    if (out.isEmpty) out.add([]);
    return out;
  }

  void _onPageChanged(int index) {
    setState(() {
      _flipDir = index >= _currentPage ? 1 : -1;
      _currentPage = index;
    });
    _flipCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int perPage = context.shortestSide < 400 ? 9 : 12;
    final pages = _pages(perPage);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Displayer(
          index: 1,
          template: MotionTemplate.bottomSlide,
          child: TextFielder(
            text: SetupText.getString(
              widget.currentLang,
              'restriction_subtitle',
            ),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
              fontSize: context.baseScale * 0.95,
            ),
          ),
        ),
        SizedBox(height: context.vS),
        Displayer(
          index: 2,
          template: MotionTemplate.flipX,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double side = constraints.maxWidth;
              if (constraints.maxHeight.isFinite &&
                  constraints.maxHeight > 0 &&
                  side > constraints.maxHeight) {
                side = constraints.maxHeight;
              }
              final double cap = context.vX5l + context.vX2l;
              if (side > cap) side = cap;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ——— مربع برش‌خورده: هیچ صفحهٔ کناری بیرون/پشت دیده نمی‌شود ———
                  Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(context.m),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: context.baseScale * 0.06,
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: pages.length,
                          onPageChanged: _onPageChanged,
                          // فقط یک صفحه؛ بدون peek صفحهٔ کناری
                          allowImplicitScrolling: false,
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _flipCtrl,
                              builder: (context, child) {
                                // فقط صفحهٔ فعلی انیمیشن چرخش ملایم دارد
                                if (index != _currentPage) {
                                  return child!;
                                }
                                final t = Curves.easeOutCubic
                                    .transform(_flipCtrl.value);
                                // از کمی زاویه به صفر = حس ورق‌خوردن داخل مربع
                                final angle = (1 - t) * _flipDir * 0.35;
                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(angle),
                                  child: child,
                                );
                              },
                              child: _FaceContent(
                                items: pages[index],
                                currentLang: widget.currentLang,
                                selected: widget.selectedRestrictions,
                                onToggle: _toggle,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.vX3s),
                  // نقاط
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final on = i == _currentPage;
                      return Container(
                        width: on ? context.s : context.x2s,
                        height: context.x2s,
                        margin:
                            EdgeInsets.symmetric(horizontal: context.hX4s),
                        decoration: BoxDecoration(
                          color: on
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(context.x2s),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FaceContent extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String currentLang;
  final List<int> selected;
  final ValueChanged<int> onToggle;

  const _FaceContent({
    required this.items,
    required this.currentLang,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // پس‌زمینه پر تا چیزی از «پشت» دیده نشود
      color: Colors.transparent,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(context.s),
        child: Wrap(
          spacing: context.hX3s,
          runSpacing: context.vX3s,
          alignment: WrapAlignment.center,
          children: [
            for (final item in items)
              _TagChip(
                icon: item['icon'] as IconData,
                label: SetupText.getString(
                  currentLang,
                  item['title'] as String,
                ),
                selected: selected.contains(item['id'] as int),
                onTap: () => onToggle(item['id'] as int),
              ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double radius = context.x2s;

    final Color bg = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surface.withValues(alpha: 0.65);
    final Color fg = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final Color borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.25);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: context.hS,
            vertical: context.vX2s,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
              width: context.baseScale * 0.07,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Iconer(
                icon: icon,
                template: IconTemplate.medium,
                customColor: fg,
              ),
              SizedBox(width: context.hX3s),
              TextFielder(
                text: label,
                template: TextTemplate.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                customStyle: TextStyle(
                  fontSize: context.m,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
