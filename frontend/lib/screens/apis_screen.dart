import 'package:flutter/material.dart';
import '../services/external_api_service.dart';

/// APIs Ana Ekranı - 11 harici API örneği
class ApisScreen extends StatefulWidget {
  const ApisScreen({super.key});

  @override
  State<ApisScreen> createState() => _ApisScreenState();
}

class _ApisScreenState extends State<ApisScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ExternalApiService _apiService = ExternalApiService();

  final List<_ApiTab> _tabs = [
    _ApiTab('Ülkeler', Icons.public, 'REST Countries'),
    _ApiTab('Kripto', Icons.currency_bitcoin, 'CoinGecko'),
    _ApiTab('Döviz', Icons.attach_money, 'ExchangeRate'),
    _ApiTab('Hava', Icons.wb_sunny, 'OpenWeatherMap'),
    _ApiTab('Haberler', Icons.newspaper, 'NewsAPI'),
    _ApiTab('Görseller', Icons.image, 'Unsplash'),
    _ApiTab('AI Metin', Icons.chat, 'OpenAI'),
    _ApiTab('Harita', Icons.map, 'Mapbox'),
    _ApiTab('NLP', Icons.psychology, 'Hugging Face'),
    _ApiTab('Hisse', Icons.trending_up, 'Finnhub'),
    _ApiTab('AI Görsel', Icons.auto_awesome, 'DeepAI'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Örnekleri'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((tab) => Tab(
            icon: Icon(tab.icon, size: 20),
            text: tab.name,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CountriesTab(apiService: _apiService),
          _CryptoTab(apiService: _apiService),
          _CurrencyTab(apiService: _apiService),
          _WeatherTab(apiService: _apiService),
          _NewsTab(apiService: _apiService),
          _ImagesTab(apiService: _apiService),
          _AITextTab(apiService: _apiService),
          _MapTab(apiService: _apiService),
          _NLPTab(apiService: _apiService),
          _StocksTab(apiService: _apiService),
          _AIImageTab(apiService: _apiService),
        ],
      ),
    );
  }
}

class _ApiTab {
  final String name;
  final IconData icon;
  final String apiName;
  
  _ApiTab(this.name, this.icon, this.apiName);
}

// ============== 1. REST Countries Tab ==============
class _CountriesTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _CountriesTab({required this.apiService});

  @override
  State<_CountriesTab> createState() => _CountriesTabState();
}

class _CountriesTabState extends State<_CountriesTab> {
  List<Map<String, dynamic>> _countries = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoading = true);
    try {
      _countries = await widget.apiService.getAllCountries();
      _countries.sort((a, b) => 
        (a['name']['common'] as String).compareTo(b['name']['common'] as String));
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadCountries();
      return;
    }
    setState(() => _isLoading = true);
    try {
      _countries = await widget.apiService.searchCountries(query);
    } catch (e) {
      _countries = [];
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ülke ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final name = country['name']['common'] ?? 'Bilinmiyor';
                    final capital = (country['capital'] as List?)?.firstOrNull ?? 'Bilinmiyor';
                    final population = country['population'] ?? 0;
                    final flag = country['flags']?['png'] ?? '';
                    final region = country['region'] ?? '';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: flag.isNotEmpty
                            ? Image.network(flag, width: 48, height: 32, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.flag))
                            : const Icon(Icons.flag),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Başkent: $capital\nBölge: $region'),
                        trailing: Text(_formatNumber(population), style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) return '${(number / 1000000000).toStringAsFixed(1)}B';
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

// ============== 2. CoinGecko Crypto Tab ==============
class _CryptoTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _CryptoTab({required this.apiService});

  @override
  State<_CryptoTab> createState() => _CryptoTabState();
}

class _CryptoTabState extends State<_CryptoTab> {
  List<Map<String, dynamic>> _cryptos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCryptos();
  }

  Future<void> _loadCryptos() async {
    setState(() => _isLoading = true);
    try {
      _cryptos = await widget.apiService.getTopCryptos();
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCryptos,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cryptos.length,
              itemBuilder: (context, index) {
                final crypto = _cryptos[index];
                final name = crypto['name'] ?? '';
                final symbol = (crypto['symbol'] ?? '').toString().toUpperCase();
                final price = crypto['current_price'] ?? 0.0;
                final change = crypto['price_change_percentage_24h'] ?? 0.0;
                final image = crypto['image'] ?? '';
                final marketCap = crypto['market_cap'] ?? 0;
                
                final isPositive = change >= 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                      child: image.isEmpty ? Text(symbol[0]) : null,
                    ),
                    title: Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(symbol, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    subtitle: Text('Market Cap: \$${_formatNumber(marketCap)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${price.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 14, color: isPositive ? Colors.green : Colors.red),
                            Text('${change.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontSize: 12,
                              )),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) return '${(number / 1000000000).toStringAsFixed(1)}B';
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    return number.toString();
  }
}

// ============== 3. ExchangeRate Currency Tab ==============
class _CurrencyTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _CurrencyTab({required this.apiService});

  @override
  State<_CurrencyTab> createState() => _CurrencyTabState();
}

class _CurrencyTabState extends State<_CurrencyTab> {
  Map<String, dynamic>? _rates;
  bool _isLoading = true;
  String _baseCurrency = 'USD';
  final _amountController = TextEditingController(text: '100');
  
  final List<String> _currencies = ['USD', 'EUR', 'TRY', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD'];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoading = true);
    try {
      _rates = await widget.apiService.getExchangeRates(_baseCurrency);
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Miktar',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _baseCurrency,
                        items: _currencies.map((c) => DropdownMenuItem(
                          value: c, child: Text(c),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _baseCurrency = value;
                            _loadRates();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_rates != null)
            ..._currencies.where((c) => c != _baseCurrency).map((currency) {
              final rate = (_rates!['rates']?[currency] ?? 0.0) as num;
              final amount = double.tryParse(_amountController.text) ?? 0;
              final converted = amount * rate;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
                    child: Text(currency.substring(0, 2), 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(currency, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('1 $_baseCurrency = ${rate.toStringAsFixed(4)} $currency'),
                  trailing: Text(
                    converted.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ============== 4. OpenWeatherMap Tab ==============
class _WeatherTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _WeatherTab({required this.apiService});

  @override
  State<_WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<_WeatherTab> {
  String _selectedCity = 'Istanbul';
  final List<String> _cities = ['Istanbul', 'Ankara', 'Izmir', 'Antalya', 'Bursa'];

  @override
  Widget build(BuildContext context) {
    final weather = widget.apiService.getDemoWeather(_selectedCity);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoBanner(context, 'OpenWeatherMap API - Demo Veri'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: _selectedCity,
                    isExpanded: true,
                    items: _cities.map((c) => DropdownMenuItem(
                      value: c, child: Text(c),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedCity = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.wb_sunny, size: 80, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(_selectedCity, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${weather['temp']}°C', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
                  Text('${weather['description']}', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildWeatherInfo(Icons.water_drop, 'Nem', '${weather['humidity']}%'),
                      _buildWeatherInfo(Icons.air, 'Rüzgar', '${weather['wind']} km/h'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ============== 5. NewsAPI Tab ==============
class _NewsTab extends StatelessWidget {
  final ExternalApiService apiService;
  const _NewsTab({required this.apiService});

  @override
  Widget build(BuildContext context) {
    final news = apiService.getDemoNews();
    
    return Column(
      children: [
        _buildInfoBanner(context, 'NewsAPI - Demo Haberler'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: news.length,
            itemBuilder: (context, index) {
              final article = news[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article['title'], 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(article['description'], style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(article['source'], 
                            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                          Text(article['publishedAt'], style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============== 6. Unsplash Images Tab ==============
class _ImagesTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _ImagesTab({required this.apiService});

  @override
  State<_ImagesTab> createState() => _ImagesTabState();
}

class _ImagesTabState extends State<_ImagesTab> {
  final _searchController = TextEditingController(text: 'nature');
  List<Map<String, dynamic>> _images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void _loadImages() {
    setState(() {
      _images = widget.apiService.getDemoImages(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInfoBanner(context, 'Unsplash API - Demo (Picsum)'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Görsel ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadImages,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _loadImages(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image['url'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============== 7. OpenAI Text Tab ==============
class _AITextTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _AITextTab({required this.apiService});

  @override
  State<_AITextTab> createState() => _AITextTabState();
}

class _AITextTabState extends State<_AITextTab> {
  final _promptController = TextEditingController();
  String _response = '';

  void _generate() {
    if (_promptController.text.isEmpty) return;
    setState(() {
      _response = widget.apiService.getDemoAIResponse(_promptController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(context, 'OpenAI API - Demo Yanıt'),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Bir soru sorun... (örn: "Merhaba", "Flutter nedir?")',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          if (_response.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.smart_toy, color: Color(0xFF667eea)),
                        const SizedBox(width: 8),
                        const Text('AI Yanıtı', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Text(_response, style: const TextStyle(fontSize: 16)),
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

// ============== 8. Mapbox Tab ==============
class _MapTab extends StatelessWidget {
  final ExternalApiService apiService;
  const _MapTab({required this.apiService});

  @override
  Widget build(BuildContext context) {
    final locations = [
      {'name': 'İstanbul', 'lat': 41.0082, 'lon': 28.9784},
      {'name': 'Ankara', 'lat': 39.9334, 'lon': 32.8597},
      {'name': 'İzmir', 'lat': 38.4192, 'lon': 27.1287},
    ];

    return Column(
      children: [
        _buildInfoBanner(context, 'Mapbox API - OpenStreetMap Tiles'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(loc['name'] as String, 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${loc['lat']}, ${loc['lon']}'),
                    ),
                    Container(
                      height: 150,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://tile.openstreetmap.org/10/${_lon2tile((loc['lon'] as num).toDouble(), 10)}/${_lat2tile((loc['lat'] as num).toDouble(), 10)}.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  int _lon2tile(double lon, int zoom) => ((lon + 180) / 360 * (1 << zoom)).floor();
  int _lat2tile(double lat, int zoom) {
    final latRad = lat * 3.141592653589793 / 180;
    return ((1 - (latRad.abs() < 1.5 ? latRad + latRad*latRad*latRad/6 : latRad) / 3.141592653589793) / 2 * (1 << zoom)).floor();
  }
}

// ============== 9. Hugging Face NLP Tab ==============
class _NLPTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _NLPTab({required this.apiService});

  @override
  State<_NLPTab> createState() => _NLPTabState();
}

class _NLPTabState extends State<_NLPTab> {
  final _textController = TextEditingController();
  Map<String, dynamic>? _result;

  void _analyze() {
    if (_textController.text.isEmpty) return;
    setState(() {
      _result = widget.apiService.getDemoSentiment(_textController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(context, 'Hugging Face - Demo Duygu Analizi'),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Analiz edilecek metni girin...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.psychology),
            label: const Text('Analiz Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(_result!['emoji'], style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(_result!['label'], 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _result!['score'],
                      backgroundColor: Colors.grey[200],
                      color: _result!['label'] == 'POSITIVE' 
                          ? Colors.green 
                          : _result!['label'] == 'NEGATIVE' ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text('Güven: ${(_result!['score'] * 100).toStringAsFixed(0)}%'),
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

// ============== 10. Finnhub Stocks Tab ==============
class _StocksTab extends StatelessWidget {
  final ExternalApiService apiService;
  const _StocksTab({required this.apiService});

  @override
  Widget build(BuildContext context) {
    final stocks = apiService.getDemoStocks();
    
    return Column(
      children: [
        _buildInfoBanner(context, 'Finnhub API - Demo Hisse Verileri'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index];
              final isPositive = stock['change'] >= 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPositive ? Colors.green[50] : Colors.red[50],
                    child: Text(stock['symbol'].substring(0, 2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      )),
                  ),
                  title: Text(stock['symbol'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(stock['name']),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${stock['price'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12, color: isPositive ? Colors.green : Colors.red),
                          Text('${stock['changePercent'].toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: isPositive ? Colors.green : Colors.red,
                            )),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============== 11. DeepAI Image Tab ==============
class _AIImageTab extends StatefulWidget {
  final ExternalApiService apiService;
  const _AIImageTab({required this.apiService});

  @override
  State<_AIImageTab> createState() => _AIImageTabState();
}

class _AIImageTabState extends State<_AIImageTab> {
  final _promptController = TextEditingController();
  String? _imageUrl;

  void _generate() {
    if (_promptController.text.isEmpty) return;
    setState(() {
      _imageUrl = widget.apiService.getDemoAIImage(_promptController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(context, 'DeepAI - Demo (Picsum)'),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText: 'Görsel açıklaması girin...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Görsel Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          if (_imageUrl != null) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _imageUrl!,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============== Helper Widgets ==============
Widget _buildInfoBanner(BuildContext context, String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Colors.amber[50],
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.amber[900], fontSize: 12)),
        ),
      ],
    ),
  );
}
