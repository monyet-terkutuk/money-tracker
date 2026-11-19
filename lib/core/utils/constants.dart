const String appName = 'Catat Uang Pribadi';
const String dbFileName = 'catat_uang.db';
const String apiKeyPrefKey = 'deepseek_api_key';
const String darkModePrefKey = 'dark_mode';
const String budgetPrefKey = 'category_budgets_v1';
const int undoDeleteDurationSeconds = 5;
const int latteFactorThreshold = 35000;
const int latteFactorMinCount = 3;

const List<String> paymentMethods = [
  'cash',
  'debit',
  'credit',
  'qris',
  'ewallet',
  'unknown',
];

const Map<String, String> paymentMethodLabels = {
  'cash': 'Tunai',
  'debit': 'Debit',
  'credit': 'Kredit',
  'qris': 'QRIS',
  'ewallet': 'E-Wallet',
  'unknown': 'Lainnya',
};

const List<String> expenseCategories = [
  'Makanan & Minuman',
  'Transportasi',
  'Belanja & Kebutuhan',
  'Tagihan & Isi Ulang',
  'Kesehatan',
  'Hiburan',
  'Pendidikan',
  'Rumah Tangga',
  'Lainnya',
];

const List<String> incomeCategories = [
  'Gaji',
  'Bonus',
  'Freelance',
  'Investasi',
  'Hadiah',
  'Lainnya',
];

const Map<String, String> categoryIcons = {
  'Makanan & Minuman': 'restaurant',
  'Transportasi': 'directions_car',
  'Belanja & Kebutuhan': 'shopping_cart',
  'Tagihan & Isi Ulang': 'receipt_long',
  'Kesehatan': 'local_hospital',
  'Hiburan': 'movie',
  'Pendidikan': 'school',
  'Rumah Tangga': 'home',
  'Gaji': 'business_center',
  'Bonus': 'card_giftcard',
  'Freelance': 'laptop',
  'Investasi': 'trending_up',
  'Hadiah': 'celebration',
  'Lainnya': 'category',
};
