# Household Sharing App

A cross-platform Flutter app (iOS, Android, Web) where neighbors can share and rent household devices (e.g., vacuum cleaners, lawn mowers, kitchen machines).

Built for **Intro Mobile** at **AP Hogeschool** (2026).

## Developed by

- [Sergiu Neagu](https://github.com/sergiuNE)
- Group: **11**

## Features

### Must-haves

- **Authentication**
  - Register and sign in with email and password (Firebase Auth)

- **List Devices**
  - Owners can add a device with:
    - name
    - category
    - description
    - price per day
    - photo (optional)
    - availability
    - location
  - **New:** owners can set weekly rental time slots  
    (e.g., Monday 12:00–16:00, Tuesday 15:00–16:00)

- **Browse and Rent Devices**
  - Search by name/description/category
  - Category filter
  - **New:** location filtering using live location + adjustable radius (km)
  - **New:** renter chooses one available time slot during reservation

- **Reservation & Rental Management**
  - Dashboard for renters and owners
  - Statuses: pending / active / declined / cancelled / ended
  - Selected time slot is stored with each reservation

### Nice-to-haves

- **Reviews**
  - Star rating + optional title/description
  - Average score shown in list/details

- **Map (Marketplace-style)**
  - **New:** profile item **Map & range**
  - Use live location
  - Set search radius (1–50 km)
  - Saved location/range is used in **Discover**

## Tech Stack

- **Frontend:** Flutter
- **Backend:** Firebase (Auth + Firestore)
- **Maps:** Google Maps (`google_maps_flutter`)
- **Location:** Geolocator
- **Image hosting:** Cloudinary (unsigned uploads)

## Important Firestore Fields

### users/{uid}

- `name`, `email`, `city`
- `locationLat`, `locationLng`
- `searchRadiusKm`

### devices/{id}

- default device fields
- `availabilitySlots`:
  - `weekday` (1=Monday … 7=Sunday)
  - `startMinutes`
  - `endMinutes`

### reservations/{id}

- default reservation fields
- `slotWeekday`
- `slotStartMinutes`
- `slotEndMinutes`
- `slotLabel`

## Environment Variables

Use `--dart-define`:

- `GOOGLE_MAPS_API_KEY`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_UPLOAD_PRESET`

## Run the App

1. Install dependencies:

```bash
flutter pub get
```

2. Run:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

## Test Users

- `test@gmail.com` / `test123`
- `test2@gmail.com` / `test123`
- `test3@gmail.com` / `test123`

## Migration Note (Existing Data)

For existing accounts/devices, add these defaults:

- users: `searchRadiusKm: 15`, `locationLat/locationLng: null`
- devices: `availabilitySlots: []`
