# Kepr Flutter App - Setup & Build Guide

## Quick Start

### 1. Install Flutter
Download Flutter from https://flutter.dev/docs/get-started/install

### 2. Setup Project
```bash
cd kepr
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

## Project Structure

```
kepr/
├── lib/
│   ├── main.dart                           # App entry point
│   ├── constants/
│   │   ├── colors.dart                    # Color palette definitions
│   │   └── app_styles.dart                # Typography and input styles
│   ├── models/
│   │   └── models.dart                    # Data models (Villa, Inspector, etc.)
│   ├── screens/                           # 7 Main screens
│   │   ├── signup_screen.dart             # ✅ Screen 1: Sign Up with OTP
│   │   ├── signin_screen.dart             # ✅ Screen 2: Sign In
│   │   ├── property_details_screen.dart   # ✅ Screen 3: Property Details
│   │   ├── inspections_dashboard_screen.dart # ✅ Screen 4: Dashboard
│   │   ├── inspection_area_screen.dart    # ✅ Screen 5: Inspection Area
│   │   ├── checklist_item_screen.dart     # ✅ Screen 6: Checklist Item
│   │   └── profile_screen.dart            # ✅ Screen 7: Profile
│   └── widgets/                           # Reusable UI components
│       ├── kepr_logo.dart
│       ├── kepr_button.dart
│       ├── kepr_header.dart
│       ├── bottom_nav.dart
│       └── badge.dart
├── pubspec.yaml                           # Dependencies
├── .gitignore
└── README.md
```

## Screens Implemented

### 1. Sign Up Screen (signup_screen.dart)
- Full name input
- Username input
- Mobile number input
- Password with visibility toggle (👁)
- Terms & Conditions checkbox
- Generate OTP button (disabled until terms accepted)
- Sign in link

### 2. Sign In Screen (signin_screen.dart)
- Mobile number input
- Generate OTP button
- Sign up for free link
- Footer with Terms & Privacy links

### 3. Property Details Screen (property_details_screen.dart)
- Kepr Unique ID input
- Society Name input
- Flat/House number input
- Continue button (enabled when all fields filled)
- Create Account link
- Bottom navigation

### 4. Inspections Dashboard Screen (inspections_dashboard_screen.dart)
- Progress circle showing 72% completion
- Villa info card with audit date
- Quick stats badges (Completed, In Progress, Issues, Pending)
- Search areas functionality
- Filter button
- 7 inspection areas with:
  - Icon, name, progress %, status
  - Completed items count
  - Color-coded progress indicators
  - Urgent status (red border for critical items)
- Generate Report button
- Bottom navigation (Home active)

### 5. Inspection Area Screen (inspection_area_screen.dart)
- Header with area name and reference ID
- Section Progress card with percentage and progress bar
- 6 checklist items with:
  - Checkbox state (completed/pending)
  - Item name
  - Chevron arrow
- Save Draft button
- Submit Section button
- Responsive layout with fixed footer

### 6. Checklist Item Screen (checklist_item_screen.dart)
- Category badge (ELECTRICAL SAFETY)
- Item title (Socket Functionality)
- Item ID badge
- Description text
- Capture Photo card (enabled)
- Record Video card (disabled)
- Issue Severity selector (Low, Medium, High, Critical)
- Technician Notes textarea with character counter (500 max)
- Inspection Tips card
- Cancel & Mark as Completed buttons
- Responsive layout with fixed footer

### 7. Inspector Profile Screen (profile_screen.dart)
- Profile header with avatar (AR initials)
- Certified & Active badges
- Activity Summary card:
  - 48 Completed
  - 3 Active Audits
  - 98% Compliance Rating with verified icon
- Personal Details section with Edit button:
  - Full Name: Alex Rivera
  - Username: @arivera
  - Mobile: +1 (555) 000-0000
  - Email: alex.rivera@kepr.io
- Settings & Preferences section:
  - Notification Settings
  - Privacy & Security
  - Support & Feedback
- Logout button
- Bottom navigation (Profile active)

## Design System Implementation

### Colors
- **Primary (Coral)**: #F85F5A - Buttons, progress indicators, active states
- **Dark (Crimson)**: #b12b2c - Profile header background, brand logo
- **Secondary (Navy)**: #0F172A - Headers, high-contrast text
- **Neutrals**: Cool greys from #F8FAFC to #0F172A for backgrounds

### Typography
- **Font**: Manrope (via Google Fonts)
- **Weights**: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold), 800 (ExtraBold)
- **Sizes**: 12px (Label), 14px (Body), 16px (Body), 18px (Body), 24px (Headline), 32px (Headline)

### Components
- **Buttons**: Primary, Secondary, Ghost variants
- **Inputs**: Text fields with focus states, validation
- **Cards**: White background, soft shadow, light border
- **Badges**: Status indicators with color variants
- **Header**: Coral background with logo and navigation
- **Bottom Nav**: Fixed tab navigation

### Spacing & Sizing
- **Base unit**: 8px
- **Border radius**: 8px (components), 16px (cards), 20px (pills)
- **Shadows**: Soft (0px 1px 3px, 0px 4px 6px), Medium (0px 10px 15px)

## Navigation Flow

```
Sign Up → Property Details → Dashboard → Inspection Area → Checklist Item
  ↓                ↓              ↓           ↓
Sign In  ←  Create Account    Profile  ← Back Button
```

## Building for Different Platforms

### Android
```bash
flutter build apk
# Output: build/app/outputs/apk/release/app-release.apk
```

### iOS
```bash
flutter build ios
# Output: build/ios/iphoneos/Runner.app
```

### Web
```bash
flutter build web
# Output: build/web
```

## Testing Navigation

1. **Sign Up Flow**:
   - Enter details → Check terms box → Click "Generate OTP"
   - Or click "Already have an account? Sign in"

2. **Dashboard Flow**:
   - Click any inspection area card → Navigate to details
   - Click checklist items → Navigate to item details
   - Use bottom nav to switch screens

3. **Back Navigation**:
   - All detail screens have back buttons
   - Bottom nav allows switching between main sections

## Customization

### Change Colors
Edit `lib/constants/colors.dart`:
```dart
static const Color coral = Color(0xFFF85F5A);
```

### Add Custom Fonts
Add to `pubspec.yaml` and reference in `lib/main.dart`

### Modify Styles
Edit `lib/constants/app_styles.dart` for typography and input styles

## Performance Tips

- Screens use `StatefulWidget` for efficient rebuilds
- Lists use `ListView.builder` for optimized rendering
- `shrinkWrap: true` prevents unnecessary scrolling
- Proper widget disposal in `dispose()` methods

## Dependencies

```yaml
- flutter: SDK (core)
- cupertino_icons: 1.0.2 (Icons)
- google_fonts: 6.1.0 (Manrope font)
- lucide_icons: 0.263.0 (Additional icons)
- intl: 0.19.0 (Internationalization)
```

## Common Issues & Solutions

### App not running?
```bash
flutter clean
flutter pub get
flutter run
```

### Fonts not loading?
- Run `flutter pub get`
- Rebuild the app with `flutter run`

### Build errors?
```bash
flutter pub get
flutter upgrade
flutter run
```

## Next Steps

1. Install Flutter SDK
2. Run `flutter pub get` in the kepr directory
3. Connect a device or start an emulator
4. Run `flutter run`
5. Navigate through all 7 screens
6. Customize colors and fonts as needed
7. Build APK/IPA for distribution

## Support

Refer to the main [README.md](README.md) for more details about the app structure and features.
