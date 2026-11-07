import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const [projectId, uid, role] = process.argv.slice(2);
if (!projectId || !uid || !['grant', 'revoke'].includes(role)) {
  throw new Error('Usage: node scripts/set-staff.mjs PROJECT_ID USER_UID grant|revoke');
}
if (process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Use the local seed script for emulator accounts.');
initializeApp({ projectId, credential: applicationDefault() });
const auth = getAuth();
const user = await auth.getUser(uid);
if (!user.emailVerified || !/^[^@ ]+@(alustudent\.com|alueducation\.com)$/.test(user.email ?? '')) {
  throw new Error('Staff must have a verified ALU email.');
}
await auth.setCustomUserClaims(uid, { ...user.customClaims, staff: role === 'grant' });
console.log(`Staff access ${role === 'grant' ? 'granted' : 'revoked'}. The user must refresh their session.`);
