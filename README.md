# SHG Employee App — Flutter

A mobile app for microfinance field officers to manage SHG group collections, surveys, and reporting.

## Features

| Screen | Description |
|---|---|
| **Dashboard** | Map/List toggle of today's SHG assignments, summary stats |
| **Gram Panchayat** | Survey form (villages, population, distance, network, bank, crop) |
| **Village** | Village-level survey with saved villages list |
| **Groups** | All SHG groups with savings & outstanding loan overview |
| **Collection** | Customer-wise and group-wise collection entry |
| **Profile** | Employee info, stats, and settings |

---

## Project Structure

```
lib/
├── main.dart                   # App entry + bottom navigation
├── theme/
│   └── app_theme.dart          # Colors, typography, component styles
├── models/
│   └── shg_group.dart          # Data models (SHGGroup, Member)
├── screens/
│   ├── dashboard_screen.dart   # Dashboard with map/list
│   ├── gram_panchayat_screen.dart
│   ├── village_screen.dart
│   ├── groups_screen.dart
│   ├── collection_screen.dart
│   └── profile_screen.dart
└── widgets/
    └── stat_card.dart          # StatCard, SHGGroupCard, AppFormField etc.
```

---

## Getting Started

### 1. Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code

### 2. Install dependencies
```bash
cd employee_app
flutter pub get
```

### 3. Run the app
```bash
flutter run
```

---

## Google Maps Integration

The dashboard map view currently uses a placeholder painter. To enable real maps:

1. Add the dependency in `pubspec.yaml`:
   ```yaml
   google_maps_flutter: ^2.5.0
   ```

2. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com)

3. **Android**: Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
     android:name="com.google.android.geo.API_KEY"
     android:value="YOUR_API_KEY"/>
   ```

4. **iOS**: Add to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

5. Replace the `_buildMapView()` placeholder in `dashboard_screen.dart` with:
   ```dart
   GoogleMap(
     initialCameraPosition: CameraPosition(
       target: LatLng(26.8467, 80.9462), // Your region
       zoom: 12,
     ),
     markers: _buildMarkers(),
   )
   ```

---

## Color Scheme

| Color | Hex | Usage |
|---|---|---|
| Primary Blue | `#1E6FFF` | Header, buttons, active states |
| Success Green | `#00C896` | Collected status, savings |
| Accent Orange | `#FF6B35` | Pending, loans, alerts |
| Purple | `#8B5CF6` | Savings card |
| Background | `#F4F7FF` | Screen background |

---

## Next Steps / Recommended Libraries

| Need | Package |
|---|---|
| State management | `provider` or `riverpod` |
| API calls | `dio` |
| Local DB | `sqflite` or `hive` |
| Offline sync | `drift` (floor) |
| PDF reports | `pdf` + `printing` |
| Auth | `firebase_auth` |
| Maps | `google_maps_flutter` |
| Charts | `fl_chart` |

---

## API Integration Points

Replace mock data in each screen with real API calls:

```dart
// Example: Fetch today's groups
final response = await http.get(
  Uri.parse('https://your-api.com/api/v1/employee/groups/today'),
  headers: {'Authorization': 'Bearer $token'},
);
```

Screens to wire up:
- `dashboard_screen.dart` → `GET /groups/today`
- `groups_screen.dart` → `GET /groups`
- `collection_screen.dart` → `POST /collections`
- `gram_panchayat_screen.dart` → `POST /surveys/gram-panchayat`
- `village_screen.dart` → `POST /surveys/village`
