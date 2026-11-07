import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc, collection, getDocs, query, where, serverTimestamp, Timestamp } from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';

let env;
const projectId = 'demo-campus-care';
const token = (email = 'alice@alustudent.com', email_verified = true, staff = false) => ({ email, email_verified, staff });
const alice = () => env.authenticatedContext('alice', token());
const bob = () => env.authenticatedContext('bob', token('bob@alustudent.com'));
const staff = () => env.authenticatedContext('staff', token('staff@alueducation.com', true, true));
const record = (ownerId = 'alice') => ({ ownerId, reporterName: 'Amina Hassan', title: 'Water shortage',
  description: 'There is no water in the student residence this morning.', location: 'Student Residence', category: 'water',
  status: 'submitted', photoPath: '', createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  history: { submitted: { status: 'submitted', by: ownerId, at: serverTimestamp(), note: 'Report submitted.' } } });
const report = context => doc(context.firestore(), 'incidents', 'report-1');
async function seed(data = record()) { await env.withSecurityRulesDisabled(c => setDoc(report(c), data)); }
async function advance(context, status, note = 'Campus staff are working on this issue.') {
  return updateDoc(report(context), { status, updatedAt: serverTimestamp(), [`history.${status}`]: {
    status, by: 'staff', at: serverTimestamp(), note,
  } });
}

before(async () => {
  env = await initializeTestEnvironment({ projectId,
    firestore: { host: '127.0.0.1', port: 8088, rules: readFileSync('firestore.rules', 'utf8') },
    storage: { host: '127.0.0.1', port: 9199, rules: readFileSync('storage.rules', 'utf8') },
  });
});
beforeEach(async () => { await env.clearFirestore(); await env.clearStorage(); });
after(async () => { await env?.cleanup(); });

test('verified ALU student creates and retrieves their report', async () => {
  await assertSucceeds(setDoc(report(alice()), record()));
  await assertSucceeds(getDoc(report(alice())));
});
test('anonymous users cannot read or create', async () => {
  await seed(); const guest = env.unauthenticatedContext();
  await assertFails(getDoc(report(guest))); await assertFails(setDoc(report(guest), record()));
});
test('unverified ALU accounts are blocked', async () => {
  await seed(); const unverified = env.authenticatedContext('alice', token('alice@alustudent.com', false));
  await assertFails(getDoc(report(unverified))); await assertFails(setDoc(report(unverified), record()));
});
test('external and lookalike domains are blocked even with staff claim', async () => {
  await seed();
  for (const email of ['alice@gmail.com', 'alice@fakealustudent.com', 'alice@alustudent.com.evil.org']) {
    await assertFails(getDoc(report(env.authenticatedContext('alice', token(email, true, true)))));
  }
});
test('students cannot read another student report or list the campus queue', async () => {
  await seed(); await assertFails(getDoc(report(bob())));
  await assertFails(getDocs(collection(alice().firestore(), 'incidents')));
});
test('owner-constrained listing and staff campus listing succeed', async () => {
  await seed();
  await assertSucceeds(getDocs(query(collection(alice().firestore(), 'incidents'), where('ownerId', '==', 'alice'))));
  await assertSucceeds(getDocs(collection(staff().firestore(), 'incidents')));
});
test('forged ownership and initial resolved status fail', async () => {
  await assertFails(setDoc(report(alice()), record('bob')));
  await assertFails(setDoc(report(alice()), { ...record(), status: 'resolved' }));
});
test('extra fields, invalid category, Unicode and short descriptions fail', async () => {
  for (const change of [{ staff: true }, { category: 'other' }, { title: 'Water \u2014 shortage' }, { description: 'Too short' }]) {
    await assertFails(setDoc(report(alice()), { ...record(), ...change }));
  }
});
test('multiline ASCII descriptions are accepted', async () => {
  await assertSucceeds(setDoc(report(alice()), { ...record(), description: 'No water since morning.\nPlease check the campus supply.' }));
});
test('client timestamps and forged submission history fail', async () => {
  await assertFails(setDoc(report(alice()), { ...record(), createdAt: Timestamp.fromMillis(1) }));
  const data = record(); data.history.submitted.by = 'staff';
  await assertFails(setDoc(report(alice()), data));
});
test('owner can edit and delete only while submitted', async () => {
  await seed();
  await assertSucceeds(updateDoc(report(alice()), { title: 'Water shortage in residence', updatedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(report(alice())));
  await seed(); await assertSucceeds(advance(staff(), 'inProgress'));
  await assertFails(updateDoc(report(alice()), { title: 'Changed by student', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(report(alice())));
});
test('students cannot promote themselves or change status', async () => {
  await seed();
  await assertFails(setDoc(doc(alice().firestore(), 'users', 'alice'), { staff: true }));
  await assertFails(updateDoc(report(alice()), { status: 'inProgress', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(report(alice()), { ownerId: 'bob', updatedAt: serverTimestamp() }));
});
test('staff advances sequentially with timestamped history', async () => {
  await seed(); await assertSucceeds(advance(staff(), 'inProgress'));
  await assertSucceeds(advance(staff(), 'resolved', 'The water supply has been restored.'));
  await assertFails(advance(staff(), 'inProgress'));
});
test('staff cannot skip stages, edit content, erase history or delete reports', async () => {
  await seed(); await assertFails(advance(staff(), 'resolved'));
  await assertFails(updateDoc(report(staff()), { title: 'Staff content edit', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(report(staff())));
  await assertSucceeds(advance(staff(), 'inProgress'));
  await assertFails(updateDoc(report(staff()), { status: 'resolved', updatedAt: serverTimestamp(), history: {
    resolved: { status: 'resolved', by: 'staff', at: serverTimestamp(), note: 'Resolved without the old history.' }
  } }));
});
test('photo paths cannot point to another owner or external URL', async () => {
  await seed();
  for (const path of ['https://example.com/photo', 'incidents/bob/report-1/photo']) {
    await assertFails(updateDoc(report(alice()), { photoPath: path, updatedAt: serverTimestamp() }));
  }
  await assertSucceeds(updateDoc(report(alice()), { photoPath: 'incidents/alice/report-1/photo', updatedAt: serverTimestamp() }));
});

const picture = context => ref(context.storage(), 'incidents/alice/report-1/photo');
const bytes = new Uint8Array([255, 216, 255, 224, 0, 0, 255, 217]);
test('owner uploads photo; owner and staff read; another student cannot', async () => {
  await seed();
  await assertSucceeds(uploadBytes(picture(alice()), bytes, { contentType: 'image/jpeg' }));
  await assertSucceeds(getBytes(picture(alice()))); await assertSucceeds(getBytes(picture(staff())));
  await assertFails(getBytes(picture(bob())));
});
test('photos require a parent report, ownership and verification', async () => {
  await assertFails(uploadBytes(picture(alice()), bytes, { contentType: 'image/jpeg' }));
  await seed();
  await assertFails(uploadBytes(picture(bob()), bytes, { contentType: 'image/jpeg' }));
  const unverified = env.authenticatedContext('alice', token('alice@alustudent.com', false));
  await assertFails(uploadBytes(picture(unverified), bytes, { contentType: 'image/jpeg' }));
});
test('Storage rejects large photos, unsupported types and public download tokens', async () => {
  await seed();
  await assertFails(uploadBytes(picture(alice()), new Uint8Array(5 * 1024 * 1024 + 1), { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(picture(alice()), bytes, { contentType: 'application/pdf' }));
  await assertFails(uploadBytes(picture(alice()), bytes, { contentType: 'image/jpeg', customMetadata: { firebaseStorageDownloadTokens: 'public-token' } }));
});
test('owner can delete a submitted photo but cannot change a photo after staff begin', async () => {
  await seed(); await assertSucceeds(uploadBytes(picture(alice()), bytes, { contentType: 'image/jpeg' }));
  await assertSucceeds(deleteObject(picture(alice())));
  await assertSucceeds(uploadBytes(picture(alice()), bytes, { contentType: 'image/jpeg' }));
  await assertSucceeds(advance(staff(), 'inProgress'));
  await assertFails(deleteObject(picture(alice())));
  await assertFails(uploadBytes(picture(alice()), bytes, { contentType: 'image/jpeg' }));
});
