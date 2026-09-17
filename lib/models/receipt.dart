import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Harcama kategorileri. Yeni bir kategori eklemek istersen buraya bir satır
/// ekleyip fromString() içine de anahtar kelimelerini yazman yeterli;
/// grafikler, kartlar ve Gemini prompt'u otomatik olarak uyum sağlar.
enum ExpenseCategory {
  gida('Temel Gida', Icons.restaurant_rounded, Color(0xFFE0F2FE), Color(0xFF0284C7)),
  hijyen('Hijyen', Icons.clean_hands_rounded, Color(0xFFDCFCE7), Color(0xFF16A34A)),
  kozmetik('Kozmetik', Icons.spa_rounded, Color(0xFFFCE7F3), Color(0xFFDB2777)),
  saglik('Saglik', Icons.medical_services_rounded, Color(0xFFFEE2E2), Color(0xFFDC2626)),
  elektronik('Elektronik', Icons.devices_rounded, Color(0xFFE0E7FF), Color(0xFF4F46E5)),
  giyim('Giyim', Icons.checkroom_rounded, Color(0xFFFFE4E6), Color(0xFFE11D48)),
  ulasim('Ulasim', Icons.directions_bus_rounded, Color(0xFFFEF3C7), Color(0xFFD97706)),
  eglence('Eglence', Icons.movie_rounded, Color(0xFFF3E8FF), Color(0xFF9333EA)),
  fatura('Fatura', Icons.receipt_rounded, Color(0xFFCCFBF1), Color(0xFF0D9488)),
  evesya('Ev Esyasi', Icons.chair_rounded, Color(0xFFFFEDD5), Color(0xFFEA580C)),
  diger('Diger', Icons.shopping_bag_rounded, Color(0xFFF1F5F9), Color(0xFF64748B));

  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const ExpenseCategory(this.title, this.icon, this.bgColor, this.iconColor);

  static ExpenseCategory fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'gida':
      case 'gıda':
      case 'temel gida':
        return ExpenseCategory.gida;
      case 'hijyen':
        return ExpenseCategory.hijyen;
      case 'kozmetik':
        return ExpenseCategory.kozmetik;
      case 'saglik':
      case 'sağlık':
        return ExpenseCategory.saglik;
      case 'elektronik':
        return ExpenseCategory.elektronik;
      case 'giyim':
        return ExpenseCategory.giyim;
      case 'ulasim':
      case 'ulaşım':
        return ExpenseCategory.ulasim;
      case 'eglence':
      case 'eğlence':
        return ExpenseCategory.eglence;
      case 'fatura':
        return ExpenseCategory.fatura;
      case 'evesya':
      case 'ev esyasi':
      case 'ev eşyası':
        return ExpenseCategory.evesya;
      default:
        return ExpenseCategory.diger;
    }
  }

  /// Gemini prompt'unda kullanılmak üzere geçerli kategori anahtarları.
  static String get promptKeyList =>
      ExpenseCategory.values.map((e) => "'${e.name}'").join(', ');
}

class ReceiptItem {
  final String name;
  final double price;
  final ExpenseCategory category;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'category': category.name,
      };

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromString(map['category'] ?? 'diger'),
    );
  }
}

class Receipt {
  final String id;
  final String storeName;
  final DateTime date;
  final List<ReceiptItem> items;
  final Uint8List? receiptImage;

  Receipt({
    required this.id,
    required this.storeName,
    required this.date,
    required this.items,
    this.receiptImage,
  });

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.price);
}

/// Birikim türleri — kullanıcı parasını nerede tuttuğunu seçiyor.
enum SavingsType {
  nakit('Nakit', Icons.payments_rounded, Color(0xFFDCFCE7), Color(0xFF16A34A)),
  altin('Altin', Icons.diamond_rounded, Color(0xFFFEF3C7), Color(0xFFD97706)),
  doviz('Doviz', Icons.currency_exchange_rounded, Color(0xFFE0F2FE), Color(0xFF0284C7)),
  borsa('Borsa / Hisse', Icons.trending_up_rounded, Color(0xFFE0E7FF), Color(0xFF4F46E5)),
  fon('Yatirim Fonu', Icons.account_balance_wallet_rounded, Color(0xFFCCFBF1), Color(0xFF0D9488)),
  mevduat('Vadeli Mevduat', Icons.account_balance_rounded, Color(0xFFF1F5F9), Color(0xFF475569)),
  kripto('Kripto', Icons.currency_bitcoin_rounded, Color(0xFFF3E8FF), Color(0xFF9333EA)),
  diger('Diger', Icons.savings_rounded, Color(0xFFFFE4E6), Color(0xFFE11D48));

  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const SavingsType(this.title, this.icon, this.bgColor, this.iconColor);

  static SavingsType fromString(String val) {
    return SavingsType.values.firstWhere(
      (e) => e.name == val.toLowerCase().trim(),
      orElse: () => SavingsType.diger,
    );
  }
}

/// Tek bir birikim kaydı (ör. "5 gram altın aldım" ya da "vadeliye 3000 TL").
class SavingsEntry {
  final String id;
  final SavingsType type;
  final double amount;
  final String note;
  final DateTime date;

  SavingsEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });

  factory SavingsEntry.fromMap(Map<String, dynamic> map) {
    return SavingsEntry(
      id: map['id'].toString(),
      type: SavingsType.fromString(map['tur'] ?? 'diger'),
      amount: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      note: map['aciklama'] ?? '',
      date: DateTime.tryParse(map['tarih'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Kullanıcının kişisel ayarları — Supabase'de saklanır, böylece çıkış yapıp
/// tekrar girince varsayılan değerlere dönmez.
class UserSettings {
  final double monthlyIncome;
  final double savingsGoal;

  const UserSettings({
    required this.monthlyIncome,
    required this.savingsGoal,
  });

  static const UserSettings defaults = UserSettings(
    monthlyIncome: 25000.0,
    savingsGoal: 5000.0,
  );

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      monthlyIncome: (map['aylik_gelir'] as num?)?.toDouble() ?? defaults.monthlyIncome,
      savingsGoal: (map['birikim_hedefi'] as num?)?.toDouble() ?? defaults.savingsGoal,
    );
  }

  UserSettings copyWith({double? monthlyIncome, double? savingsGoal}) {
    return UserSettings(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
    );
  }
}

String getMonthName(int month) {
  const months = [
    'Ocak', 'Subat', 'Mart', 'Nisan', 'Mayis', 'Haziran',
    'Temmuz', 'Agustos', 'Eylul', 'Ekim', 'Kasim', 'Aralik'
  ];
  return months[month - 1];
}