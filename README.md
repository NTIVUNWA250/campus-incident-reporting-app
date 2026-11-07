# Campus Care

A Flutter mobile app for ALU campus incident reporting. Students submit and
track private reports. Authorized campus staff review the campus queue and
advance reports from Submitted to In Progress to Resolved.

## Run locally without a billing account

Requirements: Flutter 3.41.9 / Dart 3.11.5, Node.js 22 or newer, Java 21,
and a working Android SDK/emulator. Check the mobile toolchain with
`flutter doctor`. Set `JAVA_HOME` to Java 21 before starting Firebase tools.

```sh
flutter pub get
npm ci
npm run emulators
```

Keep that terminal running. In another terminal, start an Android emulator,
then run:

```sh
npm run seed
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

The app connects to host 10.0.2.2 from the Android emulator. Services run on
ports 9099 (Auth), 8088 (Firestore) and 9199 (Storage). The Emulator UI is at
http://127.0.0.1:4000. Local state is exported into the ignored .firebase
directory when the emulators stop normally.

Local-only seeded accounts:

| Role | Email | Password |
| --- | --- | --- |
| Student | student@alustudent.com | CampusCare123! |
| Staff | staff@alueducation.com | CampusCare123! |

The seed script is restricted to localhost and project demo-campus-care.
These are development fixtures, not real accounts. Emulator verification
links simulate email delivery. Do not use emulator credentials in a real
Firebase project.

For an iOS simulator, pass `--dart-define=EMULATOR_HOST=127.0.0.1` as well.
iOS configuration is included but has not been built or verified on this
Windows development machine.

## Connect a hosted Firebase project

Android is now configured for project `campus-incident-e183e` using
lib/firebase_options.dart. Email/Password authentication is enabled and the
Standard Firestore database in us-central1 has its free tier enabled. The
repository rules and index have been deployed. Normal `flutter run` uses
this hosted project; the emulator flag still selects the isolated local demo.
Initialization uses explicit Dart options so local emulator configuration is
not overridden by Android's automatic Google Services initialization.

1. Register the Android application ID `com.ntivunwa.campus_care` in the
   chosen Firebase project and enable Email/Password authentication.
2. Create Cloud Firestore in production mode and configure Firebase Storage.
3. Copy config/firebase.example.json to config/firebase.json and enter that
   platform's actual Firebase application settings. The local file is ignored.
4. Deploy the rules and indexes to the explicit, chosen project:

```sh
firebase deploy --project YOUR_PROJECT_ID --only firestore,storage
flutter run --dart-define-from-file=config/firebase.json
```

Hosted Firebase Storage requires a Blaze billing account. The hosted project
remains on Spark and no billing has been enabled. Its Storage bucket is not
provisioned; a bucket identifier in the configuration does not create one.
Hosted photo uploads remain unavailable until Storage is provisioned.
Free local emulators
provide all three services for development; they do not establish acceptance
of emulator-only assessment evidence. Check the course requirements before
using local evidence for submission.

Staff access is a trusted custom claim, never a client-selectable role.
Using an authorized administrator's Application Default Credentials outside
the repository, grant a verified ALU account access with:

```sh
node scripts/set-staff.mjs YOUR_PROJECT_ID USER_UID grant
```

Use `revoke` instead of `grant` to remove staff access, then refresh the app
session. Never include administrator credentials in the mobile app or Git.

## Implementation

- lib/models: incident categories, statuses, records and timestamped history.
- lib/data: repository abstraction and Firebase CRUD/photo/transaction logic.
- lib/state: Provider ChangeNotifier session and report controllers.
- lib/screens and lib/widgets: forms, navigation, dashboard, filters and details.
- firestore.rules / storage.rules: verified ALU identity, ownership, staff
  transitions, schema validation and attachment permissions.

Students can edit or delete their own Submitted reports. Once staff begin
work, report content and history are preserved. Photos are optional JPEG or
PNG files up to 5 MB. Search and summary counts cover loaded records; older
records can be loaded in steps of 100. The app does not contain hardcoded
incident data; optional sample records live only in the emulator seed script.

All project text uses ASCII characters. Icons are Flutter Material icons;
binary images and build outputs are not interpreted as text.

## Verification

```sh
flutter analyze
flutter test
npm run test:rules
npm run check:ascii
flutter build apk --debug --dart-define=USE_FIREBASE_EMULATORS=true
```

Observed results: 9 Flutter unit/widget tests and 19 Firebase rules tests
pass. Formatting, analysis, ASCII checks and Android APK builds pass. Actual
Android runs exercised registration, verification simulation, report CRUD,
Storage upload/read and staff progression to Resolved with preserved history.
The complete automated mobile scenario in integration_test still has
Windows VM-service/native keyboard timing failures and is not counted as a
passing suite. Do not infer its success from the APK build or the unit tests.

To enable the local ASCII commit hook after cloning:

```sh
git config core.hooksPath .githooks
```

The technical report, screenshots, demonstration script and submission plan
are maintained outside this repository.
