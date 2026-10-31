# DOGO 🚀

> **Urban Mobility & Parcel Courier Dispatch Platform**  
> Fast, reliable ride-hailing and on-demand delivery with real-time GPS tracking, real-road turn-by-turn navigation, and seamless driver dispatch.

---

## 📱 Overview

**DOGO** is an end-to-end urban mobility ecosystem built for high-density metropolitan transit (optimized for Lagos and Nigerian commercial hubs including Ikeja GRA, Lekki Phase 1, Victoria Island, Yaba, and Bodija).

The repository houses the multiplatform mobile application, web driver portals, design assets, and backend integrations powering both passenger rides (Taxi, Keke, Bike) and courier parcel dispatch.

---

## 🗂️ Repository Structure

```plaintext
DOGO/
├── dogo_crew/            # 📱 Core Flutter Mobile Application (Android / iOS)
│   ├── lib/
│   │   ├── data/         # Models, Repositories, Routing & Location Services
│   │   ├── ui/           # Rides, Driver Console, Auth, Shell & Map Views
│   │   └── main.dart     # App entrypoint and multi-provider state configuration
│   ├── android/          # Native Android configuration (API 36+, GPS, Impeller)
│   ├── ios/              # Native iOS configuration
│   └── pubspec.yaml      # Dependencies & assets manifest
│
├── DOGO driver side/     # 💻 Web Driver Management & Dispatch Console (React / Vite)
├── Dogo ui/              # 🌐 Web UI & Supabase Client Integration
├── dogoui1/              # 🎨 Web UI Component Prototyping
├── DOGO.penpot/          # 📐 UI/UX Penpot Design System & Vector Assets
└── README.md             # Project documentation
```

---

## ✨ Key Features & Capabilities

### 1. 🗺️ Real Road Routing Polylines
- Turn-by-turn road curves following real highway geometries, bridges, and city avenues (e.g., Third Mainland Bridge, Lekki-Ikoyi Link Bridge, Ikorodu Road) rather than linear straight-line cuts.
- Built on an abstracted `RoadRoutingService` (currently OSRM GeoJSON engine, zero-cost and offline-resilient) designed for instant drop-in swap to **Google Maps Directions API**.

### 2. 📍 Interactive Search & Live Device GPS
- Instant location search with debounced autocomplete for pickups and destinations.
- **One-tap "Use current GPS"** feature that reads device latitude/longitude via high-precision location hardware and reverse-geolocates the user's real street address.
- Quick-select pills for major commercial centers and airports (MMA2).

### 3. 🚗 Real-Time Driver Simulation & Live Tracking
- Live 6-stage lifecycle engine:
  1. `Finding Driver`
  2. `Driver Confirmed`
  3. `Driver En Route`
  4. `Driver at Pickup` (with audio-visual arrival banners)
  5. `Trip in Progress`
  6. `Completed` (with 5-star ratings & itemized receipts)
- Dynamic vehicle orientation heading calculation (`calculateBearing`) matching the road curve.

### 4. 🛺 Multimodal Vehicles & Courier Dispatch
- Support for **Taxi**, **Keke (Tricycle)**, and **Bike Dispatch**.
- Parcel courier flow capturing package description, recipient contact name, and phone number with direct dial and WhatsApp triggers.

### 5. 💳 DOGO Wallet & Dynamic Pricing
- Transparent distance-based fare calculation.
- Built-in digital wallet with quick top-ups (₦5,000, ₦10,000, ₦20,000) and balance verification safeguards.

---

## 🛠️ Tech Stack

- **Mobile Framework**: [Flutter](https://flutter.dev/) 3.x (Dart 3.x)
- **State Management**: `provider` (MVVM architecture)
- **Navigation & Routing**: `go_router`
- **Mapping & Geolocation**: `flutter_map` (OSM tiles with custom night filter), `latlong2`, `geolocator`, `geocoding`
- **Web Portals**: React, Vite, Tailwind CSS, Supabase
- **UI & Typography**: Google Fonts (`Sora` for headings, `Manrope` for body)

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
- [Android Studio](https://developer.android.com/studio) / Android SDK with platform tools (`adb`)
- [Node.js](https://nodejs.org/) & [Bun](https://bun.sh/) (for web modules)

### Running the Mobile App (`dogo_crew`)

1. **Navigate to the mobile app directory**:
   ```bash
   cd dogo_crew
   ```

2. **Install Dart dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on a connected device or emulator**:
   ```bash
   flutter run
   ```

4. **Build a production release APK**:
   ```bash
   flutter build apk --release
   ```
   The compiled APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🗺️ Switching to Google Maps Directions API

When ready to switch the polyline routing from OSRM to Google Maps:

1. Open `dogo_crew/lib/data/services/road_routing_service.dart`.
2. Provide your Google Maps API key:
   ```dart
   static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
   ```
3. Update the request URL in `getDrivingRoute()`:
   ```dart
   final url = Uri.parse(
     'https://maps.googleapis.com/maps/api/directions/json?'
     'origin=${start.latitude},${start.longitude}'
     '&destination=${end.latitude},${end.longitude}'
     '&key=$googleMapsApiKey'
   );
   ```
4. All map rendering (`OsmMapWidget`) and driver movements (`DriverViewModel`) automatically adapt with no UI refactoring needed.

---

## 📄 License

Copyright © 2026 DOGO. All rights reserved.  
Maintained by [Fast Steps Consult](https://github.com/faststepsconsult).
