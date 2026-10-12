// lib/startup/setup/widget/favorite_food_setup.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/pageviewer.dart';

/// Favorite foods — same [PageViewer] UI as restrictions.
class FavoriteFoodSetup extends StatelessWidget {
  final String currentLang;
  final List<int> selectedFoods;
  final ValueChanged<List<int>> onChanged;

  const FavoriteFoodSetup({
    super.key,
    required this.currentLang,
    required this.selectedFoods,
    required this.onChanged,
  });

  /// Common favorites first (more accessible).
  static const List<Map<String, dynamic>> items = [
    {'id': 1, 'icon': Icons.rice_bowl_rounded, 'title': 'fav_rice'},
    {'id': 2, 'icon': Icons.lunch_dining_rounded, 'title': 'fav_chicken'},
    {'id': 3, 'icon': Icons.set_meal_rounded, 'title': 'fav_fish'},
    {'id': 4, 'icon': Icons.kebab_dining_rounded, 'title': 'fav_kebab'},
    {'id': 5, 'icon': Icons.local_pizza_rounded, 'title': 'fav_pizza'},
    {'id': 6, 'icon': Icons.ramen_dining_rounded, 'title': 'fav_pasta'},
    {'id': 7, 'icon': Icons.soup_kitchen_rounded, 'title': 'fav_soup'},
    {'id': 8, 'icon': Icons.breakfast_dining_rounded, 'title': 'fav_egg_dish'},
    {'id': 9, 'icon': Icons.restaurant_rounded, 'title': 'fav_stew'},
    {'id': 10, 'icon': Icons.dinner_dining_rounded, 'title': 'fav_rice_stew'},
    {'id': 11, 'icon': Icons.grass_rounded, 'title': 'fav_salad'},
    {'id': 12, 'icon': Icons.eco_rounded, 'title': 'fav_vegetables'},
    {'id': 13, 'icon': Icons.apple, 'title': 'fav_fruit'},
    {'id': 14, 'icon': Icons.icecream_rounded, 'title': 'fav_yogurt'},
    {'id': 15, 'icon': Icons.local_drink_rounded, 'title': 'fav_milk'},
    {'id': 16, 'icon': Icons.breakfast_dining_outlined, 'title': 'fav_cheese'},
    {'id': 17, 'icon': Icons.bakery_dining_rounded, 'title': 'fav_bread'},
    {'id': 18, 'icon': Icons.cookie_rounded, 'title': 'fav_pastry'},
    {'id': 19, 'icon': Icons.cake_rounded, 'title': 'fav_dessert'},
    {'id': 20, 'icon': Icons.coffee_rounded, 'title': 'fav_coffee_tea'},
    {'id': 21, 'icon': Icons.fastfood_rounded, 'title': 'fav_sandwich'},
    {'id': 22, 'icon': Icons.tapas_rounded, 'title': 'fav_appetizer'},
    {'id': 23, 'icon': Icons.egg_alt_rounded, 'title': 'fav_omelette'},
    {'id': 24, 'icon': Icons.spa_rounded, 'title': 'fav_nuts_seeds'},
    {'id': 25, 'icon': Icons.water_drop_rounded, 'title': 'fav_smoothie'},
    {'id': 26, 'icon': Icons.brunch_dining_rounded, 'title': 'fav_brunch'},
    {'id': 27, 'icon': Icons.local_cafe_rounded, 'title': 'fav_breakfast'},
    {'id': 28, 'icon': Icons.dinner_dining_outlined, 'title': 'fav_dinner'},
    {'id': 29, 'icon': Icons.lunch_dining_outlined, 'title': 'fav_lunch'},
    {'id': 30, 'icon': Icons.emoji_food_beverage_rounded, 'title': 'fav_herbal_tea'},
  ];

  static List<PageViewerItem> get pageItems =>
      items.map(PageViewerItem.fromMap).toList();

  @override
  Widget build(BuildContext context) {
    return PageViewer(
      currentLang: currentLang,
      items: pageItems,
      selectedIds: selectedFoods,
      onChanged: onChanged,
      subtitleKey: 'favorite_food_subtitle',
      showSearch: true,
    );
  }
}
