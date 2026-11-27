import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_controller.dart';
import 'core/prefs.dart';
import 'features/account/account_screen.dart';
import 'features/account/addresses_screen.dart';
import 'features/auth/login_screen.dart';
import 'core/orders/orders.dart';
import 'features/bag/bag_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/checkout/order_placed_screen.dart';
import 'core/catalog/models.dart';
import 'features/help/help_screens.dart';
import 'features/home/home_screen.dart';
import 'features/orders/order_detail_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/product/product_screen.dart';
import 'features/search/search_screen.dart';
import 'features/shop/shop_screen.dart';
import 'core/catalog/shop.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/wishlist/wishlist_screen.dart';
import 'l10n/app_localizations.dart';
import 'shared/free_delivery_bar.dart';

/// Routes. The four tabs (Home, Shop, Wishlist, Account) keep their own navigation stacks.
/// Screens are placeholders until each feature is built.
/// Pages that need an account (checkout, orders)
bool _needsSignIn(String path) =>
    path == '/checkout' || path.startsWith('/order/') || path.startsWith('/account/orders') || path == '/account/addresses';

final routerProvider = Provider<GoRouter>((ref) {
  // Loads the saved login as the app starts, and re-checks the redirects whenever sign-in state changes
  final authChanges = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: ref.read(onboardedProvider) ? '/' : '/welcome',
    refreshListenable: authChanges,
    // The welcome screen shows once; afterwards it's skipped even if something links to it
    redirect: (context, state) {
      final onboarded = ref.read(onboardedProvider);
      final atWelcome = state.matchedLocation == '/welcome';
      if (!onboarded && !atWelcome) return '/welcome';
      if (onboarded && atWelcome) return '/';
      final auth = ref.read(authProvider);
      // Checkout and orders need an account: guests sign in (or create one) first, then come straight back.
      // While the saved login is still loading, wait — this runs again once it's known.
      if (_needsSignIn(state.matchedLocation) && auth.value == null) {
        if (auth.isLoading && !auth.hasValue) return null;
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      // Already signed in: Sign in screen goes straight on
      if (state.matchedLocation == '/login' && auth.value != null) {
        final from = state.uri.queryParameters['from'];
        return from != null && from.startsWith('/') && !from.startsWith('//') ? from : '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              // ?category=…&trending=true&max_price=…&sort_by=… (same as the website); a new link starts fresh
              GoRoute(
                path: '/shop',
                builder: (c, s) =>
                    ShopScreen(key: ValueKey(s.uri.query), initial: ShopFilters.fromQuery(s.uri.queryParametersAll)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/wishlist', builder: (c, s) => const WishlistScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (c, s) => const AccountScreen(),
                routes: [
                  GoRoute(path: 'addresses', builder: (c, s) => const AddressesScreen()),
                  GoRoute(
                    path: 'orders',
                    builder: (c, s) => const OrdersScreen(),
                    routes: [
                      // extra = the order from the list, shown while the latest loads
                      GoRoute(
                        path: ':id',
                        builder: (c, s) => OrderDetailScreen(
                          orderId: int.parse(s.pathParameters['id']!),
                          initial: s.extra is Order ? s.extra as Order : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // extra = the card that was tapped, so the page shows at once while details load
      GoRoute(
        path: '/product/:slug',
        builder: (c, s) =>
            ProductScreen(slug: s.pathParameters['slug']!, initial: s.extra is Product ? s.extra as Product : null),
      ),
      // FAQs, shipping, privacy, terms — inside the app (/help/faq?open=returns opens that answer)
      GoRoute(
        path: '/help/:page',
        builder: (c, s) => HelpScreen(
          page: HelpPage.values.firstWhere((p) => p.name == s.pathParameters['page'], orElse: () => HelpPage.faq),
          open: s.uri.queryParameters['open'],
        ),
      ),
      GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
      // extra = the order just placed (shows at once); otherwise it's loaded
      GoRoute(
        path: '/order/:id/placed',
        builder: (c, s) =>
            OrderPlacedScreen(orderId: int.parse(s.pathParameters['id']!), order: s.extra is Order ? s.extra as Order : null),
      ),
      // /search?q=torch opens straight on the results
      GoRoute(
        path: '/search',
        builder: (c, s) => SearchScreen(initial: s.uri.queryParameters['q']),
      ),
      GoRoute(path: '/bag', builder: (c, s) => const BagScreen()),
      // /login?mode=register opens on Create account; ?from=/checkout returns there afterwards
      GoRoute(
        path: '/login',
        builder: (c, s) =>
            LoginScreen(register: s.uri.queryParameters['mode'] == 'register', from: s.uri.queryParameters['from']),
      ),
    ],
  );
});

class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FreeDeliveryBar(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            // Tapping the current tab again returns it to its first screen
            onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l.tabHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront),
                label: l.tabShop,
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_border),
                selectedIcon: const Icon(Icons.favorite),
                label: l.tabWishlist,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l.tabAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
