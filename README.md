# Kepr - Safety Inspection Application

A modern, production-grade safety inspection application built with Flutter, featuring a comprehensive design system and intuitive UI/UX.

## Features

- **Sign Up & Authentication** - OTP-based account creation with password validation
- **Property Management** - Enter flat/house details for inspection tracking  
- **Inspection Dashboard** - Villa-level safety summary with dynamic progress metrics
- **Inspection Areas** - 10+ inspection areas with individual checklists
- **Checklist Items** - Detailed inspection items with photo/video capture and severity levels
- **Inspector Profile** - Comprehensive profile with activity stats and preferences
- **Bottom Navigation** - Easy navigation between Home, Inspections, and Profile
- **Responsive Design** - Fully responsive design that works on all screen sizes

## Tech Stack

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Design System**: Custom Material Design with Manrope typography
- **State Management**: Built-in StatefulWidget
- **Icons**: Material Icons & Lucide Icons

## Design System

The app follows a comprehensive design system with:
- **Colors**: 
  - Primary (Coral): #F85F5A
  - Dark (Crimson): #b12b2c
  - Secondary (Navy): #0F172A
  - Neutrals: Cool greys (#F8FAFC to #0F172A)
- **Typography**: Manrope font family exclusively
- **Elevation**: Soft shadows with subtle borders
- **Rounding**: 8px for components, 16px for cards

## Getting Started

### Prerequisites
- Flutter 3.0 or higher
- Dart 3.0 or higher
- A code editor (VS Code, Android Studio, or IntelliJ)

### Installation

1. Clone or download the repository
2. Navigate to the project directory:
   ```bash
   cd kepr
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

Run on your connected device or emulator:
```bash
flutter run
```

### Building the App

Build for Android:
```bash
flutter build apk
```

Build for iOS:
```bash
flutter build ios
```

Build for Web:
```bash
flutter build web
```

## Project Structure

```
kepr/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── constants/
│   │   ├── colors.dart          # Color palette
│   │   └── app_styles.dart      # Typography and styles
│   ├── models/
│   │   └── models.dart          # Data models
│   ├── screens/
│   │   ├── signup_screen.dart
│   │   ├── signin_screen.dart
│   │   ├── property_details_screen.dart
│   │   ├── inspections_dashboard_screen.dart
│   │   ├── inspection_area_screen.dart
│   │   ├── checklist_item_screen.dart
│   │   └── profile_screen.dart
│   └── widgets/
│       ├── kepr_logo.dart
│       ├── kepr_button.dart
│       ├── kepr_header.dart
│       ├── bottom_nav.dart
│       └── badge.dart
├── pubspec.yaml                 # Dependencies
└── README.md                    # This file
```

## Screens

1. **Sign Up** - Create account with name, username, phone, and password with visibility toggle
2. **Sign In** - Login with phone number for OTP verification
3. **Property Details** - Enter Kepr ID, society name, and flat/house number
4. **Inspections Dashboard** - View villa progress circle (72%), search areas, and 7+ inspection items
5. **Inspection Area** - View Main Entrance Door checklist with 6 items and progress tracking
6. **Checklist Item** - Capture Socket Functionality with photo/video, severity levels, and notes
7. **Inspector Profile** - View Alex Rivera's stats (48 completed, 98% compliance), settings, and preferences

## Navigation

- Bottom navigation bar for switching between Home, Inspections, and Profile screens
- Back buttons on all detail screens for easy navigation
- Seamless transitions between screens
- All navigation is fully functional with mock data

## Customization

### Colors
Edit `lib/constants/colors.dart` to customize the color palette:
```dart
static const Color coral = Color(0xFFF85F5A);
static const Color crimson = Color(0xFFb12b2c);
static const Color navy = Color(0xFF0F172A);
```

### Typography
Styles are defined in `lib/constants/app_styles.dart`. Modify text styles and input decorations there.

### Fonts
Add custom fonts to `pubspec.yaml` under the `fonts:` section.

## Dependencies

- **google_fonts**: For web fonts support
- **lucide_icons**: For additional icon options
- **intl**: For internationalization

## Platform Support

- ✅ Android (API 21+)
- ✅ iOS (11.0+)
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Performance Optimizations

- Uses efficient rebuilding with StatefulWidget
- Lazy loading of screens
- Optimized list views with shrinkWrap
- Efficient use of ListView builders

## Code Quality

- Clean architecture with separation of concerns
- Reusable components and widgets
- Consistent naming conventions
- Well-organized file structure
- Type-safe Dart code

## License

Proprietary - Kepr Safety Inspection Application

## Support

For issues or feature requests, contact the development team.

## Future Enhancements

- State management with Provider/BLoC
- Local database with Hive/SQLite
- Image/video capture integration
- Real-time synchronization with backend
- Offline mode support
- Push notifications
- Multi-language support
