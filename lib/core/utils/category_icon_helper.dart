import 'package:flutter/material.dart';

class CategoryIconOption {
  final String key;
  final String label;
  final IconData icon;

  const CategoryIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const List<CategoryIconOption> availableCategoryIcons = [
  CategoryIconOption(key: 'restaurant', label: 'Makan', icon: Icons.restaurant_rounded),
  CategoryIconOption(key: 'coffee', label: 'Kopi', icon: Icons.local_cafe_rounded),
  CategoryIconOption(key: 'directions_car', label: 'Transport', icon: Icons.directions_car_rounded),
  CategoryIconOption(key: 'shopping_cart', label: 'Belanja', icon: Icons.shopping_bag_rounded),
  CategoryIconOption(key: 'receipt_long', label: 'Tagihan', icon: Icons.receipt_long_rounded),
  CategoryIconOption(key: 'electric_bolt', label: 'Listrik', icon: Icons.bolt_rounded),
  CategoryIconOption(key: 'local_hospital', label: 'Sehat', icon: Icons.medical_services_rounded),
  CategoryIconOption(key: 'movie', label: 'Hiburan', icon: Icons.movie_rounded),
  CategoryIconOption(key: 'school', label: 'Edukasi', icon: Icons.school_rounded),
  CategoryIconOption(key: 'home', label: 'Rumah', icon: Icons.home_rounded),
  CategoryIconOption(key: 'subscriptions', label: 'Langganan', icon: Icons.autorenew_rounded),
  CategoryIconOption(key: 'flight', label: 'Travel', icon: Icons.flight_takeoff_rounded),
  CategoryIconOption(key: 'fitness_center', label: 'Olahraga', icon: Icons.fitness_center_rounded),
  CategoryIconOption(key: 'pets', label: 'Peliharaan', icon: Icons.pets_rounded),
  CategoryIconOption(key: 'business_center', label: 'Gaji', icon: Icons.work_rounded),
  CategoryIconOption(key: 'card_giftcard', label: 'Bonus', icon: Icons.card_giftcard_rounded),
  CategoryIconOption(key: 'laptop', label: 'Freelance', icon: Icons.laptop_mac_rounded),
  CategoryIconOption(key: 'trending_up', label: 'Investasi', icon: Icons.trending_up_rounded),
  CategoryIconOption(key: 'savings', label: 'Tabungan', icon: Icons.savings_rounded),
  CategoryIconOption(key: 'celebration', label: 'Hadiah', icon: Icons.celebration_rounded),
  CategoryIconOption(key: 'category', label: 'Lainnya', icon: Icons.category_rounded),
];

const Map<String, IconData> _iconByKey = {
  'restaurant': Icons.restaurant_rounded,
  'coffee': Icons.local_cafe_rounded,
  'directions_car': Icons.directions_car_rounded,
  'shopping_cart': Icons.shopping_bag_rounded,
  'receipt_long': Icons.receipt_long_rounded,
  'electric_bolt': Icons.bolt_rounded,
  'local_hospital': Icons.medical_services_rounded,
  'movie': Icons.movie_rounded,
  'school': Icons.school_rounded,
  'home': Icons.home_rounded,
  'subscriptions': Icons.autorenew_rounded,
  'flight': Icons.flight_takeoff_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'pets': Icons.pets_rounded,
  'business_center': Icons.work_rounded,
  'card_giftcard': Icons.card_giftcard_rounded,
  'laptop': Icons.laptop_mac_rounded,
  'trending_up': Icons.trending_up_rounded,
  'savings': Icons.savings_rounded,
  'celebration': Icons.celebration_rounded,
  'category': Icons.category_rounded,
};

const Map<String, Color> _colorByKey = {
  'restaurant': Color(0xFFD97706),
  'coffee': Color(0xFF92400E),
  'directions_car': Color(0xFF2563EB),
  'shopping_cart': Color(0xFFDB2777),
  'receipt_long': Color(0xFF7C3AED),
  'electric_bolt': Color(0xFFEAB308),
  'local_hospital': Color(0xFFDC2626),
  'movie': Color(0xFF9333EA),
  'school': Color(0xFF0284C7),
  'home': Color(0xFF0D9488),
  'subscriptions': Color(0xFF6366F1),
  'flight': Color(0xFF0891B2),
  'fitness_center': Color(0xFF16A34A),
  'pets': Color(0xFFEA580C),
  'business_center': Color(0xFF15803D),
  'card_giftcard': Color(0xFF059669),
  'laptop': Color(0xFF4F46E5),
  'trending_up': Color(0xFF0D9488),
  'savings': Color(0xFF16A34A),
  'celebration': Color(0xFFE11D48),
  'category': Color(0xFF64748B),
};

IconData resolveCategoryIcon(
  String? iconKey, {
  String? categoryName,
  String? type,
}) {
  if (iconKey != null && _iconByKey.containsKey(iconKey)) {
    return _iconByKey[iconKey]!;
  }
  final name = (categoryName ?? '').toLowerCase();
  if (name.contains('makan') || name.contains('minum')) return Icons.restaurant_rounded;
  if (name.contains('kopi') || name.contains('cafe')) return Icons.local_cafe_rounded;
  if (name.contains('transport') || name.contains('bensin') || name.contains('ojek')) {
    return Icons.directions_car_rounded;
  }
  if (name.contains('belanja')) return Icons.shopping_bag_rounded;
  if (name.contains('tagihan') || name.contains('listrik')) return Icons.receipt_long_rounded;
  if (name.contains('sehat') || name.contains('obat')) return Icons.medical_services_rounded;
  if (name.contains('hibur')) return Icons.movie_rounded;
  if (name.contains('didik') || name.contains('kuliah')) return Icons.school_rounded;
  if (name.contains('rumah') || name.contains('kos')) return Icons.home_rounded;
  if (name.contains('gaji')) return Icons.work_rounded;
  if (name.contains('bonus')) return Icons.card_giftcard_rounded;
  if (name.contains('freelance')) return Icons.laptop_mac_rounded;
  if (name.contains('invest')) return Icons.trending_up_rounded;
  if (name.contains('hadiah')) return Icons.celebration_rounded;
  if (type == 'income') return Icons.south_west_rounded;
  return Icons.category_rounded;
}

Color resolveCategoryAccent(
  String? iconKey, {
  required Color fallback,
}) {
  if (iconKey != null && _colorByKey.containsKey(iconKey)) {
    return _colorByKey[iconKey]!;
  }
  return fallback;
}
