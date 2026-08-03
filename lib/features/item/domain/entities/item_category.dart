import 'package:flutter/material.dart';

enum ItemCategory {
  all('All Items', Icons.grid_view_outlined),
  tools('Power Tools', Icons.build_outlined),
  camping('Camping & Outdoor', Icons.terrain_outlined),
  lawnCare('Lawn & Garden', Icons.grass_outlined),
  electronics('Electronics', Icons.camera_alt_outlined),
  sports('Sports & Fitness', Icons.sports_tennis_outlined),
  party('Party & Event', Icons.celebration_outlined),
  homeAppliance('Home & Kitchen', Icons.kitchen_outlined),
  books('Books & Games', Icons.style_outlined),
  other('Other', Icons.category_outlined);

  final String label;
  final IconData icon;

  const ItemCategory(this.label, this.icon);

  static ItemCategory fromString(String value) {
    return ItemCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ItemCategory.all,
    );
  }
}
