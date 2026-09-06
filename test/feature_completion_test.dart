import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icteach/data/pre_assessment_data.dart';
import 'package:icteach/services/content_access_service.dart';
import 'package:icteach/services/report_export_service.dart';
import 'package:icteach/services/session_service.dart';
import 'package:icteach/widgets/content_access_gate.dart';
import 'package:icteach/widgets/leaderboard_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:icteach/admin_login.dart';
import 'package:icteach/login.dart';
import 'package:icteach/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'both login forms expose remember-me without narrow layout errors',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in [const LoginPage(), const AdminLoginPage()]) {
        await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
        await tester.pumpAndSettle();
        expect(find.text('Remember me'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'diagnostic requires all answers and scores each competency independently',
    () {
      expect(() => PreAssessmentData.score([0]), throwsArgumentError);
      expect(
        () => PreAssessmentData.score(List.filled(12, -1)),
        throwsArgumentError,
      );
      final answers = PreAssessmentData.questions.map((q) => q.answer).toList();
      final all = PreAssessmentData.score(answers);
      expect(all['score'], 12);
      expect(all['competencyScores'], {'COC1': 6, 'COC2': 6});
      answers[0] = (answers[0] + 1) % 4;
      final partial = PreAssessmentData.score(answers);
      expect(partial['score'], 11);
      expect(partial['competencyScores'], {'COC1': 5, 'COC2': 6});
    },
  );
  test('legacy placeholder completion does not bypass the diagnostic', () {
    expect(
      PreAssessmentData.isComplete({'completedAt': DateTime.now()}),
      false,
    );
    expect(
      PreAssessmentData.isComplete({
        'completed': true,
        'version': 0,
        'answers': List.filled(12, 0),
      }),
      false,
    );
    expect(
      PreAssessmentData.isComplete({
        'completed': true,
        'version': 1,
        'answers': List.filled(12, 0),
      }),
      true,
    );
  });
  test(
    'locks apply to categories, individual items and legacy practice records',
    () {
      final locks = [
        {'contentType': 'module', 'contentId': '*', 'isLocked': true},
        {'contentType': 'simulation', 'contentId': 'a', 'isLocked': true},
        {'contentType': 'practice', 'contentId': 'q', 'isLocked': true},
      ];
      expect(ContentAccessService.isLocked(locks, 'module', 'any'), true);
      expect(ContentAccessService.isLocked(locks, 'simulation', 'a'), true);
      expect(ContentAccessService.isLocked(locks, 'simulation', 'b'), false);
      expect(ContentAccessService.isLocked(locks, 'quiz', 'q'), true);
      expect(ContentAccessService.isLocked([], 'module', 'a'), false);
    },
  );
  testWidgets('a live lock removes active content and unlock restores it', (
    tester,
  ) async {
    final locks = StreamController<List<Map<String, dynamic>>>();
    addTearDown(locks.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ContentAccessGate(
          classId: 'c',
          contentType: 'simulation',
          contentId: 'a',
          staffLoader: (_) async => false,
          locksLoader: (_) => locks.stream,
          builder: (_) => const Scaffold(body: Text('Active activity')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Active activity'), findsNothing);
    locks.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Active activity'), findsOneWidget);
    locks.add([
      {'contentType': 'simulation', 'contentId': 'a', 'isLocked': true},
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Active activity'), findsNothing);
    expect(find.textContaining('has locked this activity'), findsOneWidget);
    locks.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Active activity'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'access errors fail closed instead of exposing learning content',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentAccessGate(
            classId: 'c',
            contentType: 'module',
            staffLoader: (_) => Future.error(StateError('offline')),
            locksLoader: (_) => const Stream.empty(),
            builder: (_) => const Text('Protected'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Protected'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    },
  );
  test('CSV escapes commas and quotes and neutralizes formula prefixes', () {
    expect(
      ReportExportService.encodeCsv([
        ['A, B', 'Say "hi"', '=1+1', 75],
      ]),
      '"A, B","Say ""hi""","\'=1+1","75"',
    );
  });
  test(
    'remember-me preference is persisted without storing passwords',
    () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SessionService.remembersUser(), true);
      await SessionService.configure(false);
      expect(await SessionService.remembersUser(), false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {SessionService.rememberKey});
    },
  );
  testWidgets(
    'leaderboard fits a narrow screen and keeps a fixed percentage scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardChart(
              entries: [
                {
                  'studentName': 'A learner with a long display name',
                  'percentage': 100,
                },
                {'studentName': 'Another learner', 'percentage': 45},
              ],
            ),
          ),
        ),
      );
      expect(find.text('100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars.map((b) => b.value), [1.0, 0.45]);
    },
  );
}
