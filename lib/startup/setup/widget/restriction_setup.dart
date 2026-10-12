// lib/startup/setup/widget/restriction_setup.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/pageviewer.dart';

/// Food restrictions — uses shared [PageViewer].
class RestrictionSetup extends StatelessWidget {
  final String currentLang;
  final List<int> selectedRestrictions;
  final ValueChanged<List<int>> onChanged;

  const RestrictionSetup({
    super.key,
    required this.currentLang,
    required this.selectedRestrictions,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> items = [
    // —— شایع‌ترین‌ها (دم‌دست)
    {'id': 1, 'icon': Icons.local_drink_rounded, 'title': 'restrict_dairy'},
    {'id': 18, 'icon': Icons.opacity_rounded, 'title': 'restrict_lactose'},
    {'id': 19, 'icon': Icons.science_outlined, 'title': 'restrict_casein'},
    {'id': 72, 'icon': Icons.egg_outlined, 'title': 'restrict_egg_white'},
    {'id': 73, 'icon': Icons.egg, 'title': 'restrict_egg_yolk'},
    {'id': 4, 'icon': Icons.crisis_alert_rounded, 'title': 'restrict_peanuts'},
    {'id': 3, 'icon': Icons.spa_rounded, 'title': 'restrict_nuts'},
    {'id': 20, 'icon': Icons.park_rounded, 'title': 'restrict_almond'},
    {'id': 21, 'icon': Icons.forest_rounded, 'title': 'restrict_hazelnut'},
    {'id': 22, 'icon': Icons.nature_rounded, 'title': 'restrict_walnut'},
    {'id': 23, 'icon': Icons.spa_outlined, 'title': 'restrict_cashew'},
    {'id': 24, 'icon': Icons.yard_rounded, 'title': 'restrict_pistachio'},
    {'id': 5, 'icon': Icons.bakery_dining_rounded, 'title': 'restrict_gluten'},
    {'id': 6, 'icon': Icons.grain_rounded, 'title': 'restrict_wheat'},
    {'id': 10, 'icon': Icons.grass_rounded, 'title': 'restrict_soy'},
    {'id': 8, 'icon': Icons.phishing_rounded, 'title': 'restrict_fish'},
    {'id': 7, 'icon': Icons.set_meal_rounded, 'title': 'restrict_seafood'},
    {'id': 9, 'icon': Icons.water_rounded, 'title': 'restrict_shellfish'},
    {'id': 29, 'icon': Icons.set_meal_outlined, 'title': 'restrict_shrimp'},
    {'id': 30, 'icon': Icons.cruelty_free_rounded, 'title': 'restrict_crab'},
    {'id': 31, 'icon': Icons.water_drop_rounded, 'title': 'restrict_lobster'},
    {'id': 11, 'icon': Icons.brightness_1_rounded, 'title': 'restrict_sesame'},
    // —— نسبتاً شایع / برچسب‌گذاری رسمی
    {'id': 12, 'icon': Icons.science_rounded, 'title': 'restrict_mustard'},
    {'id': 13, 'icon': Icons.eco_rounded, 'title': 'restrict_celery'},
    {'id': 14, 'icon': Icons.bubble_chart_rounded, 'title': 'restrict_sulfites'},
    {'id': 15, 'icon': Icons.local_florist_rounded, 'title': 'restrict_lupin'},
    {'id': 32, 'icon': Icons.waves_rounded, 'title': 'restrict_oyster'},
    {'id': 33, 'icon': Icons.water_outlined, 'title': 'restrict_clam'},
    {'id': 34, 'icon': Icons.phishing_rounded, 'title': 'restrict_squid'},
    {'id': 25, 'icon': Icons.public_rounded, 'title': 'restrict_brazil_nut'},
    {'id': 26, 'icon': Icons.circle_outlined, 'title': 'restrict_macadamia'},
    {'id': 27, 'icon': Icons.brightness_low_rounded, 'title': 'restrict_pecan'},
    {'id': 28, 'icon': Icons.beach_access_rounded, 'title': 'restrict_coconut'},
    // —— میوه‌ها و گیاهی
    {'id': 35, 'icon': Icons.local_pizza_rounded, 'title': 'restrict_tomato'},
    {'id': 36, 'icon': Icons.favorite_rounded, 'title': 'restrict_strawberry'},
    {'id': 37, 'icon': Icons.brightness_5_rounded, 'title': 'restrict_citrus'},
    {'id': 38, 'icon': Icons.emoji_nature_rounded, 'title': 'restrict_kiwi'},
    {'id': 39, 'icon': Icons.sentiment_satisfied_rounded, 'title': 'restrict_banana'},
    {'id': 40, 'icon': Icons.spa, 'title': 'restrict_avocado'},
    {'id': 41, 'icon': Icons.filter_vintage_rounded, 'title': 'restrict_peach'},
    {'id': 42, 'icon': Icons.apple, 'title': 'restrict_apple'},
    // —— غلات و حبوبات
    {'id': 16, 'icon': Icons.agriculture_rounded, 'title': 'restrict_corn'},
    {'id': 63, 'icon': Icons.grass_outlined, 'title': 'restrict_oat'},
    {'id': 64, 'icon': Icons.horizontal_split_rounded, 'title': 'restrict_barley'},
    {'id': 65, 'icon': Icons.view_week_rounded, 'title': 'restrict_rye'},
    {'id': 66, 'icon': Icons.change_history_rounded, 'title': 'restrict_buckwheat'},
    {'id': 62, 'icon': Icons.ramen_dining_rounded, 'title': 'restrict_rice'},
    {'id': 57, 'icon': Icons.grain_outlined, 'title': 'restrict_legumes'},
    {'id': 58, 'icon': Icons.circle, 'title': 'restrict_chickpea'},
    {'id': 59, 'icon': Icons.blur_on_rounded, 'title': 'restrict_lentil'},
    {'id': 60, 'icon': Icons.crop_rounded, 'title': 'restrict_bean'},
    {'id': 61, 'icon': Icons.eco_outlined, 'title': 'restrict_pea'},
    {'id': 67, 'icon': Icons.square_rounded, 'title': 'restrict_potato'},
    // —— ادویه و حساسیت‌های خاص
    {'id': 52, 'icon': Icons.spa_rounded, 'title': 'restrict_garlic'},
    {'id': 53, 'icon': Icons.radio_button_checked, 'title': 'restrict_onion'},
    {'id': 54, 'icon': Icons.local_fire_department_rounded, 'title': 'restrict_pepper'},
    {'id': 55, 'icon': Icons.whatshot_rounded, 'title': 'restrict_chili'},
    {'id': 56, 'icon': Icons.cloud_rounded, 'title': 'restrict_mushroom'},
    {'id': 49, 'icon': Icons.restaurant_rounded, 'title': 'restrict_fodmap'},
    {'id': 50, 'icon': Icons.water_drop_outlined, 'title': 'restrict_fructose'},
    {'id': 48, 'icon': Icons.bloodtype_rounded, 'title': 'restrict_histamine'},
    {'id': 51, 'icon': Icons.warning_amber_rounded, 'title': 'restrict_histamine_rich'},
    // —— گوشت و پروتئین
    {'id': 68, 'icon': Icons.kebab_dining_rounded, 'title': 'restrict_red_meat'},
    {'id': 69, 'icon': Icons.breakfast_dining_rounded, 'title': 'restrict_pork'},
    {'id': 70, 'icon': Icons.lunch_dining_rounded, 'title': 'restrict_beef'},
    {'id': 71, 'icon': Icons.fastfood_rounded, 'title': 'restrict_chicken'},
    // —— افزودنی‌ها و متفرقه
    {'id': 43, 'icon': Icons.cake_rounded, 'title': 'restrict_chocolate'},
    {'id': 44, 'icon': Icons.coffee_maker_rounded, 'title': 'restrict_cocoa'},
    {'id': 45, 'icon': Icons.coffee_rounded, 'title': 'restrict_coffee'},
    {'id': 46, 'icon': Icons.bolt_rounded, 'title': 'restrict_caffeine'},
    {'id': 47, 'icon': Icons.bubble_chart_outlined, 'title': 'restrict_yeast'},
    {'id': 17, 'icon': Icons.hive_rounded, 'title': 'restrict_honey'},
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

  static List<PageViewerItem> get pageItems =>
      items.map(PageViewerItem.fromMap).toList();

  @override
  Widget build(BuildContext context) {
    return PageViewer(
      currentLang: currentLang,
      items: pageItems,
      selectedIds: selectedRestrictions,
      onChanged: onChanged,
      subtitleKey: 'restriction_subtitle',
      showSearch: true,
    );
  }
}
