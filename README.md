# 📱 MyShop: Flutter Phone Shop

**🔗 Live demo:** https://nainezz.github.io/MyShop/

A shopping app for **ex-UK and ex-USA phones** in Nairobi, built with **Flutter** and **Firebase**. Shoppers sign up, browse and filter phones, check specs, order through checkout or WhatsApp, and track their orders. Sellers list and manage their own phones.

Version 2 rebuilds the original 2022 app on **Dart 3** with null safety and Material 3. Existing accounts, products and orders keep working.

## Features

**For shoppers**
- **Sign up and log in** with Firebase Auth. Sessions are remembered and expire automatically.
- **Search** by model, brand or storage, for example "13 Pro" or "256GB".
- **Filters:** brand chips, **ex-UK / ex-USA**, favourites only, plus **sorting** by newest or price.
- **Phone pages** with storage, grade (A+, A, B), origin, battery health and stock status.
- **Ask on WhatsApp:** one tap opens a pre-filled message about that phone.
- **Cart** with quantity controls and swipe to remove.
- **Checkout** collects a phone number and delivery details, then offers to send the order on WhatsApp.
- **My orders** with status badges: Pending, Confirmed, Delivered, Cancelled.

**For sellers**
- **Manage my listings:** add, edit and delete phones, with dropdowns for brand, storage and grade, a photo preview, and an in-stock switch.

## Tech stack

| | |
|---|---|
| Framework | Flutter 3 (Dart 3, null safety, Material 3) |
| State management | Provider 6 (`ChangeNotifier`, `ChangeNotifierProxyProvider`) |
| Backend | Firebase Realtime Database and Firebase Auth, over REST |
| Packages | `http`, `intl`, `shared_preferences`, `url_launcher` |
| CI/CD | GitHub Actions: analyze, test and build every branch; publish `main` to GitHub Pages |

## Project structure

```
lib/
├── main.dart               # Providers, theme and routes
├── config.dart             # Firebase project, WhatsApp number, currency
├── theme.dart              # Material 3 theme (light and dark)
├── models/                 # Phone options (brands, grades...), HttpException
├── providers/              # auth, products (search/filter/sort), product, cart, orders
├── screens/                # auth, shop, product detail, cart, orders, listings, edit
├── widgets/                # product card, image, spec chips, drawer
└── utils/format.dart       # KES formatting and WhatsApp messages
test/models_test.dart       # Unit tests for models, cart, filters and formatting
database.rules.json         # Firebase security rules
```

## Getting started

```bash
git clone https://github.com/nainezz/MyShop.git
cd MyShop
flutter pub get
flutter run -d chrome     # or any connected device
flutter test
```

Settings such as the Firebase project and the WhatsApp number live in `lib/config.dart`.

## Firebase security rules

`database.rules.json` makes sure that:
- only logged-in users can read products,
- sellers can only change or delete **their own** listings,
- each user can only read and write **their own** orders and favourites.

To apply them, go to Firebase console → Realtime Database → **Rules**, paste the file's contents and click **Publish**.

Order status is updated by the shop owner from the Firebase console (`orders/<userId>/<orderId>/status`: `pending`, `confirmed`, `delivered` or `cancelled`).

## Author

**Nainezz**, a software engineer and accountant in Nairobi, Kenya · [Portfolio](https://nainezz.github.io/portfolio/) · [GitHub](https://github.com/nainezz)
