<<<<<<< HEAD
# LiFE Mitra Gujarat — Flutter frontend (HC26-GEDA01)

Mission LiFE citizen app (Android/iOS) **+** GEDA admin portal (Flutter Web) in one codebase.
Built from `mission_life_docs/` (PRD/TRD/UI-UX) and `DESIGN.md` tokens.

## Quick start
```bash
flutter pub get
flutter run                          # mobile app (emulator / device)
flutter run -d chrome --web-port 8080 # admin portal → open /#/admin/login
```
Flutter 3.47+ / Dart 3.13+. `flutter analyze` → 0 issues · `flutter test` → 12 tests (calculators + full route smoke tests).

### Demo accounts (mock auth — swap for Firebase Auth later)
| Role | Email | Password |
|---|---|---|
| Citizen (seeded history) | `nisha@demo.com` | `Demo@1234` |
| GEDA admin | `admin@geda.demo` | `Admin@1234` |

Sign-up with any new email → onboarding wizard → baseline result → join community → home.
Any `@geda.gujarat.gov.in` e-mail or "Continue with Google Workspace" on `/admin/login` becomes an admin.
Login is **Email + Password and Google only** (no phone/OTP), as per the PRD.

## Structure
```
lib/
  main.dart, app.dart              # bootstrap, MaterialApp.router, AppScope
  router/app_router.dart           # GoRouter + auth/onboarding/admin redirects
  core/theme/app_theme.dart        # DESIGN.md tokens → ThemeData (Plus Jakarta Sans + Inter)
  core/widgets/widgets.dart        # design-system widgets (buttons, cards, TaskCard, NudgeCard, gauges…)
  core/logic/calculators.dart      # footprint, solar subsidy (PM Surya Ghar + Gujarat state), levels
  core/utils/formatters.dart       # ₹ Indian grouping, kg, units, dates
  data/models.dart                 # AppUser, TaskItem, FootprintEntry, Community, Lead …
  data/mock_data.dart              # tasks, badges, communities, vendors, schemes, admin metrics
  data/app_state.dart              # ChangeNotifier "backend" (replace with Firebase repos)
  features/
    auth/          splash, login, sign-up, forgot password (en/gu toggle)
    onboarding/    5-step wizard + baseline result
    home/          MainShell (bottom nav), Home, task completion flow, nudges
    impact/        trend/pie charts (fl_chart), add-month with bill photo
    community/     community, podium leaderboard, join/create, goal detail
    hub/           solar calculator + result, vendors, scheme pages
    profile/       profile, badges, points ledger, edit profile, notification settings
    admin/         web login (pixel-matched to design), shell, overview, leads, content, campaigns
test/                              # calculators_test, widget_test, flow_test
```

## Routes
Citizen: `/login /signup /forgot /onboarding/1..5 /onboarding/result /home /impact /impact/add-month
/community /community/join /community/goals/:id /hub /hub/solar /hub/solar/result/:id /hub/vendors
/hub/schemes/:id /profile /profile/notifications`
Admin: `/admin/login /admin /admin/leads /admin/content /admin/campaigns`

## Wiring Firebase (next step)
`AppState` is the single integration seam: replace the in-memory maps with
`firebase_auth` (email/password + Google), Cloud Firestore repos per `backendschema.md`, and
Cloud Functions for point awards/verification. UI code does not need to change.

## Branding
- `assets/images/logo.png` — app logo (used by splash screen, login header, web rail).
- Android launcher: `mipmap-*/ic_launcher.png` + adaptive icon (`mipmap-anydpi-v26`), native splash via
  `drawable*/launch_background.xml` (+ `drawable-*/splash_logo.png`).
- Web: `web/favicon.png`, `web/icons/*`, HTML loading splash in `web/index.html` (fades on first frame).

## Navigation rules (avoid black screens)
- GoRouter listens to `AppState.authChanges` only (sign-in / sign-out / onboarding), not every data change.
- Use `context.safePop('/tab')` or `SafeBackButton(fallback:)` on pushed pages — pops if possible, else
  jumps to the fallback (needed after deep links / browser refresh).
- In dialogs/sheets always pop with the **dialog's** context (`builder: (ctx) => … Navigator.pop(ctx)`).
- Shells (`MainShell`, `AdminShell`) render nothing while no user is signed in.

## Notes
- Fonts load via `google_fonts` at runtime; bundle TTFs under `assets/fonts/` for offline builds.
- Android applicationId: `gov.gujarat.geda.lifemitra`. iOS/macOS folders can be generated with
  `flutter create --platforms=ios .` on a Mac.
=======
# Hackcult_IIT_Gandhinagar

# Hackathon Project Details

## 1. Hackathon Information
- **Hackathon Name:**
- **Organized By:**
- **College / University:**
- **Theme / Domain:**
- **Problem Statement ID (if any):**

## 2. Project Information
- **Project Name:**
- **Project Tagline:**
- **Problem Statement:**
- **Proposed Solution:**
- **Target Users:**
- **What makes our project unique?**

## 3. Features
- **Main Features:**
- **AI / ML Features (if any):**
- **Other Special Features:**

## 4. Technology Stack
- **Frontend:**
- **Backend:**
- **Database:**
- **AI / APIs / Other Tools:**

## 5. Project Status
- **Current Status:** (Idea / Prototype / Partially Working / Fully Working)
- **Live Demo Link:**
- **GitHub Repository Link:**
- **Demo Video Link:** (if available)

## 6. Team Details
- **Team Name:**
- **Team Leader:**
- **Team Members:**
- **College / University:**

## 7. Additional Information
- **Future Scope:**
- **Special Instructions from Hackathon Organizers:**
- **Anything else to include:**
>>>>>>> 38ae5d7cb8a2d50bcc1834ae8c3b4499743eebe2
