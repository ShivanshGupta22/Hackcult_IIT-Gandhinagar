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
