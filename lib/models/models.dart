import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String neighborhood;
  final double rating;
  final int reviewCount;
  final String priceRange;
  final String status;
  final Color tileColor;
  final String? badge;
  final String? tagline;
  final String? address;
  final String? phone;
  final String? hours;
  final String? reserve;
  final String? walkInfo;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.neighborhood,
    required this.rating,
    required this.reviewCount,
    required this.priceRange,
    required this.status,
    required this.tileColor,
    this.badge,
    this.tagline,
    this.address,
    this.phone,
    this.hours,
    this.reserve,
    this.walkInfo,
  });
}

class CityGuide {
  final String city;
  final String country;
  final String season;
  final String tagline;
  final int spots;
  final int reviewers;
  final int stories;
  final Color heroColor;
  final List<CuratedGuide> guides;

  const CityGuide({
    required this.city,
    required this.country,
    required this.season,
    required this.tagline,
    required this.spots,
    required this.reviewers,
    required this.stories,
    required this.heroColor,
    required this.guides,
  });
}

class CuratedGuide {
  final String title;
  final int count;
  final Color tileColor;

  const CuratedGuide({required this.title, required this.count, required this.tileColor});
}

class TripDay {
  final DateTime date;
  final List<TripSpot> spots;

  const TripDay({required this.date, required this.spots});
}

class TripSpot {
  final String time;
  final String mealType;
  final String restaurantId;
  final String restaurantName;
  final String neighborhood;
  final String statusLabel;
  final Color statusColor;
  final Color tileColor;

  const TripSpot({
    required this.time,
    required this.mealType,
    required this.restaurantId,
    required this.restaurantName,
    required this.neighborhood,
    required this.statusLabel,
    required this.statusColor,
    required this.tileColor,
  });
}

class UserList {
  final String title;
  final int placeCount;
  final Color tileColor;

  const UserList({required this.title, required this.placeCount, required this.tileColor});
}

// ─── Sample Data ───────────────────────────────────────────────────────────────

final sampleRestaurants = [
  const Restaurant(
    id: 'sushi_dai',
    name: 'Sushi Dai',
    cuisine: 'Sushi',
    neighborhood: 'Tsukiji',
    rating: 4.9,
    reviewCount: 312,
    priceRange: '¥¥¥',
    status: 'Open · 1h 20m',
    tileColor: AppColors.tile1,
    badge: 'ICONIC',
    tagline: '"An unadorned counter, ten seats, and the chef\'s decisive hand. Come early, eat quickly, leave converted."',
    address: '5-2-1 Tsukiji, Chuo',
    phone: '+81 3-3547-6797',
    hours: '5:00 – 14:00',
    reserve: 'Walk-in only',
    walkInfo: '8 min walk from Tsukiji Stn',
  ),
  const Restaurant(
    id: 'afuri_ramen',
    name: 'Afuri Ramen',
    cuisine: 'Ramen',
    neighborhood: 'Ebisu',
    rating: 4.7,
    reviewCount: 204,
    priceRange: '¥¥',
    status: 'Open · 15m',
    tileColor: AppColors.tile2,
    tagline: 'Yuzu-forward broth, impossibly light. The bowl that made Ebisu famous.',
    address: '1-1-7 Ebisu, Shibuya',
    phone: '+81 3-5795-0750',
    hours: '11:00 – 23:00',
    reserve: 'Walk-in only',
  ),
  const Restaurant(
    id: 'den',
    name: 'Den',
    cuisine: 'Kaiseki',
    neighborhood: 'Gaienmae',
    rating: 4.9,
    reviewCount: 189,
    priceRange: '¥¥¥¥',
    status: 'Open · Booked',
    tileColor: AppColors.tile3,
    badge: 'ICONIC',
    tagline: 'Where Japanese tradition meets playful innovation. A Michelin two-star that never takes itself too seriously.',
    address: '2-3-18 Jingumae, Shibuya',
    phone: '+81 3-6455-5433',
    hours: '18:00 – 23:00',
    reserve: 'Reserve required',
  ),
  const Restaurant(
    id: 'tonkatsu_maisen',
    name: 'Tonkatsu Maisen',
    cuisine: 'Tonkatsu',
    neighborhood: 'Aoyama',
    rating: 4.7,
    reviewCount: 445,
    priceRange: '¥¥',
    status: 'Open',
    tileColor: AppColors.tile2,
    tagline: 'The tonkatsu pilgrimage ends here. Pork so tender it barely needs the knife.',
  ),
  const Restaurant(
    id: 'menya_itto',
    name: 'Menya Itto',
    cuisine: 'Ramen',
    neighborhood: 'Shin-Koiwa',
    rating: 4.9,
    reviewCount: 302,
    priceRange: '¥',
    status: 'Open',
    tileColor: AppColors.tile4,
    tagline: '"The best tsukemen in Tokyo is hiding under a train track."',
  ),
  const Restaurant(
    id: 'bills',
    name: 'Bills',
    cuisine: 'Brunch',
    neighborhood: 'Omotesandō',
    rating: 4.4,
    reviewCount: 178,
    priceRange: '¥¥',
    status: 'Open',
    tileColor: AppColors.tile5,
  ),
];

const tokyoGuide = CityGuide(
  city: 'Tokyo',
  country: 'Japan',
  season: 'Spring 2026',
  tagline: 'A city where a counter seat can be as transcendent as a tasting menu.',
  spots: 1284,
  reviewers: 312,
  stories: 48,
  heroColor: AppColors.dustyBlue,
  guides: [
    CuratedGuide(title: 'The Omakase Trail', count: 12, tileColor: AppColors.dustyBlue),
    CuratedGuide(title: '¥1000 & under', count: 28, tileColor: AppColors.warmTan),
    CuratedGuide(title: 'Late-night Tokyo', count: 19, tileColor: AppColors.tile5),
    CuratedGuide(title: 'Hidden Izakayas', count: 15, tileColor: AppColors.teal),
  ],
);

final sampleTrip = [
  TripDay(
    date: DateTime(2026, 4, 12),
    spots: const [
      TripSpot(
        time: '08:30',
        mealType: 'MORNING',
        restaurantId: 'sushi_dai',
        restaurantName: 'Sushi Dai',
        neighborhood: 'Tsukiji · 90m wait',
        statusLabel: 'Walk-in',
        statusColor: AppColors.warmGrey,
        tileColor: AppColors.tile1,
      ),
      TripSpot(
        time: '13:00',
        mealType: 'LUNCH',
        restaurantId: 'afuri_ramen',
        restaurantName: 'Afuri Ramen',
        neighborhood: 'Ebisu · 15m',
        statusLabel: 'Open',
        statusColor: AppColors.teal,
        tileColor: AppColors.tile2,
      ),
      TripSpot(
        time: '19:30',
        mealType: 'DINNER',
        restaurantId: 'den',
        restaurantName: 'Den',
        neighborhood: 'Kaiseki · Booked ✓',
        statusLabel: 'Reserved',
        statusColor: AppColors.teal,
        tileColor: AppColors.tile3,
      ),
    ],
  ),
];

final userLists = [
  const UserList(title: 'Tasting menu bucket list', placeCount: 18, tileColor: AppColors.sageGreen),
  const UserList(title: 'Cheap & iconic', placeCount: 34, tileColor: AppColors.warmTan),
  const UserList(title: 'Window tables only', placeCount: 11, tileColor: AppColors.dustyBlue),
  const UserList(title: 'Tokyo April 2026', placeCount: 23, tileColor: AppColors.softRed),
];
