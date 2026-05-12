import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/network/api_client.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/shop/domain/shop_repository.dart';
import 'features/orders/domain/order_repository.dart';
import 'features/orders/presentation/controllers/order_controller.dart';
import 'features/cart/domain/cart_repository.dart';
import 'features/cart/presentation/controllers/cart_controller.dart';
import 'features/shop/presentation/screens/customer_home.dart';
import 'welcome_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'core/cache/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheManager.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, AuthRepository>(
          update: (_, api, __) => AuthRepository(api),
        ),
        ProxyProvider<ApiClient, ShopRepository>(
          update: (_, api, __) => ShopRepository(api),
        ),
        ProxyProvider<ApiClient, OrderRepository>(
          update: (_, api, __) => OrderRepository(api),
        ),
        ProxyProvider<ApiClient, CartRepository>(
          update: (_, api, __) => CartRepository(api),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthController(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderController(context.read<OrderRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CartController(context.read<CartRepository>()),
        ),
      ],
      child: const LocalCommerceApp(),
    ),
  );
}

class LocalCommerceApp extends StatelessWidget {
  const LocalCommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final user = authRepo.getCachedUser();

    Widget home;
    if (user != null) {
      // If user is already logged in, skip welcome/login
      if (user.role == 'Shopkeeper') {
        // You can add ShopkeeperDashboard here when ready
        home = CustomerHome(customerId: user.id); 
      } else {
        home = CustomerHome(customerId: user.id);
      }
    } else {
      home = const WelcomeScreen();
    }

    return MaterialApp(
      title: 'Local Commerce',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home,
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
