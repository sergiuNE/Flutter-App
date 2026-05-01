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
  - `date` (Timestamp)
  - `startMinutes`
  - `endMinutes`

### reservations/{id}

- default reservation fields
- `slotDate`
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
flutter run `
  --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY `
  --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

## Test Users

- `test@gmail.com` / `test123`
- `test2@gmail.com` / `test123`
- `test3@gmail.com` / `test123`
- `test4@gmail.com` / `test123.`
- `test6@gmail.com` / `test123.`
- `test7@gmail.com` / `test123.`

## Migration Note (Existing Data)

For existing accounts/devices, add these defaults:

- users: `searchRadiusKm: 15`, `locationLat/locationLng: null`
- devices: `availabilitySlots: []`

## Video (verslag)

The video walks through the full app experience end-to-end. It demonstrates device listing — including uploading a photo from the gallery or taking one directly with the camera, selecting weekly availability time slots, and setting a price per day. Browse and discovery features are shown, including searching by name and filtering by category. Location-based filtering is highlighted through a test user based in the USA, who only sees devices within his configured radius — confirming that the geolocation and range system works correctly across regions. The rental flow is covered in full: a renter reserves a device by choosing an available time slot, and the owner receives the request and can accept or decline it from their dashboard. Finally, the review system is demonstrated — posting a star rating and deleting it afterward.
