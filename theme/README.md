# Skillora Web

Vite + React web MVP for Skillora.

## Run locally

Open terminal in this folder:

```bash
cd D:\Skillora\theme
npm install
npm run dev
```

Then open the local URL shown by Vite, usually:

```text
http://localhost:5173
```

## Build for hosting

```bash
npm run build
```

The production files are created in:

```text
theme/dist
```

## Firebase setup

The app works in demo mode without Firebase.

To connect Firebase, copy `.env.example` to `.env.local` and fill values from your Firebase web app settings:

```bash
copy .env.example .env.local
```

Required values:

```text
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=
VITE_FIREBASE_PROJECT_ID=
VITE_FIREBASE_STORAGE_BUCKET=
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=
```

Then enable these Firebase services:

- Authentication > Email/Password
- Firestore Database

Restart the dev server after changing environment variables.

## Deploy options

### Vercel

Deploy the `theme` folder.

Build command:

```bash
npm run build
```

Output directory:

```text
dist
```

### Firebase Hosting

From the root project or this folder, configure hosting to publish `theme/dist`.
