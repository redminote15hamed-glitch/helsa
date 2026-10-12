// lib/startup/setup/widget/favorite_food_setup.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/pageviewer.dart';

/// Favorite foods — hides items linked to selected restrictions.
class FavoriteFoodSetup extends StatelessWidget {
  final String currentLang;
  final List<int> selectedFoods;
  final List<int> selectedRestrictions;
  final ValueChanged<List<int>> onChanged;

  const FavoriteFoodSetup({
    super.key,
    required this.currentLang,
    required this.selectedFoods,
    required this.selectedRestrictions,
    required this.onChanged,
  });

  /// Real foods only. Common favorites first.
  static const List<Map<String, dynamic>> items = [
    {'id': 1, 'icon': Icons.rice_bowl_rounded, 'title': 'fav_rice'},
    {'id': 2, 'icon': Icons.lunch_dining_rounded, 'title': 'fav_chicken'},
    {'id': 3, 'icon': Icons.set_meal_rounded, 'title': 'fav_fish'},
    {'id': 4, 'icon': Icons.kebab_dining_rounded, 'title': 'fav_kebab'},
    {'id': 5, 'icon': Icons.local_pizza_rounded, 'title': 'fav_pizza'},
    {'id': 6, 'icon': Icons.ramen_dining_rounded, 'title': 'fav_pasta'},
    {'id': 7, 'icon': Icons.soup_kitchen_rounded, 'title': 'fav_soup'},
    {'id': 8, 'icon': Icons.restaurant_rounded, 'title': 'fav_stew'},
    {'id': 9, 'icon': Icons.dinner_dining_rounded, 'title': 'fav_rice_stew'},
    {'id': 10, 'icon': Icons.egg_outlined, 'title': 'fav_egg_dish'},
    {'id': 11, 'icon': Icons.egg, 'title': 'fav_omelette'},
    {'id': 12, 'icon': Icons.grass_rounded, 'title': 'fav_salad'},
    {'id': 13, 'icon': Icons.eco_rounded, 'title': 'fav_vegetables'},
    {'id': 14, 'icon': Icons.apple, 'title': 'fav_fruit'},
    {'id': 15, 'icon': Icons.icecream_rounded, 'title': 'fav_yogurt'},
    {'id': 16, 'icon': Icons.local_drink_rounded, 'title': 'fav_milk'},
    {'id': 17, 'icon': Icons.breakfast_dining_outlined, 'title': 'fav_cheese'},
    {'id': 18, 'icon': Icons.bakery_dining_rounded, 'title': 'fav_bread'},
    {'id': 19, 'icon': Icons.cookie_rounded, 'title': 'fav_pastry'},
    {'id': 20, 'icon': Icons.cake_rounded, 'title': 'fav_dessert'},
    {'id': 21, 'icon': Icons.coffee_rounded, 'title': 'fav_coffee_tea'},
    {'id': 22, 'icon': Icons.emoji_food_beverage_rounded, 'title': 'fav_herbal_tea'},
    {'id': 23, 'icon': Icons.water_drop_rounded, 'title': 'fav_smoothie'},
    {'id': 24, 'icon': Icons.fastfood_rounded, 'title': 'fav_sandwich'},
    {'id': 25, 'icon': Icons.tapas_rounded, 'title': 'fav_appetizer'},
    {'id': 26, 'icon': Icons.spa_rounded, 'title': 'fav_nuts_seeds'},
    {'id': 27, 'icon': Icons.grain_outlined, 'title': 'fav_legumes'},
    {'id': 28, 'icon': Icons.circle, 'title': 'fav_chickpea'},
    {'id': 29, 'icon': Icons.blur_on_rounded, 'title': 'fav_lentil'},
    {'id': 30, 'icon': Icons.crop_rounded, 'title': 'fav_bean'},
    {'id': 31, 'icon': Icons.square_rounded, 'title': 'fav_potato'},
    {'id': 32, 'icon': Icons.kebab_dining_outlined, 'title': 'fav_beef'},
    {'id': 33, 'icon': Icons.breakfast_dining_rounded, 'title': 'fav_lamb'},
    {'id': 34, 'icon': Icons.set_meal_outlined, 'title': 'fav_shrimp'},
    {'id': 35, 'icon': Icons.phishing_rounded, 'title': 'fav_tuna'},
    {'id': 36, 'icon': Icons.local_pizza_outlined, 'title': 'fav_burger'},
    {'id': 37, 'icon': Icons.ramen_dining_outlined, 'title': 'fav_noodles'},
    {'id': 38, 'icon': Icons.rice_bowl_outlined, 'title': 'fav_sushi'},
    {'id': 39, 'icon': Icons.soup_kitchen_outlined, 'title': 'fav_ash'},
    {'id': 40, 'icon': Icons.restaurant_menu_rounded, 'title': 'fav_gheymeh'},
    {'id': 41, 'icon': Icons.dinner_dining_outlined, 'title': 'fav_ghormeh'},
    {'id': 42, 'icon': Icons.lunch_dining_outlined, 'title': 'fav_fesenjan'},
    {'id': 43, 'icon': Icons.egg_outlined, 'title': 'fav_kotlet'},
    {'id': 44, 'icon': Icons.brunch_dining_rounded, 'title': 'fav_kuku'},
    {'id': 45, 'icon': Icons.local_florist_rounded, 'title': 'fav_sabzi'},
    {'id': 46, 'icon': Icons.water_outlined, 'title': 'fav_doogh'},
    {'id': 47, 'icon': Icons.icecream_outlined, 'title': 'fav_ice_cream'},
    {'id': 48, 'icon': Icons.cookie_outlined, 'title': 'fav_halva'},
    {'id': 49, 'icon': Icons.cake_outlined, 'title': 'fav_honey'},
    {'id': 50, 'icon': Icons.agriculture_rounded, 'title': 'fav_corn'},
    {'id': 51, 'icon': Icons.grass_outlined, 'title': 'fav_oat'},
    {'id': 52, 'icon': Icons.breakfast_dining, 'title': 'fav_pancake'},
    {'id': 53, 'icon': Icons.spa_outlined, 'title': 'fav_avocado'},
    {'id': 54, 'icon': Icons.cloud_rounded, 'title': 'fav_mushroom'},
    {'id': 55, 'icon': Icons.favorite_outline, 'title': 'fav_strawberry'},
    {'id': 56, 'icon': Icons.brightness_5_rounded, 'title': 'fav_citrus'},
    {'id': 57, 'icon': Icons.emoji_nature_rounded, 'title': 'fav_banana'},
    {'id': 58, 'icon': Icons.park_rounded, 'title': 'fav_dates'},
    {'id': 59, 'icon': Icons.hive_rounded, 'title': 'fav_honey_comb'},
    {'id': 60, 'icon': Icons.water_drop_outlined, 'title': 'fav_olive_oil'},
  ];

  /// restrictionId → favoriteIds that must be hidden
  static const Map<int, List<int>> restrictionToFavorites = {
    // dairy family
    1: [15, 16, 17, 46], // dairy → yogurt, milk, cheese, doogh
    18: [15, 16, 17, 46], // lactose
    19: [15, 16, 17, 46], // casein
    // eggs
    72: [10, 11, 43, 44], // egg white → egg dish, omelette, kotlet, kuku
    73: [10, 11, 43, 44], // egg yolk
    // nuts
    3: [26], // nuts
    4: [26], // peanuts
    20: [26],
    21: [26],
    22: [26],
    23: [26],
    24: [26],
    25: [26],
    26: [26],
    27: [26],
    // fish / seafood
    7: [3, 34, 35, 38], // seafood
    8: [3, 35, 38], // fish
    9: [34, 38], // shellfish
    29: [34], // shrimp
    30: [34],
    31: [34],
    32: [34],
    33: [34],
    34: [34],
    // meats
    68: [32, 33, 4], // red meat → beef, lamb, kebab
    70: [32, 4], // beef
    71: [2], // chicken
    69: [4], // pork ~ kebab-like dishes optional
    // legumes
    57: [27, 28, 29, 30],
    58: [28],
    59: [29],
    60: [30],
    61: [27],
    // produce / other
    67: [31], // potato
    16: [50], // corn
    63: [51], // oat
    56: [54], // mushroom
    36: [55], // strawberry
    37: [56], // citrus
    39: [57], // banana
    40: [53], // avocado
    17: [49, 59], // honey
    45: [21], // coffee
    46: [21], // caffeine
    5: [18, 19, 6, 5], // gluten → bread, pastry, pasta, pizza
    6: [18, 19, 6, 5], // wheat
    10: [27, 28, 29, 30], // soy ~ legumes overlap mild
  };

  static Set<int> hiddenFavoriteIds(List<int> restrictionIds) {
    final out = <int>{};
    for (final rid in restrictionIds) {
      final favs = restrictionToFavorites[rid];
      if (favs != null) out.addAll(favs);
    }
    return out;
  }

  List<PageViewerItem> get visibleItems {
    final hidden = hiddenFavoriteIds(selectedRestrictions);
    return items
        .where((m) => !hidden.contains(m['id'] as int))
        .map(PageViewerItem.fromMap)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Drop any previously selected fav that is now hidden
    final hidden = hiddenFavoriteIds(selectedRestrictions);
    final cleaned =
        selectedFoods.where((id) => !hidden.contains(id)).toList();
    if (cleaned.length != selectedFoods.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(cleaned);
      });
    }

    return PageViewer(
      currentLang: currentLang,
      items: visibleItems,
      selectedIds: cleaned,
      onChanged: onChanged,
      subtitleKey: 'favorite_food_subtitle',
      showSearch: true,
    );
  }
}
