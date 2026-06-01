import 'package:go_router/go_router.dart';
import 'package:input_vpn/pages/home_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home-page',
  routes: [
    GoRoute(path: '/home-page', builder: (context, state) => const HomePage()),
  ],
);
