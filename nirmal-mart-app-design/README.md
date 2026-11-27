# Nirmal Mart app — iOS & Android design

12 screens per platform (390×844), matched to nirmalmart.in.

| # | Screen | File |
|---|--------|------|
| 1 | Welcome + language (English / मराठी) | Welcome.dc.html |
| 2 | Sign in / Create account (email + password) | Login.dc.html |
| 3 | Home (offer carousel, Today's Deals countdown, categories) | Home.dc.html |
| 4 | Search (live results, recent, trending) | Search.dc.html |
| 5 | Shop / category (sort sheet, filters, skeleton loading) | Shop.dc.html |
| 6 | Product (gallery, pincode check, tabs, fly-to-bag) | Product.dc.html |
| 7 | Bag (live totals, free-delivery bar, empty state) | Bag.dc.html |
| 8 | Checkout (address, payment method, summary) | Checkout.dc.html |
| 9 | Order placed (animated tick, confetti) | Success.dc.html |
| 10 | Orders & tracking (timeline, past orders, returns) | Orders.dc.html |
| 11 | Wishlist (move to bag, empty state) | Wishlist.dc.html |
| 12 | Account (dark mode, language, help, sign out) | Account.dc.html |

## What's in this folder
- `screens/ios/`, `screens/android/` — the design source for every screen: layout, exact colours, spacing, copy and the interaction logic.
- `design-tokens.json` — colours, type scale, radii, sizes and motion specs, ready to map into a Flutter `ThemeData`.
- `canvas.json` — the canvas layout.
- `generator/generate_screens.py` — the script that produced all 24 screens (edit tokens/data at the top, re-run).

## Viewing
The `.dc.html` files are the canvas's source format and need the design canvas runtime, so they won't render
by double-clicking. To view or present the design, use the canvas link; to get images, use the canvas's
Share › Export (PNG / PDF). Read the files directly for exact values while building in Flutter.

## Placeholders to replace with live data
Product photos (icon placeholders), order numbers (#NM-XXXXXX), sample past orders, the email on Account,
some Marathi names, MRPs derived from the site's % off, and the "Apply coupon" row.

## Flutter mapping notes
- iOS: `CupertinoNavigationBar` large titles, `CupertinoSlidingSegmentedControl`, `CupertinoSwitch`, translucent tab bar.
- Android: Material 3 `NavigationBar` (pill indicator), `SearchBar`, `SegmentedButton`, `FilterChip`, `showModalBottomSheet`, outlined `TextField`s.
- Motion: `AnimatedSlide`/`AnimatedOpacity` for entrances, `AnimatedContainer` for selection states, `Hero` for product image → detail,
  a shimmer package for skeletons, `MediaQuery.disableAnimations` for reduced motion.
