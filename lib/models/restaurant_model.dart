import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String category;
  final String cityId;
  final String neighborhood;
  final GeoPoint geopoint;
  final String description;
  final String tip;
  final String dish;
  final List<String> mediaUrls;
  final String contributorId;
  final String status; // 'approved' | 'pending'
  final double avgRating;
  final int reviewCount;
  final int saveCount;
  final String priceRange; // '$' | '$$' | '$$$'
  final Color tileColor;
  final String? badge;
  final String tagline;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Legacy field aliases for UI compatibility
  double get rating => avgRating;
  final String? address;
  final String? hours;
  final String? phone;
  final String? reserve;
  final String? walkInfo;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.category,
    required this.cityId,
    required this.neighborhood,
    required this.geopoint,
    required this.description,
    required this.tip,
    required this.dish,
    required this.mediaUrls,
    required this.contributorId,
    required this.status,
    required this.avgRating,
    required this.reviewCount,
    required this.saveCount,
    required this.priceRange,
    required this.tileColor,
    this.badge,
    required this.tagline,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.hours,
    this.phone,
    this.reserve,
    this.walkInfo,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RestaurantModel(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      cityId: d['cityId'] ?? '',
      neighborhood: d['neighborhood'] ?? '',
      geopoint: d['geopoint'] ?? const GeoPoint(0, 0),
      description: d['description'] ?? '',
      tip: d['tip'] ?? '',
      dish: d['dish'] ?? '',
      mediaUrls: List<String>.from(d['mediaUrls'] ?? []),
      contributorId: d['contributorId'] ?? '',
      status: d['status'] ?? 'pending',
      avgRating: (d['avgRating'] ?? 0.0).toDouble(),
      reviewCount: d['reviewCount'] ?? 0,
      saveCount: d['saveCount'] ?? 0,
      priceRange: d['priceRange'] ?? '\$',
      tileColor: Color(d['tileColorValue'] ?? 0xFFF5EFE6),
      badge: d['badge'],
      tagline: d['tagline'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: d['address'],
      hours: d['hours'],
      phone: d['phone'],
      reserve: d['reserve'],
      walkInfo: d['walkInfo'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'category': category,
    'cityId': cityId,
    'neighborhood': neighborhood,
    'geopoint': geopoint,
    'description': description,
    'tip': tip,
    'dish': dish,
    'mediaUrls': mediaUrls,
    'contributorId': contributorId,
    'status': status,
    'avgRating': avgRating,
    'reviewCount': reviewCount,
    'saveCount': saveCount,
    'priceRange': priceRange,
    'tileColorValue': tileColor.value,
    'badge': badge,
    'tagline': tagline,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    if (address != null) 'address': address,
    if (hours != null) 'hours': hours,
    if (phone != null) 'phone': phone,
    if (reserve != null) 'reserve': reserve,
    if (walkInfo != null) 'walkInfo': walkInfo,
  };
}
