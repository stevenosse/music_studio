import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mstudio/src/core/environment.dart';
import 'package:mstudio/src/core/i18n/l10n.dart';
import 'package:mstudio/src/core/routing/app_router.dart';
import 'package:mstudio/src/core/theme/app_theme.dart';
import 'package:mstudio/src/shared/components/window_frame.dart';
import 'package:mstudio/src/shared/locator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class Application extends StatelessWidget {
  final AppRouter _appRouter;

  Application({
    super.key,
    AppRouter? appRouter,
  }) : _appRouter = appRouter ?? locator<AppRouter>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Environment.appName,
      routerConfig: _appRouter.config(
        navigatorObservers: () => [
          AutoRouteObserver(),
        ],
      ),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        I18n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => WindowFrame(child: child!),
      supportedLocales: I18n.delegate.supportedLocales,
    );
  }
}
