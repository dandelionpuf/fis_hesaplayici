import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'models/receipt.dart';
import 'services/fis_servisi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  runApp(const FisHesaplayiciApp());
}

class FisHesaplayiciApp extends StatelessWidget {
  const FisHesaplayiciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nereye Gitti?',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const MobileFrame(child: AuthGate()),
    );
  }
}

class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Gerçek telefonda sahte çerçeve ekranı kırpıyordu. Çerçeveyi sadece
    // geniş ekranlarda (web/masaüstü önizleme) gösteriyoruz.
    final bool isRealPhone = size.width < 500;

    if (isRealPhone) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      body: Center(
        child: Container(
          width: 414,
          height: 896,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.black12, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Oturum durumuna göre Giriş ekranı ya da Ana ekranı gösterir.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = SupabaseService().authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        final session = SupabaseService().currentSession;
        if (session != null) {
          return MainShellScreen(key: ValueKey(session.user.id));
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUpMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'E-posta ve şifre gerekli.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUpMode) {
        await SupabaseService().signUp(email: email, password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt başarılı! Giriş yapılıyor...'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      } else {
        await SupabaseService().signIn(email: email, password: password);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Beklenmeyen bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nereye Gitti?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUpMode ? 'Yeni bir hesap oluştur' : 'Devam etmek için giriş yap',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isSignUpMode ? 'Kayıt Ol' : 'Giriş Yap',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _isSignUpMode = !_isSignUpMode;
                          _errorMessage = null;
                        }),
                child: Text(
                  _isSignUpMode ? 'Zaten hesabın var mı? Giriş yap' : 'Hesabın yok mu? Kayıt ol',
                  style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  int _remainingDailyScans = 2;
  int _adBonusEarnedToday = 0; // Reklamla kazanılan hak, günde max 2
  bool _isPremium = false;

  // Ayarlar artık Supabase'den geliyor — çıkış/giriş sonrası sıfırlanmıyor.
  UserSettings _settings = UserSettings.defaults;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final List<Receipt> _receipts = [];
  final List<SavingsEntry> _savings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    // Ana ekran için gereken ayarlar ve fişleri önce çekiyoruz; biri hata
    // verse bile diğeri yüklensin diye her çağrıyı ayrı ayrı yakalıyoruz.
    final settingsFuture = SupabaseService().fetchSettings().catchError((e) {
      debugPrint("Ayarlar çekilemedi: $e");
      return UserSettings.defaults;
    });
    final receiptsFuture = SupabaseService().fetchReceipts().catchError((e) {
      debugPrint("Fişler çekilemedi: $e");
      return <Receipt>[];
    });

    final results = await Future.wait([settingsFuture, receiptsFuture]);

    if (!mounted) return;
    setState(() {
      _settings = results[0] as UserSettings;
      _receipts
        ..clear()
        ..addAll(results[1] as List<Receipt>);
      _isLoading = false; // Ekran burada açılıyor, birikimleri beklemiyor.
    });

    // Birikimler arka planda yükleniyor — açılışı geciktirmesin.
    _loadSavings();
  }

  Future<void> _loadSavings() async {
    try {
      final fresh = await SupabaseService().fetchSavings();
      if (!mounted) return;
      setState(() {
        _savings
          ..clear()
          ..addAll(fresh);
      });
    } catch (e) {
      debugPrint("Birikimler çekilemedi: $e");
    }
  }

  // Ayar değiştiğinde önce ekranı güncelle (hızlı hissettirir), sonra kaydet.
  Future<void> _updateIncome(double newIncome) async {
    setState(() => _settings = _settings.copyWith(monthlyIncome: newIncome));
    try {
      await SupabaseService().saveSettings(_settings);
    } catch (e) {
      debugPrint("Gelir kaydedilemedi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayar kaydedilemedi, internet bağlantını kontrol et.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _updateSavingsGoal(double newGoal) async {
    setState(() => _settings = _settings.copyWith(savingsGoal: newGoal));
    try {
      await SupabaseService().saveSettings(_settings);
    } catch (e) {
      debugPrint("Hedef kaydedilemedi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayar kaydedilemedi, internet bağlantını kontrol et.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _changeMonth(DateTime newMonth) {
    setState(() => _selectedMonth = newMonth);
  }

  void _watchRewardAd() {
    // Günlük reklam bonusu 2 ile sınırlı.
    if (_adBonusEarnedToday >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bugünlük reklam hakkın doldu (max +2). Yarın tekrar dene!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 18),
            Text('Reklam aciliyor...', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Lutfen bekleyin hakkiniz tanimlaniyor', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        _remainingDailyScans += 1;
        _adBonusEarnedToday += 1;
      });
      final kalan = 2 - _adBonusEarnedToday;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kalan > 0
              ? 'Kaptin +1 hakki! 🎉 (Bugün için $kalan reklam hakkın daha kaldı)'
              : 'Kaptin +1 hakki! 🎉 Bugünlük reklam hakların bitti.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _togglePremium(bool value) {
    setState(() => _isPremium = value);
  }

  Future<void> _signOut() async {
    await SupabaseService().signOut();
  }

  Future<void> _addNewReceipt(Receipt r) async {
    setState(() {
      _receipts.insert(0, r);
      if (!_isPremium && _remainingDailyScans > 0) {
        _remainingDailyScans--;
      }
      _currentIndex = 0;
    });

    try {
      await SupabaseService().addReceipt(r);
    } catch (e) {
      debugPrint("Supabase ekleme hatası: $e");
    }
  }

  Future<void> _addSaving(SavingsType type, double amount, String note) async {
    try {
      await SupabaseService().addSaving(
        type: type,
        amount: amount,
        note: note,
        date: DateTime.now(),
      );
      // Gerçek id'yi almak için listeyi yeniden çekiyoruz.
      final fresh = await SupabaseService().fetchSavings();
      if (!mounted) return;
      setState(() {
        _savings
          ..clear()
          ..addAll(fresh);
      });
    } catch (e) {
      debugPrint("Birikim eklenemedi: $e");
      if (mounted) {
        // Gerçek hata mesajını gösteriyoruz; "başarısız" demek sorunu
        // bulmayı imkansızlaştırıyordu (ör. tablo yok, RLS engeli vb).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Birikim eklenemedi: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _deleteSaving(String id) async {
    final backup = List<SavingsEntry>.from(_savings);
    setState(() => _savings.removeWhere((s) => s.id == id));
    try {
      await SupabaseService().deleteSaving(id);
    } catch (e) {
      debugPrint("Birikim silinemedi: $e");
      if (mounted) {
        setState(() {
          _savings
            ..clear()
            ..addAll(backup);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReceipts = _receipts.where((r) {
      return r.date.year == _selectedMonth.year && r.date.month == _selectedMonth.month;
    }).toList();

    final int adBonusRemaining = 2 - _adBonusEarnedToday;

    final List<Widget> pages = [
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DashboardScreen(
              receipts: filteredReceipts,
              remainingScans: _remainingDailyScans,
              adBonusRemaining: adBonusRemaining,
              isPremium: _isPremium,
              monthlyIncome: _settings.monthlyIncome,
              savingsGoal: _settings.savingsGoal,
              totalSavings: _savings.fold(0.0, (s, e) => s + e.amount),
              onUpdateIncome: _updateIncome,
              onUpdateSavings: _updateSavingsGoal,
              onWatchAd: _watchRewardAd,
              selectedMonth: _selectedMonth,
              onMonthChanged: _changeMonth,
              onSignOut: _signOut,
              onGoToSavings: () => setState(() => _currentIndex = 3),
            ),
      ScanReceiptScreen(
        remainingScans: _remainingDailyScans,
        adBonusRemaining: adBonusRemaining,
        isPremium: _isPremium,
        onAddReceipt: _addNewReceipt,
        onWatchAd: _watchRewardAd,
      ),
      ReportsScreen(
        receipts: _receipts,
        monthlyIncome: _settings.monthlyIncome,
      ),
      SavingsScreen(
        savings: _savings,
        savingsGoal: _settings.savingsGoal,
        onAddSaving: _addSaving,
        onDeleteSaving: _deleteSaving,
        onUpdateGoal: _updateSavingsGoal,
      ),
      SubscriptionScreen(
        isPremium: _isPremium,
        remainingScans: _remainingDailyScans,
        adBonusRemaining: adBonusRemaining,
        onTogglePremium: _togglePremium,
        onWatchAd: _watchRewardAd,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E293B),
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Harcamalar'),
            BottomNavigationBarItem(icon: Icon(Icons.document_scanner_outlined), activeIcon: Icon(Icons.document_scanner), label: 'Fis At'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Grafik'),
            BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), activeIcon: Icon(Icons.savings), label: 'Birikim'),
            BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_outlined), activeIcon: Icon(Icons.workspace_premium), label: 'Abonelik'),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final List<Receipt> receipts;
  final int remainingScans;
  final int adBonusRemaining;
  final bool isPremium;
  final double monthlyIncome;
  final double savingsGoal;
  final double totalSavings;
  final ValueChanged<double> onUpdateIncome;
  final ValueChanged<double> onUpdateSavings;
  final VoidCallback onWatchAd;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onSignOut;
  final VoidCallback onGoToSavings;

  const DashboardScreen({
    super.key,
    required this.receipts,
    required this.remainingScans,
    required this.adBonusRemaining,
    required this.isPremium,
    required this.monthlyIncome,
    required this.savingsGoal,
    required this.totalSavings,
    required this.onUpdateIncome,
    required this.onUpdateSavings,
    required this.onWatchAd,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onSignOut,
    required this.onGoToSavings,
  });

  double _categoryTotal(ExpenseCategory cat) {
    double sum = 0;
    for (var r in receipts) {
      for (var item in r.items) {
        if (item.category == cat) sum += item.price;
      }
    }
    return sum;
  }

  double get _grandTotal => receipts.fold(0.0, (sum, r) => sum + r.totalAmount);
  double get _remainingBudget => monthlyIncome - _grandTotal;

  void _showSignOutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkış yap', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onSignOut();
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditNumberDialog({
    required BuildContext context,
    required String title,
    required double currentValue,
    required ValueChanged<double> onSave,
  }) {
    final controller = TextEditingController(text: currentValue.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tutar gir',
            prefixText: '₺ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgec', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val >= 0) onSave(val);
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sadece harcaması olan kategorileri gösteriyoruz; kategori sayısı arttığı
    // için hepsini göstermek ekranı gereksiz uzatırdı.
    final aktifKategoriler = ExpenseCategory.values
        .where((c) => _categoryTotal(c) > 0)
        .toList()
      ..sort((a, b) => _categoryTotal(b).compareTo(_categoryTotal(a)));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Selam :)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text('Ne Harcadik?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPremium ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPremium ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPremium ? Icons.workspace_premium_rounded : Icons.flash_on_rounded,
                        size: 16,
                        color: isPremium ? const Color(0xFFD97706) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? 'Sinirsiz' : '$remainingScans/2 Hak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPremium ? const Color(0xFFD97706) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showSignOutConfirm(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (ctx, index) {
              final now = DateTime.now();
              final m = DateTime(now.year, now.month - (5 - index));
              final isSelected = m.year == selectedMonth.year && m.month == selectedMonth.month;

              return GestureDetector(
                onTap: () => onMonthChanged(m),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      '${getMonthName(m.month)} ${m.year}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (!isPremium && remainingScans == 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: adBonusRemaining > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: adBonusRemaining > 0 ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Icon(Icons.ondemand_video_rounded, color: adBonusRemaining > 0 ? const Color(0xFFD97706) : Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gunluk hakkin bitti!',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: adBonusRemaining > 0 ? const Color(0xFF92400E) : const Color(0xFF64748B))),
                      Text(
                        adBonusRemaining > 0
                            ? 'Reklam izle, +1 hak kap. (Bugün $adBonusRemaining hakkın var)'
                            : 'Bugünlük reklam hakların bitti, yarın tekrar dene.',
                        style: TextStyle(fontSize: 11, color: adBonusRemaining > 0 ? const Color(0xFFB45309) : Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: adBonusRemaining > 0 ? onWatchAd : null,
                  style: TextButton.styleFrom(
                    backgroundColor: adBonusRemaining > 0 ? const Color(0xFFD97706) : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Izle (+1)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text('Aylik Net Gelir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showEditNumberDialog(
                      context: context,
                      title: 'Aylik net gelir',
                      currentValue: monthlyIncome,
                      onSave: onUpdateIncome,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 13, color: Color(0xFF475569)),
                          SizedBox(width: 4),
                          Text('Duzenle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₺${monthlyIncome.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Kalan Para', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                      Text(
                        '₺${_remainingBudget.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _remainingBudget >= 0 ? const Color(0xFF1E293B) : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onGoToSavings,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                      child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Toplam Birikimin',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFB45309)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('₺${totalSavings.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                        const SizedBox(height: 2),
                        Text('Hedef: ₺${savingsGoal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFB45309))),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _showEditNumberDialog(
                    context: context,
                    title: 'Birikim Hedefin',
                    currentValue: savingsGoal,
                    onSave: onUpdateSavings,
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Hedef', style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cebimizden Cikan (Toplam Harcama)',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('₺${_grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${receipts.length} Fis Islendi',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Kategori Masraflari', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        if (aktifKategoriler.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text('Bu ay icin kategori verisi yok', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: aktifKategoriler.map((cat) {
              final total = _categoryTotal(cat);
              final oran = _grandTotal > 0 ? (total / _grandTotal).clamp(0.0, 1.0) : 0.0;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: cat.bgColor, borderRadius: BorderRadius.circular(12)),
                      child: Icon(cat.icon, color: cat.iconColor, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('₺${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: oran,
                            minHeight: 4,
                            backgroundColor: cat.bgColor,
                            valueColor: AlwaysStoppedAnimation<Color>(cat.iconColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 26),
        const Text('Gecmis Fisler', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        if (receipts.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: const [
                Icon(Icons.receipt_long_outlined, size: 42, color: Colors.grey),
                SizedBox(height: 10),
                Text('Henuz taranmis bir fis yok', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                SizedBox(height: 4),
                Text('Alttaki "Fis At" butonundan ilk fisini yukleyebilirsin',
                    style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...receipts.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF475569)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text('${r.items.length} parca • ${r.date.day}.${r.date.month}.${r.date.year}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₺${r.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  ],
                ),
              )),
      ],
    );
  }
}

/// Birikim sayfası — altın, borsa, döviz gibi türlerde birikim ekleyip
/// hedefe ne kadar yaklaştığını gösterir.
class SavingsScreen extends StatelessWidget {
  final List<SavingsEntry> savings;
  final double savingsGoal;
  final Function(SavingsType, double, String) onAddSaving;
  final ValueChanged<String> onDeleteSaving;
  final ValueChanged<double> onUpdateGoal;

  const SavingsScreen({
    super.key,
    required this.savings,
    required this.savingsGoal,
    required this.onAddSaving,
    required this.onDeleteSaving,
    required this.onUpdateGoal,
  });

  double get _total => savings.fold(0.0, (sum, s) => sum + s.amount);

  double _typeTotal(SavingsType t) =>
      savings.where((s) => s.type == t).fold(0.0, (sum, s) => sum + s.amount);

  void _showAddDialog(BuildContext context) {
    SavingsType selected = SavingsType.nakit;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Birikim Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tur sec', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: SavingsType.values.map((t) {
                    final isSelected = t == selected;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => selected = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? t.iconColor : t.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 14, color: isSelected ? Colors.white : t.iconColor),
                            const SizedBox(width: 4),
                            Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : t.iconColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Tutar',
                    prefixText: '₺ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Not (istege bagli)',
                    hintText: 'Ornek: 2 gram altin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgec', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final val = double.tryParse(amountController.text.replaceAll(',', '.'));
                if (val != null && val > 0) {
                  onAddSaving(selected, val, noteController.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final controller = TextEditingController(text: savingsGoal.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Birikim Hedefin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '₺ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgec', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val >= 0) onUpdateGoal(val);
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SavingsEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kaydi sil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${entry.type.title} - ₺${entry.amount.toStringAsFixed(2)} kaydini silmek istiyor musun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgec', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteSaving(entry.id);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = savingsGoal > 0 ? (_total / savingsGoal).clamp(0.0, 1.0) : 0.0;
    final hedefeUlasildi = savingsGoal > 0 && _total >= savingsGoal;

    final aktifTurler = SavingsType.values.where((t) => _typeTotal(t) > 0).toList()
      ..sort((a, b) => _typeTotal(b).compareTo(_typeTotal(a)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Birikim Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Birikimlerim', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('Altin, borsa, doviz... hepsi tek yerde', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              GestureDetector(
                onTap: () => _showGoalDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.flag_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hedefeUlasildi
                    ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                const Text('Toplam Birikim', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('₺${_total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(hedefeUlasildi ? Colors.white : const Color(0xFFF59E0B)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hedefin %${(progress * 100).toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('Hedef: ₺${savingsGoal.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (hedefeUlasildi) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('🎉 Hedefe ulastin!',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Dagilim', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          if (aktifTurler.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: const [
                  Icon(Icons.savings_outlined, size: 42, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Henuz birikim kaydin yok', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  SizedBox(height: 4),
                  Text('Asagidaki butondan ilk birikimini ekle', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else
            ...aktifTurler.map((t) {
              final tutar = _typeTotal(t);
              final oran = _total > 0 ? (tutar / _total).clamp(0.0, 1.0) : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: t.bgColor, borderRadius: BorderRadius.circular(14)),
                      child: Icon(t.icon, color: t.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                              Text('₺${tutar.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: oran,
                              minHeight: 5,
                              backgroundColor: t.bgColor,
                              valueColor: AlwaysStoppedAnimation<Color>(t.iconColor),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text('Toplamin %${(oran * 100).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (savings.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Islem Gecmisi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            ...savings.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: s.type.bgColor, borderRadius: BorderRadius.circular(12)),
                        child: Icon(s.type.icon, color: s.type.iconColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.type.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                            const SizedBox(height: 2),
                            Text(
                              s.note.isEmpty
                                  ? '${s.date.day}.${s.date.month}.${s.date.year}'
                                  : '${s.note} • ${s.date.day}.${s.date.month}.${s.date.year}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text('₺${s.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF16A34A))),
                      IconButton(
                        onPressed: () => _confirmDelete(context, s),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 8),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class ScanReceiptScreen extends StatefulWidget {
  final int remainingScans;
  final int adBonusRemaining;
  final bool isPremium;
  final Function(Receipt) onAddReceipt;
  final VoidCallback onWatchAd;

  const ScanReceiptScreen({
    super.key,
    required this.remainingScans,
    required this.adBonusRemaining,
    required this.isPremium,
    required this.onAddReceipt,
    required this.onWatchAd,
  });

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  bool _isProcessing = false;
  String? _lastErrorMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        // Fiş üzerindeki küçük yazılar için çözünürlük ve kalite yüksek.
        maxWidth: 1600,
        imageQuality: 92,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _isProcessing = true;
          _lastErrorMessage = null;
        });

        final result = await GeminiService().analyzeReceipt(bytes);

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (result.receipt != null) {
          widget.onAddReceipt(result.receipt!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.receipt!.storeName} fişi okundu! ₺${result.receipt!.totalAmount.toStringAsFixed(2)}'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        } else {
          setState(() => _lastErrorMessage = result.errorMessage);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Fiş net okunamadı, lütfen tekrar deneyin.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Görsel işleme hatası: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastErrorMessage = 'Görsel işlenemedi: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canScan = widget.isPremium || widget.remainingScans > 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fisi Yolla', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          const Text('Fiş görselini seç, yapay zeka fişteki gerçek tutarları okusun.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          if (!canScan) ...[
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                        child: const Icon(Icons.lock_clock_rounded, color: Colors.redAccent, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text('Bugunluk Hakkin Doldu!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 8),
                      Text(
                        widget.adBonusRemaining > 0
                            ? 'Gunde 2 bedava hakkin var. Reklam izleyip +1 hak alabilirsin ya da sinirsiz pakete gecebilirsin.'
                            : 'Bugünlük reklam hakların da bitti. Yarın tekrar gel ya da sınırsız pakete geç.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.adBonusRemaining > 0 ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: widget.adBonusRemaining > 0 ? widget.onWatchAd : null,
                          icon: const Icon(Icons.ondemand_video_rounded, color: Colors.white),
                          label: Text(
                            widget.adBonusRemaining > 0 ? 'Reklam Izle (+1 Hak Al)' : 'Bugünlük Reklam Hakkın Bitti',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: _isProcessing
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(color: Color(0xFF1E293B)),
                          SizedBox(height: 16),
                          Text('Fiş taranıyor ve yapay zeka inceliyor...', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Fişteki gerçek tutarlar çıkarılıyor...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage(ImageSource.camera),
                              child: Container(
                                width: double.infinity,
                                height: 170,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.camera_alt_rounded, size: 44, color: Color(0xFF1E293B)),
                                    SizedBox(height: 10),
                                    Text('Fisin Fotosunu Cek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(height: 4),
                                    Text('Kamerayi acip hemen tara', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: Container(
                                width: double.infinity,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.photo_library_rounded, size: 36, color: Color(0xFF64748B)),
                                    SizedBox(height: 8),
                                    Text('Galeriden Fis Sec',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.isPremium ? 'Sinirsiz Moddasin' : 'Kalan Hakkin: ${widget.remainingScans} / 2',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
                            ),
                            if (_lastErrorMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _lastErrorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final List<Receipt> receipts;
  final double monthlyIncome;

  const ReportsScreen({super.key, required this.receipts, required this.monthlyIncome});

  double _categoryTotal(ExpenseCategory cat) {
    double sum = 0;
    for (var r in receipts) {
      for (var item in r.items) {
        if (item.category == cat) sum += item.price;
      }
    }
    return sum;
  }

  double get _grandTotal => receipts.fold(0.0, (sum, r) => sum + r.totalAmount);

  @override
  Widget build(BuildContext context) {
    final Map<ExpenseCategory, double> totals = {};
    for (var c in ExpenseCategory.values) {
      final t = _categoryTotal(c);
      if (t > 0) totals[c] = t;
    }

    final double spentRatio = monthlyIncome > 0 ? (_grandTotal / monthlyIncome * 100) : 0;

    // Legend'i büyükten küçüğe sıralıyoruz ki en çok harcanan üstte olsun.
    final sortedEntries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Harcama Pastasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        const Text('Paran nereye gitti, gelirinin ne kadarini harcadin?', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Column(
            children: [
              if (_grandTotal == 0)
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const Text('Grafik icin en az bir fis yuklemelisin 📊', style: TextStyle(color: Colors.grey)),
                )
              else
                SizedBox(
                  height: 210,
                  width: 210,
                  child: CustomPaint(
                    painter: PieChartPainter(categoryTotals: totals, totalAmount: _grandTotal),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Toplam Masraf',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text('₺${_grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ...sortedEntries.map((entry) {
                final cat = entry.key;
                final amount = entry.value;
                final percent = _grandTotal > 0 ? (amount / _grandTotal * 100).toStringAsFixed(1) : '0';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: cat.iconColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(cat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Text('₺${amount.toStringAsFixed(2)} (%$percent)',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Maas / Gelir Durumu',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E))),
                    const SizedBox(height: 4),
                    Text(
                      _grandTotal == 0
                          ? 'Aylik net gelirin ₺${monthlyIncome.toStringAsFixed(0)}. Ilk fisini atinca maasinin ne kadarini harcadigini soyleyecegim.'
                          : 'Bu ay maasinin %${spentRatio.toStringAsFixed(1)} kismini harcamissin. Kalan: ₺${(monthlyIncome - _grandTotal).toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFFB45309), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalAmount;

  PieChartPainter({required this.categoryTotals, required this.totalAmount});

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 26.0;

    double startAngle = -pi / 2;

    for (var entry in categoryTotals.entries) {
      final sweepAngle = (entry.value / totalAmount) * 2 * pi;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = entry.key.iconColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SubscriptionScreen extends StatelessWidget {
  final bool isPremium;
  final int remainingScans;
  final int adBonusRemaining;
  final ValueChanged<bool> onTogglePremium;
  final VoidCallback onWatchAd;

  const SubscriptionScreen({
    super.key,
    required this.isPremium,
    required this.remainingScans,
    required this.adBonusRemaining,
    required this.onTogglePremium,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Paketler & Haklar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPremium
                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                  : [const Color(0xFF334155), const Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isPremium ? 'PREMIUM HESAP' : 'BEDAVA PLAN',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(isPremium ? Icons.verified : Icons.lock_outline, color: Colors.white),
                ],
              ),
              const SizedBox(height: 10),
              Text(isPremium ? 'Sinirsiz Fis At' : 'Gunde 2 Hakkin Var',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                isPremium
                    ? 'Istedigin kadar reklamsiz fis tarama hakki'
                    : 'Kalan hak: $remainingScans • Biterse reklam izleyip hak alirsin.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Icon(Icons.play_circle_filled, size: 36, color: adBonusRemaining > 0 ? const Color(0xFFF59E0B) : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reklam Izleyip ucretsiz tarama hakki',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      adBonusRemaining > 0
                          ? '30 saniye izle = +1 Fis Hakki (bugün $adBonusRemaining hakkın var)'
                          : 'Bugünlük reklam hakların bitti',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: adBonusRemaining > 0 ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: adBonusRemaining > 0 ? onWatchAd : null,
                child: const Text('Izle', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Paketini Sec', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isPremium ? const Color(0xFFF59E0B) : Colors.black12, width: isPremium ? 2 : 1),
          ),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isPremium,
                activeColor: const Color(0xFFF59E0B),
                onChanged: (val) {
                  if (val != null) onTogglePremium(val);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Sinirsiz Paket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Sinirsiz fis tara, reklam yok', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Text('₺9.99/ay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: !isPremium ? const Color(0xFF1E293B) : Colors.black12, width: !isPremium ? 2 : 1),
          ),
          child: Row(
            children: [
              Radio<bool>(
                value: false,
                groupValue: isPremium,
                activeColor: const Color(0xFF1E293B),
                onChanged: (val) {
                  if (val != null) onTogglePremium(val);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Bedava Mod', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Gunde 2 fis hakki yeter diyorsan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Text('0 TL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

//am