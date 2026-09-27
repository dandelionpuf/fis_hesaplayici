import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  const AccountScreen({
    super.key,
    this.isDarkMode = true,
    this.onThemeChanged,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late bool _darkMode;
  bool _pushNotifications = true;
  bool _autoScanReceipts = true;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
  }

  // Supabase uzerinden aktif kullanici e-postasini alma
  String get _userEmail {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user?.email ?? 'kullanici@email.com';
    } catch (_) {
      return 'kullanici@email.com';
    }
  }

  // Supabase ile oturum kapatma
  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cikis yapilamadi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _darkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = _darkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _darkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = _darkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = _darkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hesabim',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profil Bilgi Karti
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kullanici Hesabi',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Abonelik Durumu Karti
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mevcut Abonelik',
                        style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Aktif',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pro Plan - Sinirsiz Fis Tarama',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sonraki Fatura: 14 Ekim (TL 9.99/ay)',
                    style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4F46E5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () {
                      // Abonelik yonetimi
                    },
                    child: const Text(
                      'Plani Yonet / Degistir',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Genel Tercihler / Ayarlar
            Text(
              'Uygulama Tercihleri',
              style: TextStyle(
                color: subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xFF6366F1),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: const Color(0xFF818CF8),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Koyu Mod (Dark Theme)',
                      style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _darkMode ? 'Koyu tema aktif' : 'Acik tema aktif',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    value: _darkMode,
                    onChanged: (val) {
                      setState(() => _darkMode = val);
                      if (widget.onThemeChanged != null) {
                        widget.onThemeChanged!(val);
                      }
                    },
                  ),
                  Divider(color: borderColor, height: 1),
                  SwitchListTile(
                    activeColor: const Color(0xFF10B981),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF34D399), size: 22),
                    ),
                    title: Text(
                      'Otomatik Fis Analizi',
                      style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Cekilen fisler analiz edilsin',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    value: _autoScanReceipts,
                    onChanged: (val) => setState(() => _autoScanReceipts = val),
                  ),
                  Divider(color: borderColor, height: 1),
                  SwitchListTile(
                    activeColor: const Color(0xFFF97316),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFB923C), size: 22),
                    ),
                    title: Text(
                      'Harcama Uyarilari',
                      style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Aylik limit asiminda bildirim gonder',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Cikis Yap
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                label: const Text(
                  'Hesaptan Cikis Yap',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _handleSignOut,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}