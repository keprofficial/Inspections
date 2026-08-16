# KEPR Inspections

Flutter web application for KEPR flat, society, ad-hoc, free, paid, and Individual Home inspections.

## Production

https://inspections-ten.vercel.app

## Local development

```powershell
flutter pub get
flutter run -d chrome
```

## Validate

```powershell
flutter analyze --no-fatal-infos
flutter test
flutter build web --release
```

## Database

`supabase_inspection_rpc.sql` is the single retained database setup file. It contains:

- Inspector login users and sessions
- Inspection code generation
- Flat and society inspection RPCs
- Draft and report submission functions
- Individual Home report table and secure submission RPC
- Storage access policies required by inspection uploads

Run the complete file in the Supabase SQL Editor after changing database functions or inspector credentials.

Never commit a Supabase service-role key. The web app uses only the public Supabase URL and publishable key.

## Deployment

The Flutter web output is generated in `build/web` and deployed to the existing Vercel `inspections` project. `vercel.json` and `web/index.html` are required and must remain in the repository.
