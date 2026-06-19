import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/network/api_client.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/shop/domain/shop_repository.dart';
import 'features/orders/domain/order_repository.dart';
import 'features/orders/presentation/controllers/order_controller.dart';
import 'features/cart/domain/cart_repository.dart';
import 'features/cart/presentation/controllers/cart_controller.dart';
import 'features/account/presentation/controllers/account_controller.dart';
import 'features/shop/presentation/controllers/shop_controller.dart';
import 'features/shop/presentation/screens/customer_home.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/shopkeeper/presentation/screens/shopkeeper_route_handler.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/cache/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheManager.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, AuthRemoteDataSource>(
          update: (_, api, __) => AuthRemoteDataSourceImpl(api),
        ),
        Provider<AuthLocalDataSource>(
          create: (_) => AuthLocalDataSourceImpl(),
        ),
        ProxyProvider2<AuthRemoteDataSource, AuthLocalDataSource, IAuthRepository>(
          update: (_, remote, local, __) => AuthRepositoryImpl(
            remoteDataSource: remote,
            localDataSource: local,
          ),
        ),
        ProxyProvider<IAuthRepository, LoginUseCase>(
          update: (_, repo, __) => LoginUseCase(repo),
        ),
        ProxyProvider<IAuthRepository, RegisterUseCase>(
          update: (_, repo, __) => RegisterUseCase(repo),
        ),
        ProxyProvider<IAuthRepository, GetCachedUserUseCase>(
          update: (_, repo, __) => GetCachedUserUseCase(repo),
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
          create: (context) => AuthController(
            loginUseCase: context.read<LoginUseCase>(),
            registerUseCase: context.read<RegisterUseCase>(),
            getCachedUserUseCase: context.read<GetCachedUserUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ShopController(context.read<ShopRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderController(context.read<OrderRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AccountController(context.read<OrderRepository>()),
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
    return MaterialApp(
      title: 'Vytra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
