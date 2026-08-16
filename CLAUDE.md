# KEPR Inspections Repository Guide

This file is the authoritative engineering guide for this repository. Read it before changing code, database functions, authentication, report generation, or deployment configuration.

## Product scope

KEPR Inspections is a Flutter **web-only** application used by inspectors to perform:

- Flat inspections
- Society inspections
- Individual Home inspections
- Free, paid, and ad-hoc inspection plans

Production URL: `https://inspections-ten.vercel.app`

Repository: `https://github.com/keprofficial/Inspections.git`

Branch: `main`

Do not add Android/iOS platform projects unless the product scope explicitly changes. The supported production target is Flutter Web deployed to Vercel.

## Required repository files

Do not delete these:

- `lib/` — application source
- `web/` — Flutter web entry and assets
- `assets/brand/` — KEPR branding
- `test/` — regression and widget tests
- `pubspec.yaml` and `pubspec.lock` — dependency definition and lock file
- `.metadata` and `analysis_options.yaml` — Flutter/tooling configuration
- `vercel.json` — production build and SPA routing configuration
- `supabase_inspection_rpc.sql` — consolidated inspection authentication/report RPC source
- `README.md` and this file

Generated folders such as `build/`, `.dart_tool/`, and `.idea/` are not source and must remain ignored.

## Architecture

### Entry and routing

- `lib/main.dart` initializes Supabase, restores the saved inspection session, and selects the initial screen.
- A fresh authenticated session with an active inspection opens `InspectionsDashboardScreen`.
- Otherwise the app opens `SignInScreen`.

### State and persistence

- `lib/services/inspection_session.dart` holds the current in-memory inspector and inspection context.
- `lib/services/inspection_draft_storage.dart` persists session, checklist areas, active page, active area, and local report history using `SharedPreferences`.
- `lib/services/supabase_repository.dart` is the only place that should communicate directly with Supabase.

Do not add Supabase calls directly inside UI widgets when repository methods can own the operation.

### Main UI flow

The app is a four-tab shell — **Home · Inspect · Reports · Me** (`AppTab` in
`lib/widgets/bottom_nav.dart`). Do not reintroduce a two-tab nav: report
history and the active inspection each need a permanent address.

- `signin_screen.dart` is the authentication gate only. It renders
  `LoginScreen` or `AppShell`. Every "back to the start" navigation in the
  codebase targets it, so keep the class name.
- `app_shell.dart` owns the bottom navigation, the offline banner, and the
  lifetime of each tab body. Tab bodies live in an `IndexedStack` so switching
  tabs does not discard a loaded checklist or scroll position.
- `login_screen.dart` authenticates the inspector. Nothing else belongs here.
- `home_screen.dart` (tab 1) — greeting, resume-inspection card, start CTA,
  weekly stats, recent reports.
- `start_inspection_flow.dart` — a three-step wizard (mode → plan → property)
  on its own route. Property selection uses the full-screen
  `property_picker_sheet.dart`, never inline dropdowns: inline dropdowns grew
  and shrank the page under the user's thumb and pushed downstream fields
  off-screen.
- `inspect_screen.dart` (tab 2) — the active inspection. Areas expand in place;
  each expanded area still offers Save draft and Submit section.
- `area_manager_sheet.dart` — add / custom / modify area, and the ad-hoc sheet.
- `checklist_item_screen.dart` records severity, notes, photos, services,
  materials, and completion state, in three zones: verdict → evidence →
  guidance. `No issue` is presented first and full width because it is the
  most common answer. The action bar must stay pinned above the keyboard.
- `reports_screen.dart` (tab 3) — submitted report history, searchable and
  filterable by inspection type.
- `profile_screen.dart` (tab 4) — identity, current inspection, connection
  status, and sign out. Sign out clears the draft, so it stays behind a
  confirm dialog.
- `submit_result_screen.dart` — the full-screen submit experience: real step
  progress, a success state that links to the PDF, and a failure state that
  retries only the step that failed.

### Shared UI vocabulary

- Tokens: `AppRadii`, `AppSpacing`, `AppSizes` in `constants/app_styles.dart`.
  Use only these values for radius, spacing, and minimum tap target (48px).
- `constants/severity.dart` is the single source of truth for how a severity
  looks *and* what evidence it requires. Never resolve severity colour or
  requirements anywhere else, and never use raw `Colors.green` / `Colors.orange`
  / `Colors.red.shade900` for severity.
- Primitives: `AppCard`, `AppSectionHeader`, `AppEmptyState`, `AppStatTile`,
  `AppProgressBar`, `AppFilterChip`, `SeverityPill`, `SeverityChoice`,
  `SyncStatusDot`, `ConnectivityBanner`.
- Only one `AppElevation.floating` element per screen — the thing the user is
  meant to act on.

### Submission and validation

- `services/submit_validation.dart` returns a list of typed `SubmitBlocker`s
  instead of throwing. Each blocker carries the items it applies to so the UI
  can deep-link a "Fix" action. Add new submit rules here, not inline in a
  widget.
- `services/inspection_submit_service.dart` owns the submit sequence
  (validate → build PDF → upload → persist) and reports each `SubmitStep`. It
  accepts a `cachedReportUrl` so a failure in the final RPC retries only the
  database write rather than regenerating and re-uploading the PDF.
- `services/inspection_start_service.dart` owns flat/society/individual start.
- `services/report_history_service.dart` is the only place that merges
  `inspections` and `individual_inspections` history. Home, Reports, and
  Profile all read through it so their counts cannot drift.
- `services/sync_status.dart` + `services/unsaved_work_guard.dart` surface
  whether a draft actually reached the server, and guard tab close while work
  is unsaved. A draft saved locally but rejected by the server keeps the guard
  armed.

### Reporting

- `report_pdf_service.dart` produces complete and critical-issue PDF documents.
- PDFs are uploaded to the public Supabase Storage bucket `inspection-photos`.
- A report is considered submitted only after the PDF URL and database report record are saved.
- Local report history is a convenience cache, not the source of truth for cross-device history.

## Inspection modes and important invariants

Valid `inspectionMode` values:

- `flat`
- `society`
- `individual`

Valid `inspectionPlan` values:

- `free`
- `paid`
- `adhoc`

Always call `InspectionSession.beginInspectionScope(mode)` before starting a new inspection. This clears the previous property-specific state while preserving authenticated inspector credentials.

### Flat inspections

- Use a real property/profile selected from Supabase.
- Create a row in the normal `inspections` table through the start RPC.
- Must retain `profileId`, `propertyId`, and `inspectionId` for refresh recovery.

### Society inspections

- The selected property must have society type.
- Society reports must never be mapped to a flat property.
- The database start RPC validates the property type.

### Individual Home inspections

Individual inspections are intentionally different:

- They do not have a normal KEPR property/profile row.
- `propertyId` and `inspectionId` use a generated `individual-*` reference.
- `profileId` may be null. `InspectionSession.isActive` must therefore remain mode-aware.
- Refresh recovery must restore the Individual inspection without redirecting to flat selection.
- “Submit Section” finalizes the Individual report: it generates the PDF, uploads it, and calls `inspection_app_submit_individual_inspection`.
- Completed reports are stored in `individual_inspections`, not the normal `inspections` table.
- The secure RPC derives inspector ID/name/mobile from the valid login session; do not trust inspector identity sent by the browser.
- Submission is idempotent by `inspection_ref`, allowing safe retries.

Do not send generated Individual references to normal inspection-area foreign-key tables or normal report RPCs.

## Checklist behavior

Checklist templates and service catalog data are loaded from Supabase. A checklist already in progress is persisted as a snapshot so later admin/database changes do not silently rewrite an active inspection.

Ad-hoc plans contain only items categorized as `Adhoc Inspection`. They require at least one custom check before final submission.

Do not restore the old “complete at least five checks” restriction for ad-hoc inspections.

## Evidence rules

- Photo capture remains available for every severity.
- A photo is compulsory only for `high` or `critical` findings.
- No Issue, Low, and Medium findings must not be blocked for missing photos.
- High and Critical findings require technician notes.
- Critical findings require a selected service.
- Wall dampness checks follow the same severity-based photo rule; do not restore the old unconditional two-photo requirement.

The camera must prefer `CameraLensDirection.back`. The front camera is only a fallback when no rear camera is reported. Preserve the camera-switch control.

Photos must be live camera captures. Uploaded storage URLs used at final submission must be public HTTPS URLs from the configured Supabase project.

## Supabase contract

Supabase URL: `https://egalrsutygdvdmjkvduh.supabase.co`

The web client may use only the Supabase publishable key. Never put a service-role key in Flutter, Vercel client configuration, Git, documentation, or browser code.

`supabase_inspection_rpc.sql` is the single retained SQL source for this repository. It contains:

- Inspector user seed credentials, password hashing, and session management
- Inspection type and code generation
- Flat and society start/report RPCs
- Storage bucket and policies
- Individual Home report table and submission RPC
- Execute grants and schema reload notification

The KEPR platform's shared tables—such as properties, services, and checklist catalog data—already live in Supabase and may be owned by other KEPR applications. Do not assume this file recreates the entire cross-application database.

After changing a database function, update this single file and run the complete file in Supabase SQL Editor. Keep functions idempotent using `create table if not exists`, `alter table ... add column if not exists`, `create or replace function`, and explicit policy recreation.

Do not create scattered root-level SQL fixes. Consolidate durable database changes into `supabase_inspection_rpc.sql`.

## Cross-device report history

Cross-device visibility depends on database persistence:

- Normal reports come from `inspections.full_report_pdf_url`.
- Individual reports come from `individual_inspections.report_pdf_url`.
- History matching supports inspector ID, normalized mobile, and normalized name to accommodate older rows.

Never treat `SharedPreferences` as cross-device storage. A section/draft saved only locally cannot appear on another device.

## Commands

Run commands from this repository directory.

```powershell
..\flutter\bin\flutter.bat pub get
..\flutter\bin\dart.bat format lib test
..\flutter\bin\flutter.bat analyze --no-fatal-infos
..\flutter\bin\flutter.bat test
..\flutter\bin\flutter.bat build web --release
```

Existing analyzer info notices are not build failures. New warnings or errors introduced by a change must be fixed.

Every behavior change should include a focused regression test when the logic can be isolated. Always run all tests and a production web build before deployment.

## Vercel deployment

The tracked root `vercel.json` is required. It builds Flutter from the workspace SDK at `../flutter` and serves `build/web` with SPA rewrites.

For a manual prebuilt deployment, do not copy the root build configuration into `build/web`. Use a small prebuilt-site config containing only clean URLs and the rewrite to `/index.html`; otherwise Vercel will attempt to run the Flutter build command from inside `build/web`.

Production alias: `https://inspections-ten.vercel.app`

After deployment, verify the production URL returns HTTP 200.

## Change discipline

- Preserve unrelated user changes in a dirty worktree.
- Do not commit generated build/cache folders.
- Do not permanently delete database history or customer uploads.
- Prefer soft-deactivating catalog/checklist records over deleting rows referenced by reports.
- Keep Flat, Society, and Individual storage/report mappings separate.
- Do not change live database schema only in Dart; update `supabase_inspection_rpc.sql` in the same change.
- Do not push or deploy until formatting, analysis, tests, and web build pass.
- Use concise commit messages describing user-visible behavior.

## Current regression tests

- App starts on the login screen.
- Individual inspections count as active without a profile row.
- Flat inspections still require a profile row.
- Camera selection prefers the rear camera.
- Camera selection falls back safely when no rear camera exists.
- Login is a single-purpose screen with no property or plan pickers.
- The start flow asks mode first, then plan, then property, and states the
  ad-hoc custom-check requirement up front.
- Flat selection uses tappable pickers whose downstream fields stay disabled
  until their parent is chosen.
- Bottom navigation exposes all four destinations and reports each tap.
- `validateForSubmit` returns one blocker per broken rule; ad-hoc plans are
  exempt from the five-check minimum but need at least one check; low and
  medium findings are never blocked for a missing photo; high and critical
  need a photo and notes; critical needs a service.
- An area is flagged critical only by a *completed* critical finding, never by
  a checklist template's seeded severity.
- The start flow and bottom navigation survive a 360px viewport at 200% text
  scale.

When fixing a regression, add the new invariant here only if future contributors must preserve it across unrelated work.
