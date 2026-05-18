class AppConstants {
  // Firestore collection names
  static const String kColRestaurants = 'restaurants';
  static const String kColReviews = 'reviews';
  static const String kColUsers = 'users';
  static const String kColChats = 'chats';
  static const String kColMessages = 'messages';
  static const String kColTrips = 'trips';
  static const String kColUserTrips = 'userTrips';
  static const String kColDays = 'days';
  static const String kColSpots = 'spots';
  static const String kColSavedPlaces = 'savedPlaces';
  static const String kColTranslations = 'translations';
  static const String kDocSummary = 'summary';
  static const String kDocPreferences = 'preferences';

  // Free tier limits
  static const int kMaxSavedFree = 10;
  static const int kMaxTranslationsPerDayFree = 5;
  static const int kMaxChatSendPerDayFree = 3;
  static const int kMaxAiRecsResultsFree = 5;

  // AI / summarizer
  static const int kSummaryMinReviews = 5;
  static const int kSummaryTriggerNewReviews = 10;
  static const int kSummaryBatchSize = 50;
  static const int kSummaryTtlDays = 7;

  // Geofence
  static const double kGeofenceRadiusMeters = 500;

  // Groq API
  static const String kGroqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String kGroqModel = 'llama3-8b-8192';
}

const kSupportedCountries = <Map<String, String>>[
  {'id': 'france',         'name': 'France',         'code': 'FR'},
  {'id': 'spain',          'name': 'Spain',           'code': 'ES'},
  {'id': 'united_states',  'name': 'United States',   'code': 'US'},
  {'id': 'china',          'name': 'China',            'code': 'CN'},
  {'id': 'italy',          'name': 'Italy',            'code': 'IT'},
  {'id': 'turkey',         'name': 'Turkey',           'code': 'TR'},
  {'id': 'mexico',         'name': 'Mexico',           'code': 'MX'},
  {'id': 'thailand',       'name': 'Thailand',         'code': 'TH'},
  {'id': 'germany',        'name': 'Germany',          'code': 'DE'},
  {'id': 'united_kingdom', 'name': 'United Kingdom',   'code': 'GB'},
  {'id': 'japan',          'name': 'Japan',            'code': 'JP'},
  {'id': 'greece',         'name': 'Greece',           'code': 'GR'},
  {'id': 'austria',        'name': 'Austria',          'code': 'AT'},
  {'id': 'egypt',          'name': 'Egypt',            'code': 'EG'},
  {'id': 'malaysia',       'name': 'Malaysia',         'code': 'MY'},
];

const kCountryCities = <String, List<String>>{
  'france':         ['Paris', 'Lyon', 'Marseille', 'Nice', 'Bordeaux', 'Toulouse', 'Strasbourg', 'Nantes'],
  'spain':          ['Madrid', 'Barcelona', 'Seville', 'Valencia', 'Bilbao', 'Granada', 'Malaga', 'Zaragoza'],
  'united_states':  ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami', 'San Francisco', 'Las Vegas', 'New Orleans'],
  'china':          ['Beijing', 'Shanghai', 'Guangzhou', 'Chengdu', "Xi'an", 'Hangzhou', 'Shenzhen', 'Chongqing'],
  'italy':          ['Rome', 'Milan', 'Florence', 'Venice', 'Naples', 'Bologna', 'Turin', 'Palermo'],
  'turkey':         ['Istanbul', 'Ankara', 'Izmir', 'Antalya', 'Bursa', 'Gaziantep', 'Konya', 'Cappadocia'],
  'mexico':         ['Mexico City', 'Guadalajara', 'Monterrey', 'Oaxaca', 'Cancun', 'Puebla', 'Merida', 'Tulum'],
  'thailand':       ['Bangkok', 'Chiang Mai', 'Phuket', 'Pattaya', 'Hua Hin', 'Krabi', 'Koh Samui', 'Ayutthaya'],
  'germany':        ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Cologne', 'Stuttgart', 'Dresden', 'Düsseldorf'],
  'united_kingdom': ['London', 'Edinburgh', 'Manchester', 'Birmingham', 'Bristol', 'Glasgow', 'Liverpool', 'Bath'],
  'japan':          ['Tokyo', 'Osaka', 'Kyoto', 'Hiroshima', 'Sapporo', 'Fukuoka', 'Nara', 'Kobe'],
  'greece':         ['Athens', 'Thessaloniki', 'Santorini', 'Mykonos', 'Rhodes', 'Heraklion', 'Corfu', 'Nafplio'],
  'austria':        ['Vienna', 'Salzburg', 'Innsbruck', 'Graz', 'Linz', 'Hallstatt', 'Bregenz', 'Klagenfurt'],
  'egypt':          ['Cairo', 'Alexandria', 'Luxor', 'Aswan', 'Hurghada', 'Sharm El Sheikh', 'Dahab', 'El Gouna'],
  'malaysia':       ['Kuala Lumpur', 'Penang', 'Johor Bahru', 'Kota Kinabalu', 'Kuching', 'Malacca', 'Langkawi', 'Ipoh'],
};

// Display-only stubs — city slug → restaurant name list
const kEditorPicks = <String, List<String>>{
  'tokyo':   ['Sushi Saito', 'Den', 'Narisawa'],
  'paris':   ['Le Bernardin Paris', 'Septime', 'Frenchie'],
  'rome':    ["La Pergola", 'Dal Bolognese', 'Roscioli'],
  'bangkok': ['Nahm', 'Bo.lan', 'Gaggan Anand'],
};
