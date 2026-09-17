Nereye Gitti 💸Nereye Gitti, kullanıcıların fiziksel harcama ve market fişlerini kamera ile taratarak yapay zeka desteğiyle saniyeler içinde dijital harcama kayıtlarına dönüştürmesini sağlayan modern bir kişisel finans yönetim uygulamasıdır.
🚀 Özellikler
AI Destekli Fiş Tarama: Gemini 2.5 Flash modeli sayesinde fişteki mağaza adı, ürün kalemleri, tutarlar ve kategoriler görselden otomatik olarak ayrıştırılır.Akıllı Kategorilendirme: Yapay zeka taranan her ürünü uygun harcama kategorisine (market, yemek, fatura vb.) otomatik atar.Güvenli Backend Mimarisi: API anahtarları istemci tarafında tutulmaz; tüm analiz işlemleri Supabase Edge Functions üzerinde güvenli bir şekilde yürütülür.Finansal Takip & Raporlama: Harcamaları listeleme, toplam bütçe takibi ve kategori bazlı analiz.Monetizasyon: Google AdMob (Banner ve Geçiş Reklamları) entegrasyonu.
🛠️ Kullanılan TeknolojilerKatmanTeknolojiAçıklamaFrontendFlutter / DartÇapraz platform mobil arayüzYapay ZekaGoogle Gemini API (Gemini 2.5 Flash)Görselden veri ve JSON formatında ürün çıkarmaBackend & AuthSupabaseKimlik doğrulama, PostgreSQL veritabanıServerlessSupabase Edge Functions (Deno / TypeScript)Gemini API isteklerini proxy'leyen güvenli katmanReklamGoogle Mobile Ads SDKGelir modeli entegrasyonu🏗️ Sistem MimarisiPlaintext[Flutter Uygulaması]
        │
        ▼ (Fiş Görseli - Base64)
[Supabase Edge Function: analyze-receipt]
        │
        ▼ (Prompt + Görsel)
[Google Gemini API]
        │
        ▼ (Yapılandırılmış JSON Yanıtı)
[Supabase Database & Flutter State]
⚙️ Kurulum ve Yerel GeliştirmeGereksinimlerFlutter SDK (3.x veya üzeri)JDK 17Supabase hesabı & CLIGemini API anahtarıAdımlarRepoyu Klonlayın:Bashgit clone https://github.com/kullanici-adi/nereye-gitti.git
cd nereye-gitti
Bağımlılıkları Yükleyin:Bashflutter pub get
Supabase Edge Function Konfigürasyonu:Supabase CLI üzerinden Gemini API anahtarınızı tanımlayın:Bashsupabase secrets set GEMINI_API_KEY="SIZIN_GEMINI_API_KEYINIZ"
supabase functions deploy analyze-receipt --no-verify-jwt
Uygulamayı Çalıştırın:Bashflutter run
📦 Derleme (Build)Uygulamanın optimize edilmiş Android yayın sürümünü derlemek için:Bashflutter build apk --release
Çıktı konumu: build/app/outputs/flutter-apk/app-release.apk