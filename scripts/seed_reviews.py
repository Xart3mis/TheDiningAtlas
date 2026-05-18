#!/usr/bin/env python3
"""
Seed diverse reviews for all restaurants in DiningAtlas.
Usage: python scripts/seed_reviews.py --project the-dining-atlas
Requires: pip install firebase-admin
Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON.
"""

import argparse
import datetime
import random
import uuid
import firebase_admin
from firebase_admin import credentials, firestore

REVIEW_TEMPLATES = [
    ("Absolutely stunning meal. The flavors were bold yet balanced.", 5.0),
    ("A hidden gem — locals only know about this place. Don't skip the dessert.", 4.5),
    ("Solid food, great atmosphere. Prices are reasonable for the quality.", 4.0),
    ("Arrived late but still got a table. The service was attentive and friendly.", 4.0),
    ("The house specialty is exactly what the name suggests — order it.", 4.5),
    ("Perfect spot for a lazy Sunday. Come hungry, leave happy.", 5.0),
    ("Not bad but had better elsewhere. The views make up for the average food.", 3.5),
    ("Genuinely surprised by the quality. Will definitely be back next trip.", 5.0),
    ("A bit noisy on weekends but the food is worth it. Book ahead.", 4.0),
    ("The chef clearly takes pride in every dish. Exceptional technique.", 4.5),
]

AUTHOR_NAMES = [
    "Marco V.", "Yuki T.", "Sophie L.", "Amir H.", "Priya K.",
    "Lucas M.", "Elena B.", "Fatima A.", "James O.", "Nina C.",
]

def seed_reviews(project_id: str, dry_run: bool = False):
    if not firebase_admin._apps:
        firebase_admin.initialize_app()
    db = firestore.client()

    restaurants = db.collection("restaurants").stream()
    restaurant_ids = [r.id for r in restaurants]
    print(f"Found {len(restaurant_ids)} restaurants")

    batch = db.batch()
    count = 0

    for rid in restaurant_ids:
        reviews_ref = db.collection("restaurants").doc(rid).collection("reviews")
        existing = list(reviews_ref.limit(1).stream())
        if existing:
            print(f"  Skipping {rid} — already has reviews")
            continue

        num_reviews = random.randint(5, 8)
        shuffled = random.sample(REVIEW_TEMPLATES, min(num_reviews, len(REVIEW_TEMPLATES)))

        for i, (text, rating) in enumerate(shuffled):
            author = random.choice(AUTHOR_NAMES)
            review_ref = reviews_ref.document(str(uuid.uuid4()))
            days_ago = random.randint(1, 120)
            created = datetime.datetime.utcnow() - datetime.timedelta(days=days_ago)
            data = {
                "restaurantId": rid,
                "authorId": f"seed:{author.lower().replace(' ', '_')}",
                "authorName": author,
                "authorPhotoUrl": "",
                "text": text,
                "rating": rating,
                "upvotes": random.randint(0, 24),
                "createdAt": created,
            }
            if not dry_run:
                batch.set(review_ref, data)
            count += 1

    if not dry_run:
        batch.commit()
        print(f"Seeded {count} reviews across {len(restaurant_ids)} restaurants")
    else:
        print(f"[DRY RUN] Would seed {count} reviews")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", default="the-dining-atlas")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    import os
    os.environ.setdefault("GCLOUD_PROJECT", args.project)
    seed_reviews(args.project, dry_run=args.dry_run)
