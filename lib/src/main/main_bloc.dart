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

import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:delta_chat_core/delta_chat_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:ox_coi/src/background_refresh/background_refresh_manager.dart';
import 'package:ox_coi/src/chat/chat_bloc.dart';
import 'package:ox_coi/src/chat/chat_composer_bloc.dart';
import 'package:ox_coi/src/chatlist/chat_list_bloc.dart';
import 'package:ox_coi/src/contact/contact_change_bloc.dart';
import 'package:ox_coi/src/contact/contact_item_bloc.dart';
import 'package:ox_coi/src/contact/contact_list_bloc.dart';
import 'package:ox_coi/src/contact/contact_list_event_state.dart';
import 'package:ox_coi/src/customer/customer_config.dart';
import 'package:ox_coi/src/data/config.dart';
import 'package:ox_coi/src/data/contact_extension.dart';
import 'package:ox_coi/src/data/contact_repository.dart';
import 'package:ox_coi/src/data/repository.dart';
import 'package:ox_coi/src/data/repository_manager.dart';
import 'package:ox_coi/src/error/error_bloc.dart';
import 'package:ox_coi/src/error/error_event_state.dart';
import 'package:ox_coi/src/main/main_event_state.dart';
import 'package:ox_coi/src/notifications/local_notification_manager.dart';
import 'package:ox_coi/src/notifications/notification_manager.dart';
import 'package:ox_coi/src/platform/app_information.dart';
import 'package:ox_coi/src/platform/preferences.dart';
import 'package:ox_coi/src/push/push_manager.dart';
import 'package:ox_coi/src/ui/strings.dart';
import 'package:ox_coi/src/utils/constants.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  final _logger = Logger("main_bloc");
  final _notificationManager = NotificationManager();
  final _pushManager = PushManager();
  final _localNotificationManager = LocalNotificationManager();

  Config _config = Config();
  Context _context = Context();

  DeltaChatCore _core = DeltaChatCore();
  DeltaChatCore get core => _core;

  final ErrorBloc _errorBloc;
  StreamSubscription _errorBlocSubscription;

  MainBloc(this._errorBloc) {
    _errorBlocSubscription = _errorBloc.listen((state) {
      if (state is ErrorStateUserVisibleError) {
        add(UserVisibleErrorEncountered(userVisibleError: state.userVisibleError));
      }
    });
  }

  @override
  MainState get initialState => MainStateInitial();

  @override
  Future<void> close() {
    _errorBlocSubscription.cancel();
    return super.close();
  }

  void reset(BuildContext context) {
    clearPreferences();

    _errorBlocSubscription.cancel();

    _context.close();
    _context = null;

    _config.reset();
    _config = null;

    final Repository<Chat> chatRepository = RepositoryManager.get(RepositoryType.chat);
    chatRepository.clear();

    final Repository<ChatMsg> chatMessageRepository = RepositoryManager.get(RepositoryType.chatMessage);
    chatMessageRepository.clear();

    final Repository<Contact> contactRepository = RepositoryManager.get(RepositoryType.contact);
    contactRepository.clear();

    final contactListBloc = ContactListBloc();
    contactListBloc.close();

    final contactChangeBloc = ContactChangeBloc();
    contactChangeBloc.close();

    final contactItemBloc = ContactItemBloc();
    contactItemBloc.close();

    final chatListBloc = ChatListBloc();
    chatListBloc.close();

    final chatBloc = ChatBloc();
    chatBloc.close();

    final chatComposerBloc = ChatComposerBloc();
    chatComposerBloc.close();

    _closeDatabase();

    _core.reset();
    _core = null;
    _core = DeltaChatCore();

    _context = Context();
    _config = Config();

    add(PrepareApp(context: context));
  }

  @override
  Stream<MainState> mapEventToState(MainEvent event) async* {
    if (event is PrepareApp) {
      yield MainStateLoading();
      try {
        final context = event.context;
        await _initCore();
        await _openExtensionDatabase();
        await _setupDatabaseExtensions();
        String appState = await getPreference(preferenceAppState);
        if (appState == null || appState.isEmpty) {
          await _setupDefaultValues();
        }
        await _setupBlocs();
        await _setupManagers(context);
        add(AppLoaded());

      } catch (error) {
        yield MainStateFailure(error: error.toString());
      }

    } else if (event is AppLoaded) {
      final bool configured = await _context.isConfigured();
      if (configured) {
        await _setupLoggedInAppState();
      }

      final bool hasAuthenticationError = await _checkForAuthenticationError();
      yield MainStateSuccess(configured: configured, hasAuthenticationError: hasAuthenticationError);

    } else if (event is Logout) {
      yield MainStateLogout();
    }

    if (event is UserVisibleErrorEncountered) {
      bool configured = await _context.isConfigured();
      var hasAuthenticationError = event.userVisibleError == UserVisibleError.authenticationFailed;
      yield MainStateSuccess(configured: configured, hasAuthenticationError: hasAuthenticationError);
    }
  }

  Future<void> _setupBlocs() async {
    _errorBloc.add(SetupListeners());
  }

  Future<void> _setupManagers(BuildContext context) async {
    _notificationManager.setup(context);
    _pushManager.setup(context);
    _localNotificationManager.setup();
  }

  Future<void> _loadCustomerConfig() async{
    Map<String, dynamic> jsonFile = await rootBundle.loadString(customerConfigPath).then((jsonStr) => jsonDecode(jsonStr));

    CustomerConfig customerConfig = CustomerConfig.fromJson(jsonFile);
    if(customerConfig.chats.length > 0){
      Context context = Context();
      for(CustomerChat chat in customerConfig.chats){
        int contactId = await context.createContact(chat.name, chat.email);
        await context.createChatByContactId(contactId);
      }
    }
  }

  Future<void> setupBackgroundRefreshManager(bool coiSupported) async {
    bool pullPreference = await getPreference(preferenceNotificationsPull);
    if ((pullPreference == null && !coiSupported) || (pullPreference != null && pullPreference)) {
      var backgroundRefreshManager = BackgroundRefreshManager();
      backgroundRefreshManager.setupAndStart();
    }
  }

  Future<void> _initCore() async {
    await core.init(dbName);
  }

  Future<void> _setupDefaultValues() async {
    await _config.setValue(Context.configSelfStatus, defaultStatus);
    await _config.setValue(Context.configShowEmails, Context.showEmailsOff);
    String version = await getAppVersion();
    await setPreference(preferenceAppVersion, version);
    await setPreference(preferenceAppState, AppState.initialStartDone.toString());
  }

  Future<void> _setupLoggedInAppState() async {
    var context = Context();
    bool coiSupported = await isCoiSupported(context);
    String appState = await getPreference(preferenceAppState);
    if (appState == AppState.initialStartDone.toString()) {
      if (coiSupported) {
        await context.setCoiEnabled(1, 1);
        _logger.info("Setting coi enable to 1");
        await context.setCoiMessageFilter(1, 1);
        _logger.info("Setting coi message filter to 1");
      }
      await _config.setValue(Context.configRfc724MsgIdPrefix, Context.enableChatPrefix);
      _logger.info("Setting coi message prefix to 1");
      await _loadCustomerConfig();
      await setPreference(preferenceAppState, AppState.initialLoginDone.toString());
    }
    await setupBackgroundRefreshManager(coiSupported);
    // Ignoring false positive https://github.com/felangel/bloc/issues/587
    // ignore: close_sinks
    ContactListBloc contactListBloc = ContactListBloc();
    contactListBloc.add(RequestContacts(typeOrChatId: validContacts));
  }

  Future<bool> isCoiSupported(Context context) async {
    final isCoiSupported = (await context.isCoiSupported()) == 1;
    return isCoiSupported;
  }

  Future<void> _setupDatabaseExtensions() async {
    final contactExtensionProvider = ContactExtensionProvider();
    await contactExtensionProvider.createTable();
  }

  Future<void> _openExtensionDatabase() async {
    final contactExtensionProvider = ContactExtensionProvider();
    await contactExtensionProvider.open(core.dbPath);
  }

  Future<void> _closeDatabase() async {
    final contactExtensionProvider = ContactExtensionProvider();
    await contactExtensionProvider.close();
  }

  Future<bool> _checkForAuthenticationError() async {
    return await getPreference(preferenceHasAuthenticationError) ?? false;
  }
}
