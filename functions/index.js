const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Update avgRating when a review is created/deleted
exports.updateAvgRating = functions.firestore
  .document('restaurants/{restaurantId}/reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const { restaurantId } = context.params;
    const reviewsSnap = await db.collection('restaurants').doc(restaurantId)
      .collection('reviews').get();
    if (reviewsSnap.empty) {
      await db.collection('restaurants').doc(restaurantId).update({ avgRating: 0, reviewCount: 0 });
      return;
    }
    const total = reviewsSnap.docs.reduce((sum, d) => sum + (d.data().rating || 0), 0);
    const avg = total / reviewsSnap.size;
    await db.collection('restaurants').doc(restaurantId).update({
      avgRating: Math.round(avg * 10) / 10,
      reviewCount: reviewsSnap.size,
    });
  });

// Update contributor score when a review is added to their restaurant
exports.updateContributorScore = functions.firestore
  .document('restaurants/{restaurantId}/reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const { restaurantId } = context.params;
    const restaurant = await db.collection('restaurants').doc(restaurantId).get();
    const contributorId = restaurant.data()?.contributorId;
    if (!contributorId) return;
    await db.collection('users').doc(contributorId).update({
      score: admin.firestore.FieldValue.increment(5),
    });
    await _updateTier(contributorId);
  });

// Score decay — run monthly
exports.monthlyScoreDecay = functions.pubsub
  .schedule('0 0 1 * *').onRun(async () => {
    const usersSnap = await db.collection('users').where('score', '>', 0).get();
    const batch = db.batch();
    usersSnap.docs.forEach(doc => {
      const lastSeen = doc.data().lastActiveAt?.toDate();
      const monthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      if (!lastSeen || lastSeen < monthAgo) {
        batch.update(doc.ref, { score: admin.firestore.FieldValue.increment(-5) });
      }
    });
    await batch.commit();
  });

// Tier update helper
async function _updateTier(uid) {
  const userDoc = await db.collection('users').doc(uid).get();
  const score = userDoc.data()?.score || 0;
  let tier = 'explorer';
  if (score >= 2000) tier = 'city_legend';
  else if (score >= 500) tier = 'super_local';
  else if (score >= 100) tier = 'local';
  await db.collection('users').doc(uid).update({ tier });
}
