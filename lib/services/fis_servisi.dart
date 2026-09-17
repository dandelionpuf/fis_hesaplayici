import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt.dart';

// ---------------------------------------------------------------------------
// API ANAHTARI ARTIK CLIENT KODUNDA YOK
//
// Gemini çağrısı artık bir Supabase Edge Function üzerinden yapılıyor
// (supabase/functions/analyze-receipt). Anahtar sadece Supabase'in "secrets"
// deposunda duruyor:
//
//   supabase secrets set GEMINI_API_KEY=senin_anahtarin
//
// Client, sadece giriş yapmış kullanıcı olarak bu fonksiyonu çağırıyor;
// Supabase JWT doğrulamasını otomatik yapıyor.
// ---------------------------------------------------------------------------

const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://tiutmnxjjcpolmgztaon.supabase.co',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_uHppRzn58pWfaLZYNWa0SQ_2Moa2uTY',
);

/// Gemini API çağrısının sonucunu (başarı ya da hata mesajı ile) taşır.
class ReceiptAnalysisResult {
  final Receipt? receipt;
  final String? errorMessage;

  ReceiptAnalysisResult._(this.receipt, this.errorMessage);

  factory ReceiptAnalysisResult.success(Receipt r) => ReceiptAnalysisResult._(r, null);
  factory ReceiptAnalysisResult.error(String msg) => ReceiptAnalysisResult._(null, msg);
}

/// Supabase Auth + veritabanı işlemlerini tek yerde toplayan servis.
class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();
  factory SupabaseService() => instance;

  final SupabaseClient _client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // --- AUTH ---

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  String? get currentUserId => _client.auth.currentUser?.id;

  String? get currentUserEmail => _client.auth.currentUser?.email;

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  // --- KULLANICI AYARLARI (gelir + birikim hedefi) ---

  /// Kullanıcının kayıtlı ayarlarını getirir. Hiç kaydı yoksa varsayılanları
  /// döndürür — böylece çıkış/giriş sonrası değerler sıfırlanmaz.
  Future<UserSettings> fetchSettings() async {
    final userId = currentUserId;
    if (userId == null) return UserSettings.defaults;

    try {
      final data = await _client
          .from('kullanici_ayarlari')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return UserSettings.defaults;
      return UserSettings.fromMap(data);
    } catch (e) {
      debugPrint("Ayarlar çekilemedi: $e");
      return UserSettings.defaults;
    }
  }

  /// Ayarları kaydeder. upsert kullanıyoruz: kayıt yoksa oluşturur, varsa
  /// günceller (user_id birincil anahtar olduğu için çakışma olmuyor).
  Future<void> saveSettings(UserSettings settings) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.from('kullanici_ayarlari').upsert({
      'user_id': userId,
      'aylik_gelir': settings.monthlyIncome,
      'birikim_hedefi': settings.savingsGoal,
      'guncelleme_tarihi': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // --- HARCAMALAR ---

  Future<List<Receipt>> fetchReceipts() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final data = await _client
        .from('harcamalar')
        .select()
        .eq('user_id', userId)
        .order('tarih', ascending: false);

    return (data as List<dynamic>).map((row) {
      final List<dynamic> rawItems = row['kalemler'] ?? [];
      final items = rawItems.map((e) => ReceiptItem.fromMap(e)).toList();

      return Receipt(
        id: row['id'].toString(),
        storeName: row['isletme_adi'] ?? 'Market',
        date: DateTime.tryParse(row['tarih'] ?? '') ?? DateTime.now(),
        items: items,
      );
    }).toList();
  }

  Future<void> addReceipt(Receipt r) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.from('harcamalar').insert({
      'user_id': userId,
      'isletme_adi': r.storeName,
      'toplam_tutar': r.totalAmount,
      'tarih': r.date.toIso8601String().substring(0, 10),
      'kategori': r.items.isNotEmpty ? r.items.first.category.title : 'Diger',
      'kalemler': r.items.map((e) => e.toMap()).toList(),
    });
  }

  // --- BİRİKİMLER ---

  Future<List<SavingsEntry>> fetchSavings() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final data = await _client
        .from('birikimler')
        .select()
        .eq('user_id', userId)
        .order('tarih', ascending: false);

    return (data as List<dynamic>).map((row) => SavingsEntry.fromMap(row)).toList();
  }

  Future<void> addSaving({
    required SavingsType type,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.from('birikimler').insert({
      'user_id': userId,
      'tur': type.name,
      'tutar': amount,
      'aciklama': note,
      'tarih': date.toIso8601String().substring(0, 10),
    });
  }

  Future<void> deleteSaving(String id) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.from('birikimler').delete().eq('id', id).eq('user_id', userId);
  }
}

/// Fiş görselini Supabase Edge Function'a (analyze-receipt) gönderip
/// yapılandırılmış sonuca çevirir. Gemini API anahtarı artık bu istemcide
/// hiç bulunmuyor — anahtar sadece Edge Function'ın çalıştığı sunucuda.
class GeminiService {
  Future<ReceiptAnalysisResult> analyzeReceipt(Uint8List imageBytes) async {
    try {
      debugPrint("analyze-receipt Edge Function çağrılıyor...");

      final response = await Supabase.instance.client.functions.invoke(
        'analyze-receipt',
        body: {
          'image': base64Encode(imageBytes),
          'mimeType': 'image/jpeg',
        },
      );

      debugPrint("Edge Function yanıt kodu: ${response.status}");

      final data = response.data;

      if (response.status != 200) {
        final reason = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Sunucu hatası (HTTP ${response.status})';
        return ReceiptAnalysisResult.error(reason);
      }

      if (data is! Map) {
        return ReceiptAnalysisResult.error('Sunucudan beklenmeyen yanıt geldi.');
      }

      if (data['error'] != null) {
        return ReceiptAnalysisResult.error(data['error'].toString());
      }

      final List<dynamic> rawItems = data['items'] ?? [];
      final List<ReceiptItem> items = rawItems.map((item) {
        return ReceiptItem(
          name: item['name'] ?? 'Ürün',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          category: ExpenseCategory.fromString(item['category'] ?? 'diger'),
        );
      }).where((item) => item.price > 0).toList();

      if (items.isEmpty) {
        return ReceiptAnalysisResult.error(
            'Fişteki ürünler net okunamadı. Daha aydınlık/net bir fotoğraf deneyin.');
      }

      final receipt = Receipt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        storeName: data['storeName'] ?? 'Market',
        date: DateTime.now(),
        items: items,
        receiptImage: imageBytes,
      );
      return ReceiptAnalysisResult.success(receipt);
    } catch (e) {
      debugPrint("analyze-receipt çağrı hatası -> $e");
      return ReceiptAnalysisResult.error('Beklenmeyen hata: $e');
    }
  }
}