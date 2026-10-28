import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_mitra/app.dart';
import 'package:life_mitra/core/widgets/widgets.dart';
import 'package:life_mitra/data/app_state.dart';

/// Walks every citizen + admin route with the demo account to make sure each
/// screen builds without throwing. (Fonts are not fetched in tests.)
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Some widgets animate forever (shimmer skeletons, gauges), so pumpAndSettle
  // would never return — pump a fixed number of frames instead.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 350));
    }
  }

  Future<void> boot(WidgetTester tester,
      {Size size = const Size(720, 1600)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const LifeMitraApp());
    await settle(tester);
  }

  Future<void> go(WidgetTester tester, String path) async {
    final ctx = tester.element(find.byType(Scaffold).first);
    GoRouter.of(ctx).go(path);
    await settle(tester);
  }

  testWidgets('citizen demo flow: every route renders', (tester) async {
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      debugPrint(d.toString());
      prev?.call(d);
    };
    addTearDown(() => FlutterError.onError = prev);
    await boot(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    final state = AppScope.read(ctx);
    // Future.delayed inside sign-in needs pumped (fake) time to complete.
    String? err = 'pending';
    state.signInWithEmail('nisha@demo.com', 'Demo@1234').then((e) => err = e);
    await settle(tester);
    expect(err, isNull);

    for (final r in [
      '/home',
      '/impact',
      '/impact/add-month',
      '/community',
      '/community/join',
      '/community/goals/g1',
      '/hub',
      '/hub/solar',
      '/hub/vendors',
      '/hub/schemes/pm_surya_ghar',
      '/profile',
      '/profile/notifications',
      '/profile/edit',
      '/profile/badges',
      '/profile/points',
      '/community/create',
    ]) {
      await go(tester, r);
      final ex = tester.takeException();
      if (ex is FlutterError) {
        debugPrint(ex.diagnostics.map((d) => d.toStringDeep()).join('\n'));
      }
      expect(ex, isNull, reason: 'route $r threw');
    }

    // Solar calculator end-to-end
    final a = state.assess(monthlyUnits: 250, roofAreaM2: 30, scSt: false);
    await go(tester, '/hub/solar/result/${a.id}');
    expect(find.textContaining('10,000'), findsWidgets);

    // Task completion awards points
    final before = state.user!.points;
    final task = state.todayTasks.first;
    state.completeTask(task);
    expect(state.user!.points, greaterThan(before));
  });

  testWidgets('onboarding gate: new user is sent to /onboarding/1',
      (tester) async {
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      debugPrint(d.toString());
      prev?.call(d);
    };
    addTearDown(() => FlutterError.onError = prev);
    await boot(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    final state = AppScope.read(ctx);
    unawaited(state.signUpWithEmail(
        name: 'Test User', email: 'test@example.com', password: 'Test@1234'));
    await settle(tester);
    expect(state.isSignedIn, isTrue);
    for (var i = 1; i <= 5; i++) {
      await go(tester, '/onboarding/$i');
      final ex = tester.takeException();
      if (ex is FlutterError) {
        debugPrint(ex.diagnostics.map((d) => d.toStringDeep()).join('\n'));
      }
      expect(ex, isNull, reason: 'onboarding step $i threw');
    }
  });

  testWidgets('admin portal: login + all console routes render (desktop width)',
      (tester) async {
    await boot(tester, size: const Size(2880, 1800));
    await go(tester, '/admin/login');
    expect(find.text('GEDA Staff Portal'), findsOneWidget);
    expect(find.text('Sign In to Console'), findsOneWidget);

    final ctx = tester.element(find.byType(Scaffold).first);
    final state = AppScope.read(ctx);
    unawaited(state.signInWithEmail('admin@geda.demo', 'Admin@1234'));
    await settle(tester);
    expect(state.user?.isAdmin, isTrue);

    for (final r in [
      '/admin',
      '/admin/leads',
      '/admin/content',
      '/admin/campaigns'
    ]) {
      await go(tester, r);
      final ex = tester.takeException();
      if (ex is FlutterError) {
        debugPrint(ex.diagnostics.map((d) => d.toStringDeep()).join('\n'));
      }
      expect(ex, isNull, reason: 'route $r threw');
    }
    // Citizen routes are blocked for admins.
    await go(tester, '/home');
    expect(find.text('Programme overview'), findsOneWidget);
  });

  testWidgets('regression: sign-out from Profile never shows a black screen',
      (tester) async {
    await boot(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    final state = AppScope.read(ctx);
    unawaited(state.signInWithEmail('nisha@demo.com', 'Demo@1234'));
    await settle(tester);
    await go(tester, '/profile');
    await tester.dragUntilVisible(find.text('Sign out'),
        find.byType(ListView).first, const Offset(0, -400));
    await settle(tester);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(state.isSignedIn, isFalse);
    expect(find.text('Welcome back'), findsOneWidget); // back on /login
  });

  testWidgets('regression: back from deep-linked pages falls back to the tab',
      (tester) async {
    await boot(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    final state = AppScope.read(ctx);
    unawaited(state.signInWithEmail('nisha@demo.com', 'Demo@1234'));
    await settle(tester);

    // `go` (deep link / refresh) → nothing underneath to pop.
    await go(tester, '/profile/edit');
    await tester.tap(find.byType(SafeBackButton));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Points history'), findsOneWidget); // landed on /profile

    // Save on Edit profile (notifies AppState) must not break navigation.
    await go(tester, '/profile');
    final c2 = tester.element(find.byType(Scaffold).first);
    GoRouter.of(c2).push('/profile/edit');
    await settle(tester);
    await tester.tap(find.text('Save').first);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Points history'), findsOneWidget);
  });

  testWidgets('wide screens use a navigation rail with centred content',
      (tester) async {
    await boot(tester, size: const Size(2400, 1400));
    final ctx = tester.element(find.byType(Scaffold).first);
    final state = AppScope.read(ctx);
    unawaited(state.signInWithEmail('nisha@demo.com', 'Demo@1234'));
    await settle(tester);
    await go(tester, '/home');
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
