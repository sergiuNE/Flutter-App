# Household Sharing App

A cross-platform Flutter app (iOS, Android, Web) where neighbors can lend and rent household devices (e.g. vacuum cleaners, gardening tools, kitchen appliances).

Built for **Intro Mobile** at **AP Hogeschool** (2026).

## Developed by

- [Sergiu Neagu](https://github.com/sergiuNE)
- Group: **11**

## Features

- **Authentication**
  - Register/login with email & password (Firebase Auth)

- **Offer Devices**
  - Add a device with:
    - name
    - category
    - description
    - price/day
    - optional photo
    - availability
    - optional location

- **Discover**
  - Browse all available devices
  - Filter by category
  - Search by name/description/category

- **Reservations**
  - Renters can create reservations
  - Owners can accept/manage incoming reservations
  - Renters can cancel pending/active reservations

- **Reviews**
  - Users can leave a star rating + optional title/description
  - Device rating updates and is shown in listings/details

## Tech Stack

- **Frontend:** Flutter
- **Backend:** Firebase (Auth + Firestore)
- **Image Hosting:** Cloudinary (unsigned uploads)
- **Location:** Geolocator / Google Maps

## Environment Variables (.env)

Create a `.env` file in project root:

```env
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME
CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

## Run the app

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
