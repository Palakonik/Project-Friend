import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// Harici API'ler için servis sınıfı
class ExternalApiService {
  
  // ============== REST Countries API ==============
  // Ücretsiz, API key gerektirmez
  
  Future<List<Map<String, dynamic>>> getAllCountries() async {
    final response = await http.get(
      Uri.parse('https://restcountries.com/v3.1/all?fields=name,capital,population,flags,region,currencies,languages'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Ülkeler yüklenemedi');
  }
  
  Future<List<Map<String, dynamic>>> searchCountries(String query) async {
    if (query.isEmpty) return [];
    
    final response = await http.get(
      Uri.parse('https://restcountries.com/v3.1/name/$query?fields=name,capital,population,flags,region,currencies,languages'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============== CoinGecko API ==============
  // Ücretsiz, API key gerektirmez
  
  Future<List<Map<String, dynamic>>> getTopCryptos({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=$limit&page=1&sparkline=false'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Kripto veriler yüklenemedi');
  }

  // ============== ExchangeRate API ==============
  // Ücretsiz tier
  
  Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    final response = await http.get(
      Uri.parse('https://api.exchangerate-api.com/v4/latest/$baseCurrency'),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Döviz kurları yüklenemedi');
  }

  // ============== OpenWeatherMap API ==============
  // Demo veri (API key gerektirir, örnek veri gösteriyoruz)
  
  Map<String, dynamic> getDemoWeather(String city) {
    // Demo veri - gerçek API için API key gerekir
    final demoData = {
      'Istanbul': {'temp': 12, 'description': 'Parçalı bulutlu', 'humidity': 65, 'wind': 15},
      'Ankara': {'temp': 5, 'description': 'Açık', 'humidity': 45, 'wind': 10},
      'Izmir': {'temp': 16, 'description': 'Güneşli', 'humidity': 55, 'wind': 20},
      'Antalya': {'temp': 18, 'description': 'Güneşli', 'humidity': 60, 'wind': 12},
      'Bursa': {'temp': 8, 'description': 'Bulutlu', 'humidity': 70, 'wind': 8},
    };
    
    return demoData[city] ?? {'temp': 10, 'description': 'Bilinmiyor', 'humidity': 50, 'wind': 10};
  }

  // ============== NewsAPI ==============
  // Demo veri
  
  List<Map<String, dynamic>> getDemoNews() {
    return [
      {
        'title': 'Yapay Zeka Teknolojilerinde Yeni Gelişmeler',
        'description': 'Son dönemde yapay zeka alanında önemli ilerlemeler kaydedildi.',
        'source': 'Teknoloji Haberleri',
        'publishedAt': '2026-01-14',
      },
      {
        'title': 'Ekonomide Pozitif Sinyaller',
        'description': 'Merkez Bankası son ekonomik verileri değerlendirdi.',
        'source': 'Ekonomi Gazetesi',
        'publishedAt': '2026-01-14',
      },
      {
        'title': 'Spor Dünyasından Son Dakika',
        'description': 'Süper Lig\'de heyecan devam ediyor.',
        'source': 'Spor Ajansı',
        'publishedAt': '2026-01-14',
      },
      {
        'title': 'Bilim İnsanları Yeni Keşif Açıkladı',
        'description': 'Uzay araştırmalarında çığır açan bir keşif yapıldı.',
        'source': 'Bilim Merkezi',
        'publishedAt': '2026-01-13',
      },
      {
        'title': 'Sağlık Alanında Önemli Araştırma',
        'description': 'Yeni tedavi yöntemleri umut veriyor.',
        'source': 'Sağlık Dergisi',
        'publishedAt': '2026-01-13',
      },
    ];
  }

  // ============== Unsplash API ==============
  // Demo resimler
  
  List<Map<String, dynamic>> getDemoImages(String query) {
    // Picsum kullanarak demo resimler
    return List.generate(12, (index) {
      return <String, dynamic>{
        'id': 'img_$index',
        'url': 'https://picsum.photos/seed/${query}_$index/400/300',
        'thumb': 'https://picsum.photos/seed/${query}_$index/200/150',
        'author': 'Demo Fotoğrafçı ${index + 1}',
      };
    });
  }

  // ============== OpenAI API ==============
  // Demo yanıt
  
  String getDemoAIResponse(String prompt) {
    if (prompt.toLowerCase().contains('merhaba')) {
      return 'Merhaba! Size nasıl yardımcı olabilirim?';
    } else if (prompt.toLowerCase().contains('hava')) {
      return 'Bugün hava güzel görünüyor! Dışarı çıkmak için ideal bir gün.';
    } else if (prompt.toLowerCase().contains('flutter')) {
      return 'Flutter, Google tarafından geliştirilen açık kaynaklı bir UI toolkit\'tir. Tek kod tabanı ile iOS, Android, Web ve masaüstü uygulamaları geliştirebilirsiniz.';
    }
    return 'Bu bir demo yanıttır. Gerçek OpenAI API kullanımı için API anahtarı gereklidir.';
  }

  // ============== Mapbox API ==============
  // Statik harita URL'i
  
  String getStaticMapUrl(double lat, double lon, {int zoom = 12}) {
    // OpenStreetMap tile URL (ücretsiz)
    return 'https://tile.openstreetmap.org/$zoom/${_lon2tile(lon, zoom)}/${_lat2tile(lat, zoom)}.png';
  }
  
  int _lon2tile(double lon, int zoom) {
    return ((lon + 180) / 360 * (1 << zoom)).floor();
  }
  
  int _lat2tile(double lat, int zoom) {
    final latRad = lat * math.pi / 180;
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * (1 << zoom)).floor();
  }

  // ============== Hugging Face API ==============
  // Demo duygu analizi
  
  Map<String, dynamic> getDemoSentiment(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('güzel') || lowerText.contains('harika') || lowerText.contains('süper') || lowerText.contains('mutlu')) {
      return {'label': 'POSITIVE', 'score': 0.95, 'emoji': '😊'};
    } else if (lowerText.contains('kötü') || lowerText.contains('berbat') || lowerText.contains('üzgün') || lowerText.contains('sinirli')) {
      return {'label': 'NEGATIVE', 'score': 0.88, 'emoji': '😢'};
    }
    return {'label': 'NEUTRAL', 'score': 0.72, 'emoji': '😐'};
  }

  // ============== Finnhub API ==============
  // Demo hisse verileri
  
  List<Map<String, dynamic>> getDemoStocks() {
    return [
      {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 185.42, 'change': 2.35, 'changePercent': 1.28},
      {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'price': 141.80, 'change': -0.95, 'changePercent': -0.67},
      {'symbol': 'MSFT', 'name': 'Microsoft Corp.', 'price': 378.91, 'change': 4.12, 'changePercent': 1.10},
      {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'price': 178.25, 'change': 1.85, 'changePercent': 1.05},
      {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'price': 248.50, 'change': -3.20, 'changePercent': -1.27},
      {'symbol': 'META', 'name': 'Meta Platforms', 'price': 505.75, 'change': 8.45, 'changePercent': 1.70},
      {'symbol': 'NVDA', 'name': 'NVIDIA Corp.', 'price': 495.22, 'change': 12.50, 'changePercent': 2.59},
      {'symbol': 'NFLX', 'name': 'Netflix Inc.', 'price': 485.30, 'change': -2.10, 'changePercent': -0.43},
    ];
  }

  // ============== DeepAI API ==============
  // Demo görsel URL'leri
  
  String getDemoAIImage(String prompt) {
    // Picsum ile demo görsel
    final seed = prompt.hashCode.abs() % 1000;
    return 'https://picsum.photos/seed/$seed/512/512';
  }
}
