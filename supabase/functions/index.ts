// supabase/functions/analyze-receipt/index.ts
//
// Bu fonksiyon Gemini API'yi SUNUCU tarafında çağırır. GEMINI_API_KEY hiçbir
// zaman client'a (Flutter uygulamasına) gönderilmez — sadece Supabase'in
// "secrets" deposunda tutulur. Client sadece görselin base64'ünü gönderir,
// buradan temiz bir { storeName, items } JSON'u alır.
//
// Varsayılan olarak Supabase Edge Function'lar geçerli bir kullanıcı JWT'si
// olmadan çağrılamaz (verify_jwt açık) — yani sadece giriş yapmış kullanıcılar
// bu fonksiyonu tetikleyebilir, ekstra bir yetkilendirme kodu yazmamıza gerek
// yok.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Flutter tarafındaki ExpenseCategory enum'uyla birebir aynı tutulmalı.
const CATEGORY_KEYS = [
  "gida",
  "hijyen",
  "kozmetik",
  "saglik",
  "elektronik",
  "giyim",
  "ulasim",
  "eglence",
  "fatura",
  "evesya",
  "diger",
];

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (!GEMINI_API_KEY) {
    return jsonResponse(
      { error: "Sunucuda GEMINI_API_KEY tanımlı değil. 'supabase secrets set GEMINI_API_KEY=...' çalıştırın." },
      500,
    );
  }

  let image: string | undefined;
  let mimeType: string | undefined;

  try {
    const body = await req.json();
    image = body.image;
    mimeType = body.mimeType ?? "image/jpeg";
  } catch {
    return jsonResponse({ error: "Geçersiz istek gövdesi (JSON bekleniyor)." }, 400);
  }

  if (!image) {
    return jsonResponse({ error: "'image' alanı (base64) gerekli." }, 400);
  }

  const prompt = `Sen bir fiş OCR ve analiz uzmanısın. Bu alışveriş fişi görselini SATIR SATIR dikkatlice oku.
Kurallar:
1. SADECE fişte fiziksel olarak yazılı olan ürün adlarını ve fiyatları çıkar. Asla tahmin etme, asla ortalama veya rastgele bir değer üretme.
2. Bir fiyatı net okuyamıyorsan o ürünü listeye EKLEME.
3. Fiyatlar fişte yazan TUTAR (KDV dahil, birim fiyat değil, toplam satır tutarı) olmalı.
4. Ondalık ayraç olarak nokta kullan (örn: 45.90), virgülü noktaya çevir.
5. Kategori kesinlikle şu değerlerden biri olmalı: ${CATEGORY_KEYS.map((k) => `'${k}'`).join(", ")}.
   Kategori seçerken ürünün ne olduğuna bak: ilaç/vitamin/medikal -> saglik, telefon/kablo/pil/bilgisayar -> elektronik,
   tisort/pantolon/ayakkabi -> giyim, benzin/otobus/taksi/metro -> ulasim, sinema/oyun/kitap/kafe -> eglence,
   su/elektrik/dogalgaz/internet faturasi -> fatura, tencere/havlu/mobilya -> evesya.
6. Görsel bulanık/okunaksızsa veya bir fiş değilse, items alanını boş dizi [] olarak döndür.
SADECE ve SADECE şu JSON formatında yanıt ver, başka hiçbir açıklama, markdown veya metin ekleme:
{
  "storeName": "Market Adı",
  "items": [
    { "name": "Ürün adı", "price": 0.00, "category": "gida" }
  ]
}`;

  try {
    const geminiUrl =
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              { inline_data: { mime_type: mimeType, data: image } },
            ],
          },
        ],
        generationConfig: {
          thinkingConfig: { thinkingLevel: "low" },
          maxOutputTokens: 4096,
          responseMimeType: "application/json",
        },
      }),
    });

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      let reason = errText;
      try {
        reason = JSON.parse(errText)?.error?.message ?? errText;
      } catch {
        // düz metin olarak bırak
      }
      return jsonResponse({ error: `Gemini API hatası: ${reason}` }, 502);
    }

    const data = await geminiRes.json();
    const candidates = data.candidates;

    if (!candidates || candidates.length === 0) {
      return jsonResponse(
        { error: `Model bir yanıt üretemedi. ${data.promptFeedback ? "Sebep: " + JSON.stringify(data.promptFeedback) : "Lütfen daha net bir fotoğraf deneyin."}` },
        502,
      );
    }

    const textContent = candidates[0]?.content?.parts?.[0]?.text;
    if (!textContent) {
      return jsonResponse({ error: "Model metin içeriği döndürmedi." }, 502);
    }

    const cleanJson = textContent.replace(/```json/g, "").replace(/```/g, "").trim();

    let parsed: { storeName?: string; items?: unknown[] };
    try {
      parsed = JSON.parse(cleanJson);
    } catch {
      return jsonResponse({ error: "Model yanıtı JSON formatında değildi, tekrar deneyin." }, 502);
    }

    const rawItems = Array.isArray(parsed.items) ? parsed.items : [];
    const items = rawItems
      .map((it) => {
        const rec = it as Record<string, unknown>;
        const category = typeof rec.category === "string" ? rec.category.toLowerCase() : "diger";
        return {
          name: typeof rec.name === "string" ? rec.name : "Ürün",
          price: Number(rec.price) || 0,
          category: CATEGORY_KEYS.includes(category) ? category : "diger",
        };
      })
      .filter((it) => it.price > 0);

    if (items.length === 0) {
      return jsonResponse({ error: "Fişteki ürünler net okunamadı. Daha aydınlık/net bir fotoğraf deneyin." }, 200);
    }

    return jsonResponse({
      storeName: typeof parsed.storeName === "string" ? parsed.storeName : "Market",
      items,
    });
  } catch (e) {
    return jsonResponse({ error: `Beklenmeyen sunucu hatası: ${e}` }, 500);
  }
});