# Refactor validation

format=0
bundle=0
runtime=0
analyze=1
test=1

## analyze failure tail
```
Resolving dependencies...
Downloading packages...
  cli_util 0.4.2 (0.5.1 available)
  hooks 2.0.2 (2.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.19.0 available)
  package_config 2.2.0 (3.0.0 available)
  record_use 0.6.0 (1.0.0 available)
  share_plus 10.1.4 (13.2.1 available)
  share_plus_platform_interface 5.0.2 (7.1.0 available)
  shared_preferences_android 2.4.26 (2.4.27 available)
  test_api 0.7.11 (0.7.13 available)
  uuid 4.5.3 (4.6.0 available)
  vector_math 2.2.0 (2.4.0 available)
  win32 5.15.0 (6.3.0 available)
Got dependencies!
13 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing hee_no_tane...                                        

   info • Use an initializing formal to assign a parameter to a field. Try using an initialing formal ('this._saveRepository') to initialize the field • lib/application/daily_progress_service.dart:26:8 • prefer_initializing_formals
   info • Use an initializing formal to assign a parameter to a field. Try using an initialing formal ('this._rewardService') to initialize the field • lib/application/daily_progress_service.dart:27:8 • prefer_initializing_formals

2 issues found. (ran in 12.6s)
```

## test failure tail
```
#11     main.<anonymous closure>.<anonymous closure> (file:///home/runner/work/hee_no_tane/hee_no_tane/test/features/card_collection_stale_data_test.dart:393:7)
<asynchronous suspension>
#12     Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:253:15)
<asynchronous suspension>
#13     Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:250:11)
<asynchronous suspension>
#14     Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:318:9)
<asynchronous suspension>
(elided one frame from package:stack_trace)
00:32 +98: loading /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart
00:33 +98: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: SaveData onboarding migration new save data starts with onboarding incomplete
00:33 +99: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: SaveData onboarding migration onboarding completion survives JSON round-trip
00:33 +100: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: SaveData onboarding migration legacy save with user progress is treated as completed
00:33 +101: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: SaveData onboarding migration legacy empty save remains incomplete
00:33 +102: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: first-run onboarding shows onboarding for an incomplete save
00:33 +103: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: first-run onboarding shows home immediately for a completed save
00:34 +104: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: first-run onboarding completes all pages, persists, and opens home
00:34 +105: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: first-run onboarding prevents duplicate completion while saving
00:34 +106: /home/runner/work/hee_no_tane/hee_no_tane/test/features/onboarding_screen_test.dart: first-run onboarding stays on onboarding and shows an error when saving fails
00:34 +107: loading /home/runner/work/hee_no_tane/hee_no_tane/test/features/startup_error_screen_test.dart
00:35 +107: /home/runner/work/hee_no_tane/hee_no_tane/test/features/startup_error_screen_test.dart: uses the system dark theme during startup failure
00:35 +108: /home/runner/work/hee_no_tane/hee_no_tane/test/features/startup_error_screen_test.dart: shows a safe concrete failure detail
00:35 +109: loading /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart
00:36 +109: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R1. unowned card answer grants card and saves date
00:37 +110: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R2. already owned card still saves date and stats
00:37 +111: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R3. null relatedCard still marks as answered
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: <1>
  Actual: <0>

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart:210:5)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart line 210
The test description was:
  R3. null relatedCard still marks as answered
════════════════════════════════════════════════════════════════════════════════════════════════════
00:37 +111 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R3. null relatedCard still marks as answered [E]
  Test failed. See exception logs above.
  The test description was: R3. null relatedCard still marks as answered
  
00:37 +111 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R4. cannot answer again on same day via home
00:38 +112 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R5. card to read opens CardDetailScreen
00:38 +113 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R6. answer persists through SaveRepository and survives app restart
00:38 +114 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R7. unowned card content stays hidden
00:38 +115 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: A. save-in-progress A1. double answer prevented during save
00:38 +116 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: A. save-in-progress A2. home navigation blocked during save
00:38 +117 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: A. save-in-progress A3. system back prevented during save
00:38 +118 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: A. save-in-progress A4. card detail navigation blocked during save
00:38 +119 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: A. save-in-progress A5. navigation enabled after save succeeds
00:38 +120 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: B. save failure B1. save failure detected - not marked as succeeded
00:38 +121 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: B. save failure B2. retry succeeds after failure
00:39 +122 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: B. save failure B3. retry data is idempotent - no double counting
00:39 +123 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: D. system back before answering D1. system back allowed before selecting an answer
00:39 +124 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: C. card missing on home C1. inconsistent completion without its card shows a recoverable error
00:39 +125 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: C. card missing on home C2. system back during save error - no pop
00:39 +126 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: C. card missing on home C3. system back after save success - pop allowed
00:39 +127 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: E. home refresh after quiz E1. system back after save success refreshes home
00:39 +128 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: E. home refresh after quiz E2. AppBar back after save success refreshes home
00:39 +129 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: E. home refresh after quiz E3. back before answering keeps unanswered state
00:39 +130 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: E. home refresh after quiz E4. home button after save success refreshes home
00:40 +131 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: F. card detail save failure F1. save failure does not crash card detail
Failed to save card view stats: SaveException: 保存に失敗しました (cause: null)
#4      FakeSaveRepository.failSave (file:///home/runner/work/hee_no_tane/hee_no_tane/test/helpers/fake_save_repository.dart:71:17)
#5      main.<anonymous closure>.<anonymous closure> (file:///home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart:927:19)
#7      main.<anonymous closure>.<anonymous closure> (file:///home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart:915:7)
#8      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
#10     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:189:25)
#11     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:19)
#13     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1941:5)
#16     TestWidgetsFlutterBinding._runTest (package:flutter_test/src/binding.dart:1926:10)
#17     AutomatedTestWidgetsFlutterBinding.runTest.<anonymous closure> (package:flutter_test/src/binding.dart:2489:24)
#18     FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:182:47)
#23     withClock (package:clock/src/default.dart:52:10)
#24     FakeAsync.run.<anonymous closure> (package:fake_async/fake_async.dart:182:15)
#29     FakeAsync.run (package:fake_async/fake_async.dart:181:52)
#30     AutomatedTestWidgetsFlutterBinding.runTest (package:flutter_test/src/binding.dart:2486:15)
#31     testWidgets.<anonymous closure> (package:flutter_test/src/widget_tester.dart:184:24)
#32     Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:253:25)
#34     Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:252:15)
#39     Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:250:17)
#40     Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:318:17)
#45     Invoker._waitForOutstandingCallbacks (package:test_api/src/backend/invoker.dart:314:5)
#46     Invoker._onRun.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart:457:21)
#48     Invoker._onRun.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart:455:15)
#53     Invoker._onRun.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart:445:11)
#54     Invoker._guardIfGuarded (package:test_api/src/backend/invoker.dart:500:15)
#55     Invoker._onRun.<anonymous closure> (package:test_api/src/backend/invoker.dart:444:9)
#62     Invoker._onRun (package:test_api/src/backend/invoker.dart:442:11)
#63     LiveTestController.run (package:test_api/src/backend/live_test_controller.dart:161:11)
#64     RemoteListener._runLiveTest.<anonymous closure> (package:test_api/src/backend/remote_listener.dart:323:16)
#69     RemoteListener._runLiveTest (package:test_api/src/backend/remote_listener.dart:322:5)
#70     RemoteListener._serializeTest.<anonymous closure> (package:test_api/src/backend/remote_listener.dart:263:7)
#88     _GuaranteeSink.add (package:stream_channel/src/guarantee_channel.dart:125:12)
#89     new _MultiChannel.<anonymous closure> (package:stream_channel/src/multi_channel.dart:159:31)
#91     CastStreamSubscription._onData (dart:_internal/async_cast.dart:95:11)
#117    new _WebSocketImpl._fromSocket.<anonymous closure> (dart:_http/websocket_impl.dart:1252:27)
#123    _WebSocketProtocolTransformer._messageFrameEnd (dart:_http/websocket_impl.dart:348:23)
#124    _WebSocketProtocolTransformer.add (dart:_http/websocket_impl.dart:238:46)
#132    _Socket._onData (dart:io-patch/socket_patch.dart:2874:41)
#139    new _RawSocket.<anonymous closure> (dart:io-patch/socket_patch.dart:2312:31)
#140    _NativeSocket.issueReadEvent.issue (dart:io-patch/socket_patch.dart:1647:14)
(elided 103 frames from dart:async and package:stack_trace)
00:40 +132 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: F. card detail save failure F2. save success on card detail works normally
00:40 +133 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/monkey_test.dart
00:41 +133 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/monkey_test.dart: monkey test: random taps and drags do not crash the app
00:42 +134 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/application/daily_progress_service_test.dart
00:42 +134 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/application/daily_progress_service_test.dart: daily assignment is persisted and cannot change on the same date
00:42 +135 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/application/daily_progress_service_test.dart: daily answer update is idempotent and keeps assignment identity
00:42 +136 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/application/daily_progress_service_test.dart: version 3 completion fields migrate into the assignment fields
00:42 +137 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_duplicate_semantics_test.dart
00:43 +137 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_duplicate_semantics_test.dart: similar question wording does not merge different facts
00:43 +138 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_duplicate_semantics_test.dart: different question phrasing still links the same fact
00:43 +139 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_atomic_write_test.dart
00:44 +139 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_atomic_write_test.dart: two-file write restores both originals when the second install fails
00:44 +140 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart
00:44 +140 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart: (setUpAll)
00:44 +140 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart: same answer alone does not make unrelated facts duplicates
00:44 +141 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart: all three octopus-heart questions remain duplicate candidates
00:44 +142 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart: strawberry fruit-structure questions remain duplicate candidates
00:44 +143 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart: sandwich-origin questions remain duplicate candidates
00:44 +144 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart: real data duplicate edges remain the five known pairs
00:44 +145 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_real_data_test.dart: (tearDownAll)
00:44 +145 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart
00:45 +145 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: export covers all reviewable claims and quotes CSV safely
00:45 +146 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: an unchanged exported pending CSV produces no JSON diff
00:45 +147 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: approved source and visual review are applied to the pair
00:45 +148 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: approved source without required evidence is rejected
00:45 +149 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: changed immutable content and stale content hashes are rejected
00:45 +150 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: invalid CSV never changes either JSON file
00:45 +151 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: dry-run reports changes without writing files
00:45 +152 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: category progress counts only release-approved pairs
00:45 +153 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_review_workflow_test.dart: risk extraction scans distractors as well as the correct answer
00:45 +154 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart
00:46 +154 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart: enhanced review CSV adds immutable image asset and imageFit
00:46 +155 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart: invalid image fit and changed image asset are rejected
00:46 +156 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart: current facts are not current roles without office language
00:46 +157 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart: current roles require time and office language
00:46 +158 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart: animal anatomy is separate from human health
00:46 +159 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart: currency history is separate from financial advice
00:46 +160 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/content_review/content_risk_classifier_test.dart: duplicate facts link the other question IDs
00:46 +161 -1: loading /home/runner/work/hee_no_tane/hee_no_tane/test/data/save_repository_update_test.dart
00:46 +161 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/data/save_repository_update_test.dart: SaveRepository.update U1. concurrent updates run FIFO and preserve both changes
00:47 +162 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/data/save_repository_update_test.dart: SaveRepository.update U2. card view and daily answer updates both survive
00:47 +163 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/data/save_repository_update_test.dart: SaveRepository.update U3. load failure skips save
00:47 +164 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/data/save_repository_update_test.dart: SaveRepository.update U4. updater failure skips save
00:47 +165 -1: /home/runner/work/hee_no_tane/hee_no_tane/test/data/save_repository_update_test.dart: SaveRepository.update U5. save failure does not block a later update
00:47 +166 -1: Some tests failed.

Failing tests:
  /home/runner/work/hee_no_tane/hee_no_tane/test/features/daily_question_screen_test.dart: R3. null relatedCard still marks as answered
```
