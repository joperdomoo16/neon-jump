const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

const app = admin.initializeApp({
  projectId: 'neon-jump-stellar'
});
const db = getFirestore();

async function findAndUpdate() {
  try {
    const snapshot = await db.collection('leaderboard').where('name', '==', 'George').get();
    if (snapshot.empty) {
      console.log('No matching documents for name=George.');
      return;
    }  

    snapshot.forEach(async doc => {
      console.log(doc.id, '=>', doc.data());
      await doc.ref.update({ score: 7035 });
      console.log('Updated to 7035!');
    });
  } catch (error) {
    console.error(error);
  }
}
findAndUpdate();
