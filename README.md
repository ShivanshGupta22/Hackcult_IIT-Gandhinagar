# LiFE Mitra Gujarat

A Flutter hackathon prototype for Mission LiFE citizens and a GEDA-style admin portal. The prototype demonstrates sustainability tracking, community goals, solar estimates, survey requests, and Firebase-backed data persistence.

## Run locally

```bash
flutter pub get
flutter run
flutter run -d chrome
```

Open `/#/admin/login` in the browser to view the admin portal. Use Flutter 3.47+ and Dart 3.13+.

### Demo mode

When Firebase is not enabled, the app uses local mock accounts:

| Role | Email | Password |
|---|---|---|
| Citizen | `nisha@demo.com` | `Demo@1234` |
| GEDA admin | `admin@geda.demo` | `Admin@1234` |

These are prototype-only credentials. They do not sign in to the deployed Firebase app.

## Firebase prototype

The deployed web prototype is available at [green-energy-fb652.web.app](https://green-energy-fb652.web.app). Firebase Auth and Firestore persist citizen profiles/settings, task status, monthly impact, community goals, solar estimates, and survey requests.

Firebase client configuration is not committed. Copy `firebase-config.example.json` to `firebase-config.json`, add your Firebase **web app API key** locally, and keep the local file untracked. For Android, download `google-services.json` for this app from Firebase Console and place it at `android/app/google-services.json`; it is git-ignored.

```powershell
Copy-Item firebase-config.example.json firebase-config.json
flutter run -d chrome --dart-define-from-file=firebase-config.json
flutter build web --dart-define-from-file=firebase-config.json
```

Firebase client API keys are visible in client apps and compiled web assets; build-time configuration only keeps the key out of the source repository. Restrict the key in Google Cloud Console to the required APIs and app/referrer restrictions. Never put service-account keys or other server secrets in Flutter configuration.

The admin portal requires a Firebase account with the `admin` custom claim. Admins can view saved survey requests and update their status. The Overview, content editing, and campaigns pages explain which prototype functions are not connected rather than presenting demo values as live data.

## Prototype limitations

- Survey requests are saved to the user's account; they are not dispatched to vendors.
- Programme-wide analytics, content publishing, push notifications, and SMS campaigns are not connected.
- Firebase-mode rewards and photo verification are not issued/verified by a trusted server.
- Android and iOS device sign-in/testing are not covered by the deployed web demo.

This is a hackathon prototype, not a production service. Do not enter sensitive personal information.

## Validation

```bash
flutter analyze
flutter test test/flow_test.dart
flutter build web
```

## Project layout

- `lib/data/`: app state, models, and demo data
- `lib/features/`: citizen and admin screens
- `firestore.rules`: Firestore access controls
- `firestore.indexes.json`: Firestore query indexes
- `functions/`: Cloud Functions source (not deployed)
- `test/`: calculator, widget, and flow tests

## Hackathon details

- Hackathon name / organizer: to be filled in by the team
- Team and members: to be filled in by the team
- Problem statement: Mission LiFE sustainability engagement
- Demo: [green-energy-fb652.web.app](https://green-energy-fb652.web.app)
