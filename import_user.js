const admin = require('firebase-admin');
const app = admin.initializeApp({
  projectId: 'neon-jump-stellar'
});
admin.auth().updateUser('1TZfg0sKcXTeFmxoVfUo3zznIOB3', {
  email: 'joperdomoo16@gmail.com',
  emailVerified: true
}).then((userRecord) => {
  console.log('Successfully updated user', userRecord.toJSON());
}).catch((error) => {
  console.log('Error updating user:', error);
});
