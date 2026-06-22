# Face Recognition POC — Flutter PWA

**Stage 1: Prove the browser face loop works before touching the ERP.**

```
Browser Camera → Register Face → 128-d Embedding → Store
      → New Photo → 128-d Embedding → Compare → Match ✓
```

Everything runs **100% in the browser**. No backend, no server, no cloud API.

---

## How it works

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI | Flutter Web (PWA) | Cross-platform shell |
| Face Detection | face-api.js (SSD MobileNet v1) | Find face in frame |
| Landmarks | face-api.js (68-point model) | Align face |
| Embedding | face-api.js (FaceNet-style 128-d) | Generate descriptor vector |
| Comparison | Euclidean distance < 0.6 | Match / No Match |
| Storage | `localStorage` (SharedPreferences) | Persist embeddings on device |

### face-api.js models (loaded from jsDelivr CDN)
- `ssd_mobilenetv1` — fast face bounding box detection
- `face_landmark_68` — 68-point landmark alignment
- `face_recognition_net` — 128-dimensional embedding (ResNet-34 based)

Threshold `0.6` is the standard for this model (same as dlib). Adjust in `web/index.html → compareEmbeddings`.

---

## Prerequisites

```bash
flutter --version    # Needs Flutter 3.10+ with web support
flutter config --enable-web
```

## Quick Start

```bash
# 1. Clone / open the project
cd face_poc

# 2. Get dependencies
flutter pub get

# 3. Run in Chrome (hot reload works)
flutter run -d chrome

# 4. Or build the PWA for production
flutter build web --release
# → Output in build/web/
# Serve with: npx serve build/web -p 3000
```

> **HTTPS required for camera access** — Chrome blocks `getUserMedia` on plain HTTP (except `localhost`). For production testing, use `ngrok` or any HTTPS host.

---

## Project Structure

```
face_poc/
├── web/
│   ├── index.html              ← face-api.js loaded here + JS bridge functions
│   ├── manifest.json           ← PWA manifest
│   └── flutter_service_worker.js
├── lib/
│   ├── main.dart               ← App entry
│   ├── models/
│   │   └── face_embedding.dart ← Data model (128-d vector + metadata)
│   ├── services/
│   │   ├── face_api_service.dart  ← Flutter → JS bridge (dart:js)
│   │   ├── camera_service.dart    ← getUserMedia wrapper (dart:html)
│   │   └── embedding_storage.dart ← localStorage persistence
│   ├── widgets/
│   │   ├── camera_view.dart       ← Live camera + face oval overlay
│   │   └── model_status_banner.dart ← AI model loading indicator
│   └── screens/
│       ├── home_screen.dart    ← Dashboard + registered faces list
│       ├── register_screen.dart ← Capture + generate + store embedding
│       └── match_screen.dart   ← Capture + compare + show result
└── pubspec.yaml
```

---

## What this POC answers

| Question | Answer after POC |
|----------|-----------------|
| Can a browser generate reliable face embeddings? | ✓ / ✗ |
| Is the 0.6 threshold good for your users? | Tune it |
| Does it work on mobile browsers? | Test iOS Safari + Android Chrome |
| Is CDN model load time acceptable? | ~3–5 sec first load, cached after |
| Does it work under office lighting? | Real-world test |

---

## Next stages (after POC proves the loop)

- **Stage 2:** Anti-spoofing (liveness detection)
- **Stage 3:** Multi-face registration per employee
- **Stage 4:** ERP integration (attendance marking)
- **Stage 5:** PWA conversion of existing app

---

## Tuning the match threshold

In `web/index.html`, find `compareEmbeddings`:

```js
const THRESHOLD = 0.6; // Lower = stricter (fewer false positives, more false negatives)
                        // Higher = looser (more false positives, fewer false negatives)
```

Typical values:
- `0.5` → Very strict (recommended for attendance)
- `0.6` → Standard (face-api.js default)
- `0.7` → Permissive

---

## Known browser constraints

| Constraint | Notes |
|-----------|-------|
| HTTPS only | `localhost` is exempt; use ngrok for device testing |
| iOS Safari | `getUserMedia` works since iOS 14.3 |
| Model download | ~6MB first load, then cached by service worker |
| Web Workers | face-api.js runs on main thread — UI may stutter briefly during processing |
