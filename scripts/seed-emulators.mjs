import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

if (!process.argv.includes('--emulator')) throw new Error('This script is restricted to local emulators.');
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8088';
initializeApp({ projectId: 'demo-campus-care' });
const auth = getAuth();
const db = getFirestore();
const password = 'CampusCare123!';
for (const [uid, email, displayName, staff] of [
  ['demo-student', 'student@alustudent.com', 'Amina Hassan', false],
  ['demo-staff', 'staff@alueducation.com', 'Campus Support', true],
]) {
  try { await auth.createUser({ uid, email, displayName, password, emailVerified: true }); }
  catch (error) { if (error.code !== 'auth/uid-already-exists' && error.code !== 'auth/email-already-exists') throw error; }
  await auth.setCustomUserClaims(uid, { staff });
}
const samples = [
  ['water-shortage', 'Water shortage', 'water', 'Student Residence', 'There has been no water supply in the residence since this morning. Please check the supply.'],
  ['classroom-projector', 'Broken classroom projector', 'facilities', 'Block B - Room 204', 'The projector does not turn on and the class cannot display lecture materials.'],
  ['overflowing-bin', 'Overflowing bin', 'sanitation', 'Cafeteria', 'The bin outside the cafeteria is overflowing and needs to be emptied and cleaned.'],
];
for (const [id, title, category, location, description] of samples) {
  const ref = db.collection('incidents').doc(id);
  if ((await ref.get()).exists) continue;
  await ref.set({ ownerId: 'demo-student', reporterName: 'Amina Hassan', title, category, location, description,
    status: 'submitted', photoPath: '', createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    history: { submitted: { status: 'submitted', by: 'demo-student', note: 'Report submitted.', at: FieldValue.serverTimestamp() } } });
}
console.log('Local accounts ready: student@alustudent.com / staff@alueducation.com');
console.log(`Local-only password: ${password}`);
