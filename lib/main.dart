/*
 * OPEN-XCHANGE legal information
 *
 * All intellectual property rights in the Software are protected by
 * international copyright laws.
 *
 *
 * In some countries OX, OX Open-Xchange and open xchange
 * as well as the corresponding Logos OX Open-Xchange and OX are registered
 * trademarks of the OX Software GmbH group of companies.
 * The use of the Logos is not covered by the Mozilla Public License 2.0 (MPL 2.0).
 * Instead, you are allowed to use these Logos according to the terms and
 * conditions of the Creative Commons License, Version 2.5, Attribution,
 * Non-commercial, ShareAlike, and the interpretation of the term
 * Non-commercial applicable to the aforementioned license is published
 * on the web site https://www.open-xchange.com/terms-and-conditions/.
 *
 * Please make sure that third-party modules and libraries are used
 * according to their respective licenses.
 *
 * Any modifications to this package must retain all copyright notices
 * of the original copyright holder(s) for the original code used.
 *
 * After any such modifications, the original and derivative code shall remain
 * under the copyright of the copyright holder(s) and/or original author(s) as stated here:
 * https://www.open-xchange.com/legal/. The contributing author shall be
 * given Attribution for the derivative code and a license granting use.
 *
 * Copyright (C) 2016-2020 OX Software GmbH
 * Mail: info@open-xchange.com
 *
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the Mozilla Public License 2.0
 * for more details.
 */

import 'package:delta_chat_core/delta_chat_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:ox_coi/src/error/error_bloc.dart';
import 'package:ox_coi/src/l10n/l10n.dart';
import 'package:ox_coi/src/lifecycle/lifecycle_bloc.dart';
import 'package:ox_coi/src/lifecycle/lifecycle_event_state.dart';
import 'package:ox_coi/src/log/log_manager.dart';
import 'package:ox_coi/src/login/login.dart';
import 'package:ox_coi/src/login/password_changed.dart';
import 'package:ox_coi/src/main/main_bloc.dart';
import 'package:ox_coi/src/main/main_event_state.dart';
import 'package:ox_coi/src/main/root.dart';
import 'package:ox_coi/src/main/splash.dart';
import 'package:ox_coi/src/navigation/navigation.dart';
import 'package:ox_coi/src/platform/preferences.dart';
import 'package:ox_coi/src/push/push_bloc.dart';
import 'package:ox_coi/src/push/push_event_state.dart';
import 'package:ox_coi/src/ui/custom_theme.dart';
import 'package:ox_coi/src/widgets/view_switcher.dart';

void main() {
  final LogManager _logManager = LogManager();
  _logManager.setup(logToFile: false, logLevel: Level.INFO);

  // ignore: close_sinks
  final errorBloc = ErrorBloc();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<LifecycleBloc>(
          create: (BuildContext context) {
            var lifecycleBloc = LifecycleBloc();
            lifecycleBloc.add(ListenerSetup());
            return lifecycleBloc;
          },
        ),
        BlocProvider<PushBloc>(
          create: (BuildContext context) => PushBloc(),
        ),
        BlocProvider<ErrorBloc>(
          create: (BuildContext context) => errorBloc,
        ),
        BlocProvider<MainBloc>(
          create: (BuildContext context) => MainBloc(errorBloc),
        ),
      ],
      child: CustomTheme(
        initialThemeKey: ThemeKey.LIGHT,
        child: OxCoiApp(),
      ),
    ),
  );
}

class OxCoiApp extends StatelessWidget {
  final navigation = Navigation();

  @override
  Widget build(BuildContext context) {
    var customTheme = CustomTheme.of(context);
    return MaterialApp(
      theme: ThemeData(
        brightness: customTheme.brightness,
        backgroundColor: customTheme.background,
        scaffoldBackgroundColor: customTheme.background,
        toggleableActiveColor: customTheme.accent,
        accentColor: customTheme.accent,
        primaryIconTheme: Theme.of(context).primaryIconTheme.copyWith(
              color: customTheme.onSurface,
            ),
        primaryTextTheme: Theme.of(context).primaryTextTheme.apply(
              bodyColor: customTheme.onSurface,
            ),
      ),
      localizationsDelegates: getLocalizationsDelegates(),
      supportedLocales: L10n.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        getLocaleResolutionCallback(deviceLocale);
        return deviceLocale;
      },
      initialRoute: Navigation.root,
      routes: navigation.routesMapping,
    );
  }

  List<LocalizationsDelegate> getLocalizationsDelegates() {
    return [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];
  }

  void getLocaleResolutionCallback(Locale deviceLocale) {
    L10n.loadTranslation(deviceLocale);
    L10n.setLanguage(deviceLocale);
  }
}

class OxCoi extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OxCoiState();
}

class _OxCoiState extends State<OxCoi> {
  MainBloc _mainBloc;
  Navigation _navigation = Navigation();

  @override
  void initState() {
    super.initState();
    _mainBloc = MainBloc(BlocProvider.of<ErrorBloc>(context));
    _mainBloc.add(PrepareApp(context: context));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: _mainBloc,
      builder: (context, state) {
        Widget child;
        if (state is MainStateSuccess) {
          if (state.configured && !state.hasAuthenticationError) {
            child = Root();
          } else if (state.configured && state.hasAuthenticationError) {
            child = PasswordChanged(passwordChangedCallback: () => _loginSuccess(isRelogin: true));
          } else {
            child = Login(success: _loginSuccess);
          }
        } else {
          child = Splash();
        }
        return ViewSwitcher(child);
      },
    );
  }

  _loginSuccess({bool isRelogin = false}) {
    if (!isRelogin) {
      BlocProvider.of<PushBloc>(context).add(RegisterPushResource());
    }
    _navigation.popUntilRoot(context);
    _mainBloc.add(AppLoaded());
  }

}
