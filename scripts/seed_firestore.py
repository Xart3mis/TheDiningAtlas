#!/usr/bin/env python3

import argparse
import json
import re
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


TILE_COLORS = [
    0xFFCC4A1E,
    0xFF5C7A6B,
    0xFF2E5B52,
    0xFFB8962E,
    0xFF8C7B6A,
]


class DryRunFirestore:
    SERVER_TIMESTAMP = "__SERVER_TIMESTAMP__"

    class GeoPoint:
        def __init__(self, latitude: float, longitude: float) -> None:
            self.latitude = latitude
            self.longitude = longitude

        def __repr__(self) -> str:
            return f"GeoPoint({self.latitude}, {self.longitude})"


firestore = DryRunFirestore
GeoPointClass = DryRunFirestore.GeoPoint


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Import DiningAtlas seed.json into Firestore."
    )

    parser.add_argument(
        "--seed",
        default="seed.json",
        help="Path to seed JSON file.",
    )

    parser.add_argument(
        "--project-id",
        help="Firebase project id.",
    )

    parser.add_argument(
        "--credentials",
        help="Path to Firebase service-account JSON.",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and validate without Firestore writes.",
    )

    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print generated documents.",
    )

    args = parser.parse_args()

    seed_path = Path(args.seed)

    if not seed_path.exists():
        raise FileNotFoundError(f"Seed file not found: {seed_path}")

    with seed_path.open(encoding="utf-8") as handle:
        seed = json.load(handle)

    if args.dry_run:
        cities, restaurants = build_documents(seed)

        validate_metadata(seed, cities, restaurants)

        print(f"Parsed {len(cities)} cities")
        print(f"Parsed {len(restaurants)} restaurants")
        return

    db = initialize_firebase(
        project_id=args.project_id,
        credentials_path=args.credentials,
    )

    cities, restaurants = build_documents(seed)

    validate_metadata(seed, cities, restaurants)

    write_documents(db, cities, restaurants)

    print(f"Seeded {len(cities)} cities")
    print(f"Seeded {len(restaurants)} restaurants")


def initialize_firebase(project_id: str | None, credentials_path: str | None):
    global firestore
    global GeoPointClass

    import firebase_admin
    from firebase_admin import credentials
    from firebase_admin import firestore as firestore_module
    from google.cloud import firestore_v1

    firestore = firestore_module
    GeoPointClass = firestore_v1.GeoPoint

    if firebase_admin._apps:
        return firestore.client()

    options = {"projectId": project_id} if project_id else None

    if credentials_path:
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred, options)
    else:
        firebase_admin.initialize_app(options=options)

    return firestore.client()

def build_documents(
    seed: dict,
) -> tuple[list[tuple[str, dict]], list[tuple[str, dict]]]:

    metadata = seed.get("metadata", {})

    generated_at = parse_generated_at(metadata.get("generated"))

    cities: list[tuple[str, dict]] = []
    restaurants: list[tuple[str, dict]] = []

    for country_entry in seed.get("countries", []):

        country = country_entry.get("country", "")
        country_code = country_entry.get("country_code", "")

        for city_entry in country_entry.get("cities", []):

            city_name = city_entry.get("city", "")
            city_rank = int(city_entry.get("city_rank", 0) or 0)

            city_id = city_id_for(country_code, city_name)

            venues = city_entry.get("venues", [])

            city_document = {
                "id": city_id,
                "name": city_name,
                "slug": slug(city_name),
                "country": country,
                "countryCode": country_code,
                "rank": city_rank,
                "venueCount": len(venues),
                "coordinates": geopoint(city_entry.get("coordinates", {})),
                "createdAt": generated_at,
                "updatedAt": firestore.SERVER_TIMESTAMP,
                "seedVersion": metadata.get("version"),
            }

            cities.append((city_id, clean_document(city_document)))

            for venue in venues:

                restaurant_id = (
                    venue.get("id")
                    or deterministic_id(
                        f"{country_code}:{city_name}:{venue.get('name', '')}"
                    )
                )

                restaurant_doc = restaurant_document(
                    venue=venue,
                    restaurant_id=restaurant_id,
                    city_id=city_id,
                    city_name=city_name,
                    country=country,
                    country_code=country_code,
                    generated_at=generated_at,
                    metadata=metadata,
                )

                restaurants.append((restaurant_id, restaurant_doc))

    return cities, restaurants


def restaurant_document(
    venue: dict,
    *,
    restaurant_id: str,
    city_id: str,
    city_name: str,
    country: str,
    country_code: str,
    generated_at: datetime,
    metadata: dict,
) -> dict:

    venue_type = venue.get("type", "").strip()

    cuisine = (
        venue.get("cuisine_type")
        or title_case(venue_type)
    )

    mood_tags = string_list(venue.get("mood_tags"))
    vibe_tags = string_list(venue.get("vibe_tags"))
    tourist_tags = string_list(venue.get("touristiness_tags"))
    crowded_tags = string_list(venue.get("crowdedness_tags"))

    all_tags = unique_strings([
        *mood_tags,
        *vibe_tags,
        *tourist_tags,
        *crowded_tags,
    ])

    tip_parts = []

    if venue.get("best_time_of_day"):
        tip_parts.append(f"Best for {venue['best_time_of_day']}")

    if venue.get("estimated_avg_spend"):
        tip_parts.append(f"Average spend {venue['estimated_avg_spend']}")

    if venue.get("dress_code"):
        tip_parts.append(f"Dress code {venue['dress_code']}")

    description = venue.get("description", "").strip()

    document = {
        "id": restaurant_id,
        "slug": slug(venue.get("name", "")),
        "name": venue.get("name", ""),
        "category": title_case(venue_type),
        "type": venue_type,

        "cityId": city_id,
        "city": city_name,
        "country": country,
        "countryCode": country_code,

        "coordinates": geopoint(venue.get("coordinates", {})),

        "description": description,
        "tagline": truncate(description, 120),

        "tip": ". ".join(tip_parts),

        "address": venue.get("address"),
        "hours": venue.get("opening_hours"),

        "priceRange": venue.get("cost_range", "$$"),
        "estimatedSpend": venue.get("estimated_avg_spend"),

        "dish": cuisine,
        "cuisine": cuisine,

        "tags": all_tags,
        "moodTags": mood_tags,
        "vibeTags": vibe_tags,
        "touristinessTags": tourist_tags,
        "crowdednessTags": crowded_tags,

        "bestTimeOfDay": venue.get("best_time_of_day"),
        "seasonalPopularity": venue.get("seasonal_popularity"),

        "dressCode": venue.get("dress_code"),

        "instagram": venue.get("instagram"),
        "reservationUrl": venue.get("reservation_url"),

        "musicGenre": venue.get("music_genre"),

        "mediaUrls": [],

        "avgRating": seed_rating(restaurant_id),
        "reviewCount": 0,
        "saveCount": 0,

        "tileColorValue": tile_color(restaurant_id),

        "badge": (
            title_case(all_tags[0].replace("-", " "))
            if all_tags else None
        ),

        "walkInfo": " • ".join(
            title_case(tag.replace("-", " "))
            for tag in all_tags[:3]
        ),

        "searchText": build_search_text(
            venue=venue,
            city_name=city_name,
            country=country,
            cuisine=cuisine,
            tags=all_tags,
        ),

        "status": "approved",
        "source": "seed",

        "contributorId": f"seed:{country_code.lower()}",

        "createdAt": generated_at,
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "seedVersion": metadata.get("version"),
    }

    return clean_document(document)


def write_documents(
    db,
    cities: list[tuple[str, dict]],
    restaurants: list[tuple[str, dict]],
) -> None:

    writes = []

    for doc_id, data in cities:
        writes.append(("cities", doc_id, data))

    for doc_id, data in restaurants:
        writes.append(("restaurants", doc_id, data))

    batch_size = 450

    for start in range(0, len(writes), batch_size):

        batch = db.batch()

        chunk = writes[start : start + batch_size]

        for collection_name, doc_id, data in chunk:

            ref = db.collection(collection_name).document(doc_id)

            batch.set(ref, data, merge=True)

        batch.commit()

        print(
            f"Committed batch "
            f"{(start // batch_size) + 1} "
            f"({len(chunk)} writes)"
        )


def validate_metadata(
    seed: dict,
    cities: list,
    restaurants: list,
) -> None:

    metadata = seed.get("metadata", {})

    expected_countries = metadata.get("total_countries")
    expected_cities = metadata.get("total_cities")
    expected_venues = metadata.get("total_venues")

    actual_countries = len(seed.get("countries", []))
    actual_cities = len(cities)
    actual_venues = len(restaurants)

    mismatches = []

    if expected_countries != actual_countries:
        mismatches.append(
            f"countries metadata={expected_countries} actual={actual_countries}"
        )

    if expected_cities != actual_cities:
        mismatches.append(
            f"cities metadata={expected_cities} actual={actual_cities}"
        )

    if expected_venues != actual_venues:
        mismatches.append(
            f"venues metadata={expected_venues} actual={actual_venues}"
        )

    if mismatches:
        raise ValueError(
            "Seed metadata mismatch: " + "; ".join(mismatches)
        )


def build_search_text(
    *,
    venue: dict,
    city_name: str,
    country: str,
    cuisine: str,
    tags: list[str],
) -> str:

    parts = [
        venue.get("name", ""),
        venue.get("description", ""),
        cuisine,
        city_name,
        country,
        venue.get("type", ""),
        *tags,
    ]

    return " ".join(
        part.strip()
        for part in parts
        if isinstance(part, str) and part.strip()
    )


def city_id_for(country_code: str, city_name: str) -> str:
    return f"{country_code.lower()}-{slug(city_name)}"


def slug(value: str) -> str:

    value = value.lower()

    value = re.sub(r"[^\w\s-]", "", value)

    value = re.sub(r"[\s_]+", "-", value)

    value = re.sub(r"-+", "-", value)

    return value.strip("-") or "unknown"


def geopoint(coordinates: dict):
    lat = float(coordinates.get("lat", 0) or 0)
    lng = float(coordinates.get("lng", 0) or 0)

    return GeoPointClass(lat, lng)

def string_list(value: object) -> list[str]:

    if not isinstance(value, list):
        return []

    return [
        str(item).strip()
        for item in value
        if str(item).strip()
    ]


def unique_strings(values: list[str]) -> list[str]:

    seen = set()
    result = []

    for value in values:

        normalized = value.lower()

        if normalized in seen:
            continue

        seen.add(normalized)

        result.append(value)

    return result


def title_case(value: str) -> str:

    return " ".join(
        word[:1].upper() + word[1:]
        for word in value.split()
        if word
    )


def seed_rating(restaurant_id: str) -> float:

    return round(
        4.2 + (
            (sum(ord(char) for char in restaurant_id) % 8) / 10
        ),
        1,
    )


def tile_color(restaurant_id: str) -> int:

    return TILE_COLORS[
        sum(ord(char) for char in restaurant_id) % len(TILE_COLORS)
    ]


def truncate(value: str, length: int) -> str:

    if len(value) <= length:
        return value

    return value[: length - 3].rstrip() + "..."


def deterministic_id(value: str) -> str:

    return hashlib.md5(
        value.encode("utf-8")
    ).hexdigest()[:16]


def parse_generated_at(value: str | None) -> datetime:

    if not value:
        return datetime.now(tz=timezone.utc)

    return datetime.fromisoformat(value).replace(
        tzinfo=timezone.utc
    )


def clean_document(document: dict[str, Any]) -> dict[str, Any]:

    cleaned = {}

    for key, value in document.items():

        if value is None:
            continue

        if value == "":
            continue

        if value == []:
            continue

        cleaned[key] = value

    return cleaned


def serialize_firestore(value):

    if isinstance(value, datetime):
        return value.isoformat()

    if hasattr(value, "latitude") and hasattr(value, "longitude"):
        return {
            "lat": value.latitude,
            "lng": value.longitude,
        }

    return str(value)


if __name__ == "__main__":
    main()
