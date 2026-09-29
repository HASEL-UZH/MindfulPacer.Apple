# iOS design alignment

The September 2026 design pass continues issue #135 using Athleon’s `Card`, `LabeledCard`, Home dashboard, `ExerciseStatDetailView`, and `OnboardingStepView` as references. The feedback pass removes unnecessary card containers from Analytics, Outreach, and onboarding. The existing Reflections and Reminders lists remain the baseline for list interactions.

## Shared conventions

- Dashboard content sits on `systemGroupedBackground`, with `secondarySystemGroupedBackground` cards and continuous 24-point corners. Semantic colors support light and dark appearance.
- Card headings use semibold subheadline text, meaningful SF Symbols, and restrained feature colors. `LabeledCard` moves accessories below headings at accessibility text sizes.
- Primary actions use native prominent glass capsules with `.controlSize(.large)` and no extra height or vertical padding inside the label. Native tab, toolbar, and sheet presentation handles the system navigation material; sheets no longer force 16-point corners.
- Outreach uses a plain system background and a 680-point editorial column; onboarding uses a 600-point column with group boxes around expandable setup instructions and the disclaimer acceptance toggle. Home health cards stack for larger text. Small Home cards use 8–10-point internal spacing; widget create actions use their intrinsic label height without an added 44-point frame.
- Onboarding and reflection selection follow Athleon’s `SelectableButton`, `SingleSelectRow`, and `CapsuleSelectableButton`: 16-point content padding, 20-point corners, 12-point gaps, and a persistent checkmark slot. Custom controls have a 44-point minimum target and grow with their content. At accessibility sizes, checkmarks and Settings icons move onto separate lines so labels retain the full available width. Compact chart choices use native large capsules.
- Navigation, creation, reading, and sharing actions are separate controls. Avoid putting buttons, menus, or links inside a parent button or navigation link.

## Updated surfaces

| Surface | Changes |
| --- | --- |
| Home | Compact illustrated empty states; tightly spaced, separate history and create actions; readable metric headers and timestamps; adaptive health-card layout. |
| Analytics | Visible measurement selector; heart rate first; date and create toolbar actions; full-width chart above a separately scrolling reflections area with compact horizontal selection capsules; period selection remains available without health data. |
| Charts | Heart-rate lower bound uses visible minimum minus 10 bpm (clamped at zero); area fill starts at the visible baseline; step bars retain a zero baseline. |
| Date selection | Calendar edits are local until Done; Cancel preserves the previously selected date. |
| Outreach and articles | Editorial lead article, compact secondary article rows, flat community/resource links, and loading/empty/retry states. The complete articles list retains separate read/share actions. |
| Roadmap and release notes | Native list sections and rows, readable status text, native dismissal, and roadmap recovery states. |
| Onboarding and reminder introduction | Focused symbol/title steps, plain feature rows, Athleon selectable rows, grouped expandable setup instructions, prominent capsule actions, and a grouped native acceptance toggle. Each scroll view owns a bottom safe-area inset for its action bar. Full permission and disclaimer text remains available. |
| Reflection entry | The date row stacks when its controls need more room. Adaptive form rows open selection sheets for activities, subactivities, mood, and well-being. Activities and symptom values use shared selectable rows; mood uses scalable circular buttons. Optional selections can be cleared by selecting them again. |
| Settings and information | Native lists and checkmarked selection rows, explicit Color.primary/Color.secondary for row labels and button subtitles, native sheet geometry, selection traits, and contained sponsor logos. Apple Watch setup and supporting information screens also use native list rows. |

New copy is translated into German, French, Italian, and Spanish in the shared string catalog.

## Validation

`StatChartScaleTests` covers heart-rate padding, constant readings, a zero step baseline, and missing/nonfinite data. `RedesignNavigationTests` exercises Home creation, Analytics measurement/period/date navigation, Outreach articles, reminder dismissal, supporting sheets, dark appearance, and accessibility text size. Onboarding checks cover device selection and mandatory disclaimer acceptance. Selection-flow checks exercise reminder choices, Continue gating, and reflection selection sheets. `AnalyticsPresentationTests` exercises selection persistence/deletion with an in-memory store and captures populated heart-rate/step charts. Screenshots are retained as XCTest attachments.

Run the focused checks with:

```sh
xcodebuild \
  -project MindfulPacer/MindfulPacer.xcodeproj \
  -scheme 'iOS Prod' \
  -configuration Debug-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO \
  -only-testing:iOSTests/StatChartScaleTests \
  -only-testing:iOSTests/AnalyticsPresentationTests \
  -only-testing:iOSUITests/RedesignNavigationTests \
  CODE_SIGN_IDENTITY=- IPHONEOS_DEPLOYMENT_TARGET=27.0 test
```

The command explicitly aligns the older test-target deployment setting with the app’s iOS 27 target. Simulator signing is needed for the app’s existing CloudKit entitlements. The `iOS Prod` scheme is used because the existing `iOS Dev` scheme names the Watch app as its launch executable.

The dated notes below describe the initial iOS presentation passes. The branch now also includes the Watch redesign and threshold highlights, the expanded architecture guide, and isolated screenshot fixtures for both platforms. The final screenshot catalog uses populated synthetic data as well as empty and recovery states.

### Results, 22 September 2026

- Xcode 27 simulator build succeeded.
- All 10 focused tests passed: four scale tests, one populated Analytics presentation test, and five UI flows. Additional checks covered the final Outreach/accessibility refinements.
- Reviewed the feedback pass on iPhone 18 Pro, including dark appearance at the largest accessibility text size, populated charts, and every onboarding step. The initial pass also covered iPhone 17e.
- A supporting-screen run on iPhone 17e stalled in the existing synchronous HealthKit permission query. Its process sample showed a wait for the simulator HealthKit service. The same flow passed on iPhone 18 Pro after fixing a test locator to match the Settings row’s combined title/subtitle accessibility label.
- Validated all 23 translatable new catalog entries in de/fr/it/es (the community proper name is marked untranslatable) and confirmed existing translations were preserved. `git diff --check` passed.

### Selection and button sizing follow-up

The selection pass reuses Athleon’s onboarding/button patterns for device and mode choices, reminder measurement/strength/interval, Settings appearance/device choices, and reflection entry. Reflection form rows now open the corresponding selection sheets. Native action buttons no longer combine large control sizing with extra label height or padding. Analytics uses compact horizontal capsules and keeps the selected reflection’s edit action below them.

The main run passed all eight checks (seven UI flows and the populated Analytics presentation check). Targeted follow-up checks passed for compact Analytics capsules, reflection selection/clearing, and dark appearance at the largest accessibility size in Settings and onboarding. The final screenshots verify adaptive date layout and full-width labels at accessibility sizes. Screenshots are retained in the result bundles. UI flows start in iPhone-only mode to isolate them from previously saved onboarding selections; a simulator run in Watch mode stalled in the existing synchronous HealthKit permission query.

### Feedback follow-up, 24 September 2026

Onboarding action bars are inset into each page’s scroll view, so the final content can scroll fully clear of the button. Disclaimer acceptance lives in a group box in the scrollable content; setup disclosure groups also use group boxes. Settings selection surfaces, Apple Watch setup, release notes, and roadmap use native lists rather than selectable cards. Home restores illustrated reflection/reminder empty states with compact typography and removes the extra fixed height from create actions.

Five focused UI tests passed on iPhone 18 Pro / iOS 27, including a geometric assertion that the final onboarding content sits at least 12 points above the action at normal and largest accessibility sizes. The acceptance gate remains enforced. Widget creation, Settings navigation, and supporting sheets are covered as well. Both widget creation/supporting-screen tests passed again after the final compact empty-state adjustment.
