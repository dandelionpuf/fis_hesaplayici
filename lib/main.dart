import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const FisHesaplayiciApp());
}

class FisHesaplayiciApp extends StatelessWidget {
  const FisHesaplayiciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fis Takip',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const MobileFrame(child: MainShellScreen()),
    );
  }
}

// masaustunde telefon gibi gosteren sekil
class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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

// kategoriler
enum ExpenseCategory {
  gida('Temel Gida', Icons.restaurant_rounded, Color(0xFFE0F2FE), Color(0xFF0284C7)),
  hijyen('Hijyen', Icons.clean_hands_rounded, Color(0xFFDCFCE7), Color(0xFF16A34A)),
  kozmetik('Kozmetik', Icons.spa_rounded, Color(0xFFFCE7F3), Color(0xFFDB2777)),
  diger('Diger', Icons.shopping_bag_rounded, Color(0xFFF3E8FF), Color(0xFF9333EA));

  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const ExpenseCategory(this.title, this.icon, this.bgColor, this.iconColor);
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

//ana ekran yonetimi
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  int _remainingDailyScans = 2;
  bool _isPremium = false;
  double _monthlyIncome = 25000.0; // varsayilan aylik gelir
  final List<Receipt> _receipts = []; // baslangicta sifir fis

  void _updateIncome(double newIncome) {
    setState(() {
      _monthlyIncome = newIncome;
    });
  }

  void _watchRewardAd() {
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kaptin +1 hakki! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _togglePremium(bool value) {
    setState(() {
      _isPremium = value;
    });
  }

  void _addNewReceipt(Receipt r) {
    setState(() {
      _receipts.insert(0, r);
      if (!_isPremium && _remainingDailyScans > 0) {
        _remainingDailyScans--;
      }
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        receipts: _receipts,
        remainingScans: _remainingDailyScans,
        isPremium: _isPremium,
        monthlyIncome: _monthlyIncome,
        onUpdateIncome: _updateIncome,
        onWatchAd: _watchRewardAd,
      ),
      ScanReceiptScreen(
        remainingScans: _remainingDailyScans,
        isPremium: _isPremium,
        onAddReceipt: _addNewReceipt,
        onWatchAd: _watchRewardAd,
      ),
      ReportsScreen(
        receipts: _receipts,
        monthlyIncome: _monthlyIncome,
      ),
      SubscriptionScreen(
        isPremium: _isPremium,
        remainingScans: _remainingDailyScans,
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
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Harcamalar'),
            BottomNavigationBarItem(icon: Icon(Icons.document_scanner_outlined), activeIcon: Icon(Icons.document_scanner), label: 'Fis At'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Pasta Grafik'),
            BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_outlined), activeIcon: Icon(Icons.workspace_premium), label: 'Abonelik'),
          ],
        ),
      ),
    );
  }
}

// 1.harcamalar ve dashboard
class DashboardScreen extends StatelessWidget {
  final List<Receipt> receipts;
  final int remainingScans;
  final bool isPremium;
  final double monthlyIncome;
  final ValueChanged<double> onUpdateIncome;
  final VoidCallback onWatchAd;

  const DashboardScreen({
    super.key,
    required this.receipts,
    required this.remainingScans,
    required this.isPremium,
    required this.monthlyIncome,
    required this.onUpdateIncome,
    required this.onWatchAd,
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

  void _showEditIncomeDialog(BuildContext context) {
    final controller = TextEditingController(text: monthlyIncome.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aylik Net Gelir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Orn: 30000',
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
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                onUpdateIncome(val);
              }
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPremium ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPremium ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                ),
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
          ],
        ),

        // Hak bitince cikan reklam bari
        if (!isPremium && remainingScans == 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.ondemand_video_rounded, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Gunluk hakkin bitti!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E))),
                      Text('Kisa bi reklam izle, aninda +1 hak kap.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onWatchAd,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Izle (+1)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // aylik net gelir ve kalan para
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
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
                    onTap: () => _showEditIncomeDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                  Text(
                    '₺${monthlyIncome.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                  ),
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

        // toplam harcama karti
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
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cebimizden Cikan (Toplam Harcama)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                '₺${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${receipts.length} Fis Islendi',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('Kategori Masraflari', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: ExpenseCategory.values.map((cat) {
            final total = _categoryTotal(cat);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
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
                      Text(cat.title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('₺${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                Icon(Icons.receipt_long_outlined, size: 42, color: Colors.grey),
                SizedBox(height: 10),
                Text('Henuz taranmis bir fis yok', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                SizedBox(height: 4),
                Text('Alttaki "Fis At" butonundan ilk fisini yukleyebilirsin ', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
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
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                  ],
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
                          Text(r.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text('${r.items.length} parca • ${r.date.day}.${r.date.month}.${r.date.year}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₺${r.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  ],
                ),
              )),
      ],
    );
  }
}

//2. fis tarama ve yukleme
class ScanReceiptScreen extends StatefulWidget {
  final int remainingScans;
  final bool isPremium;
  final Function(Receipt) onAddReceipt;
  final VoidCallback onWatchAd;

  const ScanReceiptScreen({
    super.key,
    required this.remainingScans,
    required this.isPremium,
    required this.onAddReceipt,
    required this.onWatchAd,
  });

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  Uint8List? _selectedImage;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _isProcessing = true;
        });

        // backend cevabi simülasyonu
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        setState(() => _isProcessing = false);

        final simulatedReceipt = Receipt(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          storeName: 'CarrefourSA',
          date: DateTime.now(),
          receiptImage: _selectedImage,
          items: [
            ReceiptItem(name: 'Tam Yagli Peynir', price: 115.00, category: ExpenseCategory.gida),
            ReceiptItem(name: 'Kagit Havlu', price: 84.50, category: ExpenseCategory.hijyen),
            ReceiptItem(name: 'El Sabunu', price: 29.90, category: ExpenseCategory.kozmetik),
          ],
        );

        widget.onAddReceipt(simulatedReceipt);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fis okundu, gruplara ayrildi! ')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
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
          const Text('Fisi at, urunleri gida, hijyen, kozmetik diye ayiralim.', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                      const Text(
                        'Bugunluk Hakkin Doldu!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gunde 2 tane bedava hakkin var. Reklam izleyip hemen +1 hak alabilirsin ya da sinirsiz pakete gecebilirsin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: widget.onWatchAd,
                          icon: const Icon(Icons.ondemand_video_rounded, color: Colors.white),
                          label: const Text('Reklam Izle (+1 Hak Al)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'veya Abonelikten sinirsiza gecin',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
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
                          Text('Fisi ayikliyoruz, lutfen bekleyin', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Gida, hijyen, kozmetik gruplaniyor', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : Column(
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
                                  Text('Galeriden Fis Sec', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.isPremium ? ' Sinirsiz Moddasin' : 'Kalan Hakkin: ${widget.remainingScans} / 2',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//3.pasta grafik ve raporlar
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
      totals[c] = _categoryTotal(c);
    }

    final double spentRatio = monthlyIncome > 0 ? (_grandTotal / monthlyIncome * 100) : 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Harcama Pastasi ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                    painter: PieChartPainter(
                      categoryTotals: totals,
                      totalAmount: _grandTotal,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Toplam Masraf', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            '₺${_grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              ...ExpenseCategory.values.map((cat) {
                final amount = totals[cat] ?? 0.0;
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
                      Text(cat.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('₺${amount.toStringAsFixed(2)} (%$percent)', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Gelir - Harcama Karsilastirma Notu
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Maas / Gelir Durumu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E))),
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

// 4.abonelik sistemi
class SubscriptionScreen extends StatelessWidget {
  final bool isPremium;
  final int remainingScans;
  final ValueChanged<bool> onTogglePremium;
  final VoidCallback onWatchAd;

  const SubscriptionScreen({
    super.key,
    required this.isPremium,
    required this.remainingScans,
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
              colors: isPremium ? [const Color(0xFFF59E0B), const Color(0xFFD97706)] : [const Color(0xFF334155), const Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isPremium ? 'PREMIUM HESAP' : 'BEDAVA PLAN', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(isPremium ? Icons.verified : Icons.lock_outline, color: Colors.white),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isPremium ? 'Sinirsiz Fis At' : 'Gunde 2 Hakkin Var',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                isPremium ? 'Istedigin kadar reklamsiz fis tarama hakki' : 'Kalan hak: $remainingScans • Biterse reklam izleyip hak alirsin.',
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
              const Icon(Icons.play_circle_filled, size: 36, color: Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Reklam Izleyip ucretsiz bir tarama hakki ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('30 saniye izle = +1 Fis Hakki', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onWatchAd,
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