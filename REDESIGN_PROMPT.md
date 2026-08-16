# KEPR Inspections — Mobile-Web UX Redesign Prompt

Paste this whole file to an implementing agent. It is written against the current
code in this repository. **The mandate is a UX/IA redesign, not a rewrite: every
existing feature, validation rule, RPC call, and persistence behaviour must
survive unchanged.**

---

## 0. Context the implementer must load first

- `CLAUDE.md` (root of this repo) — product invariants. Non-negotiable.
- Design tokens: `lib/constants/colors.dart`, `lib/constants/app_styles.dart`
- Shell widgets: `lib/widgets/kepr_header.dart`, `bottom_nav.dart`, `kepr_button.dart`, `badge.dart`, `kepr_logo.dart`
- Screens: `signin_screen.dart` (1609 L), `inspections_dashboard_screen.dart` (1434 L),
  `inspection_area_screen.dart`, `checklist_item_screen.dart` (969 L),
  `profile_screen.dart`, `property_details_screen.dart`, `camera_capture_screen.dart`,
  `image_annotation_screen.dart`, `signup_screen.dart`, `otp_verification_screen.dart`,
  `create_account_property_details_screen.dart`
- Data/services: `supabase_repository.dart`, `inspection_session.dart`,
  `inspection_draft_storage.dart`, `report_pdf_service.dart`, `service_recommendation.dart`

**Target device: a phone browser.** Design for a 360–430 px viewport first;
scale up gracefully to tablet/desktop with a centred max-width column. Assume
one-handed use, gloves, poor light, patchy 4G, and a user standing in a stairwell.

---

## 1. What is wrong today (the problems to solve)

### 1.1 Information architecture is inverted
`SignInScreen` is doing four unrelated jobs: login form, inspector home,
inspection-type/plan picker, and property picker. `InspectionsDashboardScreen`
is doing three: checklist browser, area editor host, and final submit. The
bottom nav has only **Home** and **Profile**, so "report history" is buried
inside Profile, and "the inspection I'm currently doing" has no stable address.

The user's real mental model is four nouns: **Home · Inspect · Reports · Me.**
The app should be built around those.

### 1.2 Navigation loses the user
- Final submit does `Navigator.pushReplacement(SignInScreen)` — after a
  successful report the inspector is dumped on what looks like a login screen.
  There is no success state, no "view the PDF I just made".
- The header's `Icons.tune` opens a bottom sheet whose entries are
  "Inspection Home / Flat Selection / **Login Page**" — a destructive
  session-clearing action sitting one tap from a routine one, unlabelled as
  destructive.
- `KeprHeader` shows a bell that opens an `AlertDialog` printing "Last login /
  Inspector / Mobile". That is not a notification centre; it is debug output.

### 1.3 The dashboard progress card breaks on a phone
`_buildProgressCard()` is a `Row` with a fixed **120×120** circular indicator
plus an `Expanded` column that contains a 5-chip `Wrap`. At 360 px the chips get
~200 px and wrap into a 5-row ragged block. Five equally-weighted badges
(Completed / Areas / Pending / Checks / Critical Est.) with five different
colours is noise, not a summary.

### 1.4 Everything is 8 px radius, white card, `shadowSm`
There is no visual hierarchy. The progress summary, an area row, an info card,
and the service estimate panel are all the same object. Nothing tells the eye
what matters.

### 1.5 The checklist item screen is a long unstructured scroll
`checklist_item_screen.dart` stacks: category badge → 28 px title → Capture
button → photo chips → severity 4-up grid → separate full-width "No Issues" →
helper text → conditional service card → 3 info cards → notes field, with a
floating action bar that **disappears when the keyboard opens**. The primary
action (severity) sits below a secondary one (camera). "No Issues" — by far the
most common answer — is visually demoted below the four issue levels.

### 1.6 Progressive disclosure is done with `setState` booleans
`_showPropertyFields`, `_showSocietyOptions`, `_showBlockOptions`,
`_showFlatOptions` cause the page to grow and shrink under the user's thumb with
no scroll anchoring. Selecting a society silently mutates the block/flat rows
further down, off-screen.

### 1.7 Validation is punitive and late
`_validateCriticalIssuesForSubmit()` throws a raw `Exception` whose
`toString()` is rendered in a `SnackBar` — the user reads
`Final submit failed: Exception: Technician notes are required...` after
possibly an hour of work, with no link to the offending item. Six distinct
failure modes all funnel into that one transient grey bar.

### 1.8 Long-press-and-hope affordances
Area cards do a full-screen `Navigator.push`, then a manual `_saveDraft()` on
return. Draft-save is invisible: the user has no idea whether their work is on
the device only or on Supabase.

### 1.9 Web-specific gaps
No offline/online indicator despite `connectivity_plus` being a dependency. No
"work in progress, don't close this tab" guard. Refresh recovery exists in
`inspection_draft_storage.dart` but is never surfaced to the user as a
reassurance.

---

## 2. The redesign

### 2.1 New information architecture

```
┌──────────────────────── Persistent shell ───────────────────────┐
│ AppBar: KEPR mark · context title · [sync dot] · [avatar menu]  │
│                                                                 │
│   Tab 1  Home      Tab 2  Inspect     Tab 3  Reports   Tab 4 Me │
└─────────────────────────────────────────────────────────────────┘
```

Replace `enum BottomNavTab { home, profile }` with
`enum AppTab { home, inspect, reports, profile }`. Four items, 56 px tall,
icon + 11 px label, active item coral-filled pill (keep the existing animation
— it is good). This is the single biggest win: history and the active
inspection each get a permanent address.

**Tab 1 — Home (inspector home).** Only shown when authenticated. Contains, top
to bottom:
1. Greeting + date (`Good ${_dayPeriod()}, ${name}` — keep).
2. **Resume card** (elevated, coral left rail) if `InspectionSession.isActive` —
   property name, mode · plan, live `x/y checks` progress bar, "Continue →".
   Today this is a modest white row; it should be the loudest thing on screen.
3. **Start new inspection** — a single primary button that opens the *start
   flow* (§2.3), instead of the current always-visible two-step selector.
4. **This week** strip — 3 stat tiles: inspections submitted, critical issues
   raised, avg. completion. Sourced from the same query as Reports.
5. **Recent reports** — last 3, tappable to the PDF, "See all →" to Tab 3.

**Tab 2 — Inspect (the active inspection).** This is today's
`InspectionsDashboardScreen`, restructured per §2.4. If no inspection is
active, show an empty state with a "Start an inspection" button that routes to
the start flow — never a blank screen.

**Tab 3 — Reports.** Promote report history out of Profile. Full-height list,
search field, filter chips (`All · Flat · Society · Individual`), grouped by
month. Each row: property name, code, inspection type badge, date, and a
trailing PDF icon. Keep both sources — `inspections.full_report_pdf_url` and
`individual_inspections.report_pdf_url` — and keep the existing ID/mobile/name
matching fallbacks in `_loadReportHistory()`.

**Tab 4 — Me.** Identity card, inspector details, last login, connectivity and
sync status, and logout. Logout must move behind a confirm dialog.

### 2.2 Design system upgrade (extend, don't replace)

Keep `AppColors` values — coral `#F85F5A`, navy `#0F172A`, the slate ramp, the
status colours. Add to `app_styles.dart`:

```
Radii    : sm 10 · md 14 · lg 20 · pill 999
Spacing  : 4 8 12 16 20 24 32 (use only these)
Elevation: flat (border only) · raised (shadowSm) · floating (shadowMd)
Surfaces : page = neutral50 · card = white · sunken = neutral100
```

Rules:
- **One elevated element per screen** — the thing the user should act on.
  Everything else is a flat bordered surface.
- Minimum tap target **48×48**; minimum body text **15 px** (current `bodySm`
  at 14 px on `neutral500` fails contrast in daylight — bump secondary text to
  `neutral600`).
- Severity gets one fixed colour token set, used identically on the item screen,
  the area row, the dashboard, and the PDF:
  `no_issue → success` · `low → #65A30D` · `medium → warning` ·
  `high → error` · `critical → crimson #B12B2C`.
  Never use raw `Colors.green` / `Colors.orange` / `Colors.red.shade900` again.
- Colour is never the only signal — pair every severity with an icon and a word.

### 2.3 The start-inspection flow (replaces the stacked `SignInScreen` sections)

Make it an explicit **3-step wizard on its own route**, with a header progress
bar and a persistent bottom `Continue` bar. No `_showX` booleans.

- **Step 1 — What are you inspecting?** The three mode cards (Flat / Society /
  Individual). At 360 px, three cards in a `Row` gives each ~110 px — too tight
  for a 88 px-tall card with icon + title + subtitle. **Stack them vertically as
  full-width rows** (icon left, title + subtitle, radio right). Selecting
  auto-advances.
- **Step 2 — Which plan?** Free / Ad-hoc / Paid as full-width rows with a
  one-line "what you get" and a check count. Ad-hoc must say plainly:
  "You build the checklist yourself — at least one custom check required".
- **Step 3 — Property details.** Mode-dependent, and only the fields that mode
  needs:
  - *Flat*: Society → Block → Flat. Replace the three inline
    `_buildPropertyAutocomplete` dropdowns with **full-screen searchable pickers**
    (tap a row → sheet with a search field and a list). This removes the
    layout-shift problem entirely and is far better on a phone keyboard.
    Downstream selections clear visibly with a toast: "Block and flat cleared".
  - *Society*: society only.
  - *Individual*: property name, owner name, owner mobile.
- **Review bar**: the sticky bottom bar always shows the current choice
  ("Flat · Paid · Green Meadows / B / 402") so the user can verify before
  committing. `Start inspection` is the terminal action.

Login itself stays a separate, clean, single-card screen (it is already fine —
just widen tap targets, add show/hide password, and keep the 460 px max-width).

### 2.4 Inspect tab (the checklist)

Replace the single scrolling `Column` with a `CustomScrollView`:

1. **Sticky summary header** (collapses on scroll to a 56 px bar with just a
   linear progress and `x/y`). Expanded state:
   - Left: `overallProgress` ring, **72 px, not 120** — it is decoration, not
     data.
   - Right: property name, inspection type · plan.
   - Below: a single horizontal progress bar segmented by state, plus **at most
     three** chips: `Pending n` · `Critical n` · `Est. ₹x`. Move
     "Completed / Areas / Checks" into a one-line caption
     ("12 of 48 checks · 6 areas"). The 5-chip `Wrap` goes away.
2. **Filter row** (sticky under the header): search field + chips
   `All · Pending · Critical · Done`. Search already exists in `filteredAreas` —
   keep the logic, add the chips on top of it.
3. **Area list.** Each area is an **expandable card**, not a navigate-away row:
   tapping expands in place to reveal its parameter checks; tapping a check
   opens the item screen. This kills a whole level of navigation and makes
   `_restoreActiveAreaIfNeeded()`'s post-frame `Navigator.push` unnecessary for
   the common case (keep the deep-restore path for refresh recovery). Card shows
   icon, name, `n pending of m`, a thin progress bar, and a critical flag as a
   left rail + icon (not a 2 px red border on an otherwise identical card).
4. **`Add area` / `Add custom check`** becomes a small FAB or an inline dashed
   "＋ Add area" tile at the end of the list — not two competing entry points
   (there are currently three: the search-row `+`, the header `Add area` text
   button, and the full-width button).
5. **Sticky submit bar** at the bottom, above the nav:
   `[ Save draft ✓ synced 12s ago ]  [ Submit & generate report ]`.
   The submit button is **disabled with an inline reason** when validation would
   fail — see §2.6.

### 2.5 Checklist item screen (the highest-value fix)

This is where inspectors spend 90% of their time. Restructure into a **fixed
frame with three zones**:

```
┌ Header  ── area · category · "3 of 12"  · [skip →] ─────────┐
│ Title (20px, 2 lines max)                                   │
├ ZONE 1  VERDICT  (always visible, above the fold) ──────────┤
│  [ ✓ No issue ]  ← full width, first, largest                │
│  [ Low ] [ Medium ] [ High ] [ Critical ]  ← 2×2, 48px tall  │
├ ZONE 2  EVIDENCE (appears only when a severity ≠ no_issue) ──┤
│  Photos: [ 📷 Capture ]  + thumbnail strip (real thumbnails, │
│           not filename Chips — decode photoEvidenceBase64)   │
│  Notes  : textarea, labelled "Required" when high/critical    │
│  Service: shown when high/critical (keep existing card)      │
├ ZONE 3  GUIDANCE (collapsed accordion, default closed) ──────┤
│  Equipment needed · Inspection guidance · Reference           │
└ Sticky action bar ──────────────────────────────────────────┘
  [ Back ]              [ Save & next → ]
```

Specific fixes:
- **`No Issues` first and full-width.** It is the modal answer; it currently
  sits last, below the four issue buttons.
- **The action bar must not vanish with the keyboard.** Current code hides it
  with `if (keyboardInset == 0)`. Instead keep it pinned above the inset and let
  the content scroll behind.
- **Photo chips → thumbnails.** `_photoLabel()` truncating a storage filename to
  25 chars tells an inspector nothing. Show a 64 px thumbnail grid with a delete
  ✕ and an upload state (local-only vs uploaded), because that distinction is
  load-bearing at final submit.
- **Show the upload state honestly.** Today a failed upload produces a snackbar
  saying "saved locally only" and then nothing — and the failure resurfaces
  as a blocking error an hour later at submit. Give each photo a persistent
  badge: `Uploaded ✓` / `On device — retry ↻`, with a working retry.
- **`Save & next`** advances to the next incomplete check in the area without a
  round-trip to the area list. Add `Skip for now` in the header.
- Requirement hints must be present *before* the user tries to submit:
  "High and critical need a photo + notes" appears the moment such a severity is
  picked, next to the fields, not as an `AlertDialog` after the fact.

**Preserve exactly:** photo compulsory only for `high`/`critical`; notes
required for `high`/`critical`; service required for `critical`; photo capture
available at every severity; wall-dampness follows the same severity rule (no
unconditional two-photo requirement); rear camera preferred with front-camera
fallback and the switch control retained.

### 2.6 Validation: move it from "throw at the end" to "guide throughout"

Replace the six `throw Exception(...)` paths in
`_validateCriticalIssuesForSubmit()` with a typed result:

```dart
class SubmitBlocker {
  final String title;      // "Notes missing"
  final String detail;     // "3 high/critical checks need technician notes"
  final List<String> itemIds; // deep-link targets
}
List<SubmitBlocker> validateForSubmit();
```

- The submit bar shows a live count: `2 issues to fix before submitting`.
- Tapping it opens a **pre-submit checklist sheet** listing each blocker with an
  affected-item count and a `Fix →` that navigates straight to the item.
- Keep every existing rule and message text, including the ad-hoc "add at least
  one custom check", the `_isValidPublicUrl()` host check, and the
  five-completed-checks minimum for non-ad-hoc. **Do not add back the removed
  "five checks" rule for ad-hoc.**

### 2.7 Submission and the success state

Today: PDF → upload → RPC → snackbar → `pushReplacement(SignInScreen)`. Replace
the tail with a **full-screen result page**:
- Progress steps while working: `Generating PDF · Uploading · Saving report`
  (three real states — the user currently stares at a spinner for 10–30 s).
- On success: green check, property name, inspection code, health score,
  critical-issue count, and three actions:
  `[ View PDF ]  [ Share link ]  [ Done → Home ]`.
- On failure: which step failed, the underlying message, and a **Retry** that
  does not lose the draft. Critically, if the PDF uploaded but the RPC failed,
  say so and retry only the RPC — the current code makes the user redo everything.

### 2.8 Web/PWA specifics (this is a phone *website*)

- **Connectivity banner** using the already-present `connectivity_plus`: a thin
  amber bar "Offline — work is saved on this device" and a green "Back online —
  syncing" transient.
- **Sync indicator** in the app bar: a dot with three states (synced / pending /
  offline) plus "last saved 12s ago". `_saveDraft()` writes to both
  SharedPreferences and Supabase — surface which one succeeded.
- **`beforeunload` guard** when an inspection has unsaved changes.
- **Safe-area + browser chrome**: bottom nav must sit above iOS Safari's toolbar;
  use `MediaQuery.viewPaddingOf` and avoid `Positioned(bottom: 0)` inside a
  `Stack` for the nav — use `Scaffold.bottomNavigationBar` consistently
  (`inspections_dashboard_screen.dart` and `profile_screen.dart` currently use
  the `Stack` approach, `signin_screen.dart` uses the correct one).
- **Camera on web**: keep `camera` package behaviour, but add a clear permission-
  denied state with instructions, since a browser permission prompt is easy to
  dismiss accidentally.
- **Scroll restoration**: returning from an item must land on that item, not the
  top of the list.
- Respect `prefers-reduced-motion`; keep animations ≤ 200 ms.

### 2.9 Accessibility

- Semantics labels on every icon-only button (the header's bell and `tune` have
  none).
- Text scales to 200% without clipping — the fixed-height 88 px mode cards and
  the 46 px severity button will break; use `IntrinsicHeight` / min-height.
- Focus order follows visual order; every interactive element reachable by
  keyboard (this is a website).
- Contrast ≥ 4.5:1 for body text. `neutral400` on white and
  `neutral300` hint text currently fail.

---

## 3. Feature preservation checklist — nothing here may be lost

Auth & session: mobile+password login · session restore & expiry
(`hasFreshInspectorSession`) · `clearInspectorAuth` on stale token · signup ·
OTP verification · create-account-with-property-details · logout with full
`clearAll()`.

Start flow: flat / society / individual modes · free / paid / adhoc plans ·
society→block→flat cascading search from Supabase · society-type validation for
society inspections · individual property + owner name + owner mobile ·
`beginInspectionScope(mode)` before every new inspection · resume active
inspection · `individual-*` refs never sent to normal FK tables.

Checklist: DB-driven templates via `fetchChecklistKindForInspectionType` +
`fetchChecklistTemplates` · snapshot of in-progress checklist · ad-hoc filtering
to `Adhoc Inspection` category · `ensureRequiredAreaChecks` · add area from
template · rename/edit area · add custom check · search across areas and items ·
per-area and overall progress.

Item capture: 5 severities · live camera capture (rear-preferred, switchable) ·
image annotation screen · client-side compression to ≤50 KB · Supabase photo
upload · technician notes with char limit · service search & selection ·
₹150 consultation fallback · material codes · estimated cost roll-up ·
`service_recommendation.dart` matching.

Drafts: `SharedPreferences` session/areas/active-page/active-area · Supabase
server-side draft (`saveInspectionDraft`/`loadInspectionDraft`) · refresh
recovery into the correct area · draft clearing on submit.

Submit & reports: complete PDF · critical-issues PDF · upload to
`inspection-photos` bucket · public-HTTPS URL validation · `submitReport` RPC
(health score + critical service rows) · `submitIndividualInspection` RPC
(idempotent by `inspection_ref`) · local submitted-report cache · cross-device
history from `inspections` and `individual_inspections` with inspector-ID /
mobile / name matching · open report URL via `url_launcher`.

---

## 4. Implementation plan

1. **Tokens & primitives** — extend `app_styles.dart` (radii, spacing, severity
   tokens); add `AppCard`, `AppSectionHeader`, `AppEmptyState`, `AppStatChip`,
   `SeverityPill`, `SyncStatusDot` under `lib/widgets/`.
2. **Shell** — `AppTab` 4-tab nav + a single `AppShell` scaffold that owns the
   app bar, nav, and connectivity banner. Migrate all screens onto it.
3. **Extract before restyling** — `signin_screen.dart` (1609 L) splits into
   `login_screen.dart` + `home_screen.dart` + `start_inspection_flow/` (3 steps
   + pickers). `inspections_dashboard_screen.dart` (1434 L) splits into
   `inspect_screen.dart` + `inspection_submit_service.dart` +
   `submit_validation.dart`. Pure moves first, no behaviour change, tests green.
4. **Reports tab** — lift `_loadReportHistory()` and `_matchesCurrentInspection
   Context()` out of `profile_screen.dart` into a repository method; build the
   new list.
5. **Inspect tab** — `CustomScrollView`, collapsing header, filter chips,
   expandable area cards.
6. **Item screen** — three-zone layout, thumbnails, keyboard-safe action bar,
   Save & next.
7. **Validation & submit result page.**
8. **Web polish** — connectivity, sync state, unload guard, safe areas.
9. **A11y + text-scale pass.**

Ship 1–3 as one PR, then one PR per remaining step.

---

## 5. Definition of done

- [ ] Every item in §3 works exactly as before; no RPC signature, storage path,
      or `supabase_inspection_rpc.sql` contract changed by UI work.
- [ ] Usable one-handed at 360×640 with no horizontal scroll and no overlap.
- [ ] Renders correctly at 200% text scale.
- [ ] Refresh mid-inspection restores the exact screen and scroll position.
- [ ] A failed submit never loses a draft; a partial submit retries only the
      failed step.
- [ ] New regression tests: 4-tab nav routing · `validateForSubmit()` returns
      one blocker per rule · "No Issues" requires no photo/notes · high/critical
      require photo + notes · critical requires a service · ad-hoc needs ≥1
      custom check and is *not* subject to the 5-check rule · reports list merges
      both tables. Existing tests (login start screen, individual-active-without-
      profile, flat-requires-profile, rear-camera preference and fallback) stay
      green.
- [ ] `dart format` clean · `flutter analyze --no-fatal-infos` introduces no new
      warnings · `flutter test` passes · `flutter build web --release` succeeds ·
      production URL returns 200 after deploy.
