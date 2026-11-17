# 🛍️ MyShop: Flutter E-commerce App

**🔗 Live demo:** https://nainezz.github.io/MyShop/

A full shopping app built with **Flutter**. Users sign up, browse products, save favourites, add items to a cart and place orders. Sellers can manage their own products. Data is stored in **Firebase**.

## Features

- **Authentication.** Sign up and log in with email and password through the Firebase Auth REST API. Login stays in place between sessions (`shared_preferences`) and you are logged out automatically when the token expires.
- **Product catalog.** A grid of products with images, prices and details, plus a "show favourites only" filter.
- **Favourites.** Tap the heart on any product. Favourites are saved per user.
- **Cart.** Add items, see a badge with the item count, swipe to remove an item, and see the total.
- **Orders.** Place an order from the cart and view your order history with an expandable breakdown of each order.
- **Seller area.** Add, edit and delete your own products through a validated form with an image URL preview.
- **Polish.** A splash screen, custom page transitions, pull-to-refresh and loading indicators.

## Tech stack

| | |
|---|---|
| Framework | Flutter (Dart) |
| State management | Provider (`ChangeNotifier`) |
| Backend | Firebase Realtime Database + Firebase Auth (REST) |
| Networking | `http` |
| Local storage | `shared_preferences` |
| Formatting | `intl` |

## Project structure

```
lib/
├── main.dart                 # App entry, providers and routes
├── providers/                # State: auth, products, product, cart, orders
├── screens/                  # Auth, products overview, detail, cart, orders, edit/user products, splash
├── widgets/                  # Product grid/item, cart item, order item, badge, drawer
├── models/                   # HttpException
└── helpers/custom_route.dart # Custom page transition
```

## Getting started

> This project targets **Dart 2** (`sdk: ">=2.1.0 <3.0.0"`), so use Flutter **3.7 or earlier**, or update the dependencies to run it on newer versions.

```bash
git clone https://github.com/nainezz/MyShop.git
cd MyShop
flutter pub get
flutter run
```

## Author

**Nainezz**, a software engineer in Nairobi, Kenya · [GitHub](https://github.com/nainezz)
