import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../models/trip_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef Restaurant = RestaurantModel;
typedef TripDay = TripDayModel;
typedef TripSpot = TripSpotModel;

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

class UserList {
  final String title;
  final int placeCount;
  final Color tileColor;

  const UserList({required this.title, required this.placeCount, required this.tileColor});
}

final sampleRestaurants = [
  RestaurantModel(
    id: 'sushi_dai',
    name: 'Sushi Dai',
    category: 'Sushi',
    cityId: 'tokyo',
    neighborhood: 'Tsukiji',
    geopoint: const GeoPoint(35.6654, 139.7707),
    description: '"An unadorned counter, ten seats, and the chef\'s decisive hand. Come early, eat quickly, leave converted."',
    tip: 'Walk-in only. 8 min walk from Tsukiji Stn',
    dish: 'Omakase',
    mediaUrls: [],
    contributorId: 'system',
    status: 'approved',
    avgRating: 4.9,
    reviewCount: 312,
    saveCount: 150,
    priceRange: '¥¥¥',
    tileColor: AppColors.tile1,
    badge: 'ICONIC',
    tagline: '"An unadorned counter, ten seats, and the chef\'s decisive hand. Come early, eat quickly, leave converted."',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  RestaurantModel(
    id: 'afuri_ramen',
    name: 'Afuri Ramen',
    category: 'Ramen',
    cityId: 'tokyo',
    neighborhood: 'Ebisu',
    geopoint: const GeoPoint(35.6654, 139.7707),
    description: 'Yuzu-forward broth, impossibly light. The bowl that made Ebisu famous.',
    tip: 'Walk-in only',
    dish: 'Yuzu Ramen',
    mediaUrls: [],
    contributorId: 'system',
    status: 'approved',
    avgRating: 4.7,
    reviewCount: 204,
    saveCount: 100,
    priceRange: '¥¥',
    tileColor: AppColors.tile2,
    badge: null,
    tagline: 'Yuzu-forward broth, impossibly light. The bowl that made Ebisu famous.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  RestaurantModel(
    id: 'den',
    name: 'Den',
    category: 'Kaiseki',
    cityId: 'tokyo',
    neighborhood: 'Gaienmae',
    geopoint: const GeoPoint(35.6654, 139.7707),
    description: 'Where Japanese tradition meets playful innovation. A Michelin two-star that never takes itself too seriously.',
    tip: 'Reserve required',
    dish: 'Dentucky Fried Chicken',
    mediaUrls: [],
    contributorId: 'system',
    status: 'approved',
    avgRating: 4.9,
    reviewCount: 189,
    saveCount: 200,
    priceRange: '¥¥¥¥',
    tileColor: AppColors.tile3,
    badge: 'ICONIC',
    tagline: 'Where Japanese tradition meets playful innovation. A Michelin two-star that never takes itself too seriously.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  RestaurantModel(
    id: 'tonkatsu_maisen',
    name: 'Tonkatsu Maisen',
    category: 'Tonkatsu',
    cityId: 'tokyo',
    neighborhood: 'Aoyama',
    geopoint: const GeoPoint(35.6654, 139.7707),
    description: 'The tonkatsu pilgrimage ends here. Pork so tender it barely needs the knife.',
    tip: '',
    dish: 'Kurobuta Tonkatsu',
    mediaUrls: [],
    contributorId: 'system',
    status: 'approved',
    avgRating: 4.7,
    reviewCount: 445,
    saveCount: 300,
    priceRange: '¥¥',
    tileColor: AppColors.tile2,
    badge: null,
    tagline: 'The tonkatsu pilgrimage ends here. Pork so tender it barely needs the knife.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  RestaurantModel(
    id: 'menya_itto',
    name: 'Menya Itto',
    category: 'Ramen',
    cityId: 'tokyo',
    neighborhood: 'Shin-Koiwa',
    geopoint: const GeoPoint(35.6654, 139.7707),
    description: '"The best tsukemen in Tokyo is hiding under a train track."',
    tip: '',
    dish: 'Tsukemen',
    mediaUrls: [],
    contributorId: 'system',
    status: 'approved',
    avgRating: 4.9,
    reviewCount: 302,
    saveCount: 100,
    priceRange: '¥',
    tileColor: AppColors.tile4,
    badge: null,
    tagline: '"The best tsukemen in Tokyo is hiding under a train track."',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  RestaurantModel(
    id: 'bills',
    name: 'Bills',
    category: 'Brunch',
    cityId: 'tokyo',
    neighborhood: 'Omotesandō',
    geopoint: const GeoPoint(35.6654, 139.7707),
    description: '',
    tip: '',
    dish: '',
    mediaUrls: [],
    contributorId: 'system',
    status: 'approved',
    avgRating: 4.4,
    reviewCount: 178,
    saveCount: 50,
    priceRange: '¥¥',
    tileColor: AppColors.tile5,
    badge: null,
    tagline: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
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
  TripDayModel(
    id: 'd1',
    date: DateTime(2026, 4, 12),
    spots: [
      const TripSpotModel(
        id: 's1',
        time: '08:30',
        mealType: 'MORNING',
        restaurantId: 'sushi_dai',
        name: 'Sushi Dai',
        neighborhood: 'Tsukiji · 90m wait',
        statusLabel: 'Walk-in',
        statusColor: AppColors.warmGrey,
        tileColor: AppColors.tile1,
      ),
      const TripSpotModel(
        id: 's2',
        time: '13:00',
        mealType: 'LUNCH',
        restaurantId: 'afuri_ramen',
        name: 'Afuri Ramen',
        neighborhood: 'Ebisu · 15m',
        statusLabel: 'Open',
        statusColor: AppColors.teal,
        tileColor: AppColors.tile2,
      ),
      const TripSpotModel(
        id: 's3',
        time: '19:30',
        mealType: 'DINNER',
        restaurantId: 'den',
        name: 'Den',
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
