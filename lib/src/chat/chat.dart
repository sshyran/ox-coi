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

import 'dart:io';

import 'package:delta_chat_core/delta_chat_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ox_coi/src/adaptiveWidgets/adaptive_app_bar.dart';
import 'package:ox_coi/src/adaptiveWidgets/adaptive_icon.dart';
import 'package:ox_coi/src/adaptiveWidgets/adaptive_icon_button.dart';
import 'package:ox_coi/src/adaptiveWidgets/adaptive_superellipse_icon.dart';
import 'package:ox_coi/src/chat/chat_bloc.dart';
import 'package:ox_coi/src/chat/chat_change_bloc.dart';
import 'package:ox_coi/src/chat/chat_change_event_state.dart';
import 'package:ox_coi/src/chat/chat_composer_bloc.dart';
import 'package:ox_coi/src/chat/chat_composer_event_state.dart';
import 'package:ox_coi/src/chat/chat_composer_mixin.dart';
import 'package:ox_coi/src/chat/chat_event_state.dart';
import 'package:ox_coi/src/chat/chat_profile.dart';
import 'package:ox_coi/src/contact/contact_change_bloc.dart';
import 'package:ox_coi/src/contact/contact_change_event_state.dart';
import 'package:ox_coi/src/data/contact_extension.dart';
import 'package:ox_coi/src/invite/invite_mixin.dart';
import 'package:ox_coi/src/l10n/l.dart';
import 'package:ox_coi/src/l10n/l10n.dart';
import 'package:ox_coi/src/lifecycle/lifecycle_bloc.dart';
import 'package:ox_coi/src/lifecycle/lifecycle_event_state.dart';
import 'package:ox_coi/src/message/message_item.dart';
import 'package:ox_coi/src/message/message_list_bloc.dart';
import 'package:ox_coi/src/message/message_list_event_state.dart';
import 'package:ox_coi/src/navigation/navigatable.dart';
import 'package:ox_coi/src/navigation/navigation.dart';
import 'package:ox_coi/src/share/shared_data.dart';
import 'package:ox_coi/src/ui/color.dart';
import 'package:ox_coi/src/ui/custom_theme.dart';
import 'package:ox_coi/src/ui/dimensions.dart';
import 'package:ox_coi/src/ui/strings.dart';
import 'package:ox_coi/src/utils/dialog_builder.dart';
import 'package:ox_coi/src/utils/keyMapping.dart';
import 'package:ox_coi/src/utils/key_generator.dart';
import 'package:ox_coi/src/utils/text.dart';
import 'package:ox_coi/src/utils/toast.dart';
import 'package:ox_coi/src/widgets/avatar.dart';
import 'package:ox_coi/src/widgets/state_info.dart';
import 'package:path/path.dart' as Path;
import 'package:url_launcher/url_launcher.dart';

import 'chat_create_mixin.dart';

class Chat extends StatefulWidget {
  final int chatId;
  final int messageId;
  final String newMessage;
  final String newPath;
  final int newFileType;
  final SharedData sharedData;
  final bool headlessStart;

  Chat({@required this.chatId, this.messageId, this.newMessage, this.newPath, this.newFileType, this.sharedData, this.headlessStart = false});

  @override
  _ChatState createState() => new _ChatState();
}

class _ChatState extends State<Chat> with ChatComposer, ChatCreateMixin, InviteMixin {
  Navigation navigation = Navigation();
  ChatBloc _chatBloc = ChatBloc();
  MessageListBloc _messageListBloc = MessageListBloc();
  ChatComposerBloc _chatComposerBloc = ChatComposerBloc();
  ChatChangeBloc _chatChangeBloc = ChatChangeBloc();

  // Ignoring false positive https://github.com/felangel/bloc/issues/587
  // ignore: close_sinks
  LifecycleBloc _lifecycleBloc;

  final TextEditingController _textController = new TextEditingController();
  bool _isComposingText = false;
  bool _isLocked = false;
  bool _isStopped = false;
  String _composingAudioTimer;
  List<double> _dbPeakList;
  String _filePath = "";
  int _knownType;
  FileType _selectedFileType;
  String _selectedExtension = "";
  String _fileName = "";
  String _phoneNumbers;
  var _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    navigation.current = Navigatable(Type.chat, params: [widget.chatId]);
    _chatBloc.add(RequestChat(chatId: widget.chatId, isHeadless: widget.headlessStart, messageId: widget.messageId));
    _chatBloc.add(ClearNotifications());
    _chatBloc.listen((state) {
      if (state is ChatStateSuccess) {
        _phoneNumbers = state.phoneNumbers;
        _messageListBloc.add(RequestMessages(chatId: widget.chatId, messageId: widget.messageId));
        if (widget.newMessage != null || widget.newPath != null) {
          if (widget.newPath.isEmpty) {
            _messageListBloc.add(SendMessage(text: widget.newMessage));
          } else {
            _messageListBloc.add(SendMessage(path: widget.newPath, fileType: widget.newFileType, text: widget.newMessage));
          }
        }
      }
    });
    _chatComposerBloc.listen((state) => handleChatComposer(state));
    _messageListBloc.listen((state) {
      if (state is MessagesStateSuccess) {
        if (_lifecycleBloc.currentBackgroundState == AppLifecycleState.paused.toString()) {
          return;
        }
        _chatChangeBloc.add(ChatMarkMessagesSeen(messageIds: state.messageIds));
      }
    });

    if (widget.sharedData != null) {
      if (widget.sharedData.mimeType.contains("text/")) {
        _textController.text = widget.sharedData.text;
        setState(() {
          _isComposingText = true;
        });
      } else {
        setFileData();
        if (widget.sharedData.text.isNotEmpty) {
          _textController.text = widget.sharedData.text;
          setState(() {
            _isComposingText = true;
          });
        }
      }
    }
  }

  void setFileData() {
    var path = widget.sharedData.path;
    FileType type;
    switch (widget.sharedData.mimeType) {
      case "image/*":
        type = FileType.IMAGE;
        break;
      case "audio/*":
        type = FileType.AUDIO;
        break;
      case "video/*":
        type = FileType.VIDEO;
        break;
      default:
        type = FileType.ANY;
        break;
    }
    setState(() {
      _filePath = path;
      _selectedFileType = type;
      _fileName = widget.sharedData.fileName;
      _isComposingText = true;
    });
  }

  void handleChatComposer(ChatComposerState state)async {
    if (state is ChatComposerRecordingAudio) {
      setState(() {
        _composingAudioTimer = state.timer;
      });
    } else if (state is ChatComposerDBPeakUpdated) {
      setState(() {
        _dbPeakList = state.dbPeakList;
      });
    } else if (state is ChatComposerRecordingAudioStopped) {
      if (state.filePath != null) {
        _filePath = state.filePath;
        _knownType = ChatMsg.typeVoice;
      }
      setState(() {
        _isStopped = true;
      });
    } else if(state is ChatComposerRecordingAudioAborted){
      await Future.delayed(Duration(microseconds: 100));
      setState(() {
        _composingAudioTimer = null;
        _dbPeakList = null;
        _isStopped = false;
        _isLocked = false;
      });
    } else if (state is ChatComposerRecordingImageOrVideoStopped) {
      if (state.type != 0 && state.filePath != null) {
        _filePath = state.filePath;
        _knownType = state.type;
        _onPrepareMessageSend();
      }
    } else if (state is ChatComposerRecordingFailed) {
      _composingAudioTimer = null;
      _dbPeakList = null;
      String chatComposeFailed;
      if (state.error == ChatComposerStateError.missingMicrophonePermission) {
        chatComposeFailed = L10n.get(L.chatAudioRecordingFailed);
      } else if (state.error == ChatComposerStateError.missingCameraPermission) {
        chatComposeFailed = L10n.get(L.chatVideoRecordingFailed);
      }
      showToast(chatComposeFailed);
    }
  }

  @override
  void dispose() {
    _chatBloc.close();
    _messageListBloc.close();
    _chatComposerBloc.close();
    _chatChangeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _lifecycleBloc = BlocProvider.of<LifecycleBloc>(context);
    return BlocListener(
      bloc: _lifecycleBloc,
      listener: (context, state) {
        if (state is LifecycleStateSuccess) {
          if (state.state == AppLifecycleState.resumed.toString()) {
            _messageListBloc.add(RequestMessages(chatId: widget.chatId, messageId: widget.messageId));
          }
        }
      },
      child: BlocBuilder(
        bloc: _chatBloc,
        builder: (context, state) {
          String name;
          String subTitle;
          Color color;
          bool isVerified = false;
          String imagePath = "";
          bool isGroup = false;
          if (state is ChatStateSuccess) {
            name = state.name;
            subTitle = state.subTitle;
            color = state.color;
            isVerified = state.isVerified;
            imagePath = state.avatarPath;
            isGroup = state.isGroupChat;
          } else {
            name = "";
            subTitle = "";
          }
          return Scaffold(
            appBar: AdaptiveAppBar(
              title: isInviteChat(widget.chatId)
                  ? buildRow(imagePath, name, subTitle, color, context, isVerified)
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _chatTitleTapped(),
                      child: buildRow(imagePath, name, subTitle, color, context, isVerified),
                    ),
              actions: <Widget>[
                if (!isGroup)
                  AdaptiveIconButton(
                    icon: AdaptiveIcon(icon: IconSource.phone),
                    key: Key(keyChatIconButtonIconPhone),
                    onPressed: onPhonePressed,
                    color: CustomTheme.of(context).onPrimary,
                  ),
              ],
            ),
            body: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Flexible(
                      child: MultiBlocProvider(
                        providers: [
                          BlocProvider<MessageListBloc>.value(
                            value: _messageListBloc,
                          ),
                          BlocProvider<ChatBloc>.value(
                            value: _chatBloc,
                          ),
                        ],
                        child: MessageList(scrollController: _scrollController, chatId: widget.chatId),
                      ),
                    ),
                    if (isInviteChat(widget.chatId)) buildInviteChoice(),
                    if (_filePath.isNotEmpty && _knownType != ChatMsg.typeVoice) buildPreview(),
                    Divider(height: dividerHeight),
                    if (state is ChatStateSuccess && !state.isRemoved)
                      Container(
                        decoration: BoxDecoration(color: CustomTheme.of(context).surface),
                        child: SafeArea(child: _buildTextComposer()),
                      ),
                  ],
                ),
                Visibility(
                  visible: _composingAudioTimer != null,
                  child: Positioned(
                    bottom: 72.0,
                    right: 16.0,
                    child: AdaptiveSuperellipseIcon(
                      icon: IconSource.send,
                      iconSize: 20.0,
                      color: CustomTheme.of(context).accent,
                      iconColor: CustomTheme.of(context).white,
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildInviteChoice() {
    return Column(
      children: <Widget>[
        Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(L10n.get(L.chatCreateText), style: Theme.of(context).textTheme.subhead),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ButtonTheme(
                minWidth: 120.0,
                child: OutlineButton(
                  highlightedBorderColor: CustomTheme.of(context).error,
                  onPressed: _blockContact,
                  child: Text(
                    L10n.get(L.block).toUpperCase(),
                    style: TextStyle(color: CustomTheme.of(context).error),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                  borderSide: BorderSide(color: CustomTheme.of(context).onBackground),
                ),
              ),
              ButtonTheme(
                minWidth: 120.0,
                child: OutlineButton(
                  highlightedBorderColor: CustomTheme.of(context).accent,
                  onPressed: _createChat,
                  child: Text(
                    L10n.get(L.ok).toUpperCase(),
                    style: TextStyle(color: CustomTheme.of(context).accent),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                  borderSide: BorderSide(color: CustomTheme.of(context).onBackground),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  _blockContact() {
    _messageListBloc.close();
    // Ignoring false positive https://github.com/felangel/bloc/issues/587
    // ignore: close_sinks
    ContactChangeBloc contactChangeBloc = ContactChangeBloc();
    contactChangeBloc.add(BlockContact(messageId: widget.messageId, chatId: widget.chatId));
    navigation.popUntil(context, ModalRoute.withName(Navigation.root));
  }

  _createChat() {
    _messageListBloc.close();
    createChatFromMessage(context, widget.messageId, widget.chatId);
  }

  Widget buildPreview() {
    return Column(
      children: <Widget>[
        Divider(height: dividerHeight),
        Padding(padding: EdgeInsets.all(attachmentDividerPadding)),
        SizedBox(
          height: previewMaxSize,
          child: Stack(
            fit: StackFit.loose,
            children: <Widget>[
              _selectedFileType == FileType.IMAGE || _selectedExtension == "gif"
                  ? Image.file(
                      File(_filePath),
                    )
                  : Center(
                      child: AdaptiveIcon(
                        icon: IconSource.insertDriveFile,
                        size: previewDefaultIconSize,
                        color: CustomTheme.of(context).black.withOpacity(slightly),
                      ),
                    ),
              Padding(
                padding: EdgeInsets.all(iconTextPadding),
                child: GestureDetector(
                  onTap: () => _closePreview(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CustomTheme.of(context).black.withOpacity(half),
                      borderRadius: BorderRadiusDirectional.circular(previewCloseIconBorderRadius),
                    ),
                    child: AdaptiveIcon(
                      icon: IconSource.close,
                      size: previewCloseIconSize,
                      color: CustomTheme.of(context).white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(previewFileNamePadding),
          child: Text(_fileName),
        )
      ],
    );
  }

  Row buildRow(String imagePath, String name, String subTitle, Color color, BuildContext context, bool isVerified) {
    return Row(
      children: <Widget>[
        Avatar(
          imagePath: imagePath,
          textPrimary: name,
          textSecondary: subTitle,
          color: color,
        ),
        Padding(padding: EdgeInsets.only(left: appBarAvatarTextPadding)),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.title.apply(color: CustomTheme.of(context).onSurface),
                key: Key(keyChatNameText),
              ),
              Row(
                children: <Widget>[
                  Visibility(
                    visible: _chatBloc.isGroup,
                    child: Padding(
                        padding: const EdgeInsets.only(right: iconTextPadding),
                        child: AdaptiveIcon(
                          icon: IconSource.group,
                          size: iconSize,
                        )),
                  ),
                  Visibility(
                    visible: isVerified,
                    child: Padding(
                        padding: const EdgeInsets.only(right: iconTextPadding),
                        child: AdaptiveIcon(
                          icon: IconSource.verifiedUser,
                          size: iconSize,
                        )),
                  ),
                  Expanded(
                    child: Text(
                      subTitle,
                      style: Theme.of(context).textTheme.subtitle.apply(color: CustomTheme.of(context).onSurface),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextComposer() {
    List<Widget> widgets = List();
    if(_getComposerType() != ComposerModeType.isVoiceRecording){
      widgets.add(buildLeftComposerPart(
        context: context,
        type: _getComposerType(),
        onShowAttachmentChooser: _showAttachmentChooser,
        onAudioRecordingAbort: _onAudioRecordingAbort,
      ));
    }else if(_isLocked || _isStopped){
      widgets.add(buildLeftComposerPart(
        context: context,
        type: _getComposerType(),
        onShowAttachmentChooser: _showAttachmentChooser,
        onAudioRecordingAbort: _onAudioRecordingAbort,
      ));
    } else{
      widgets.add(Padding(padding: EdgeInsets.only(left: 48.0),));
    }
    widgets.add(buildCenterComposerPart(
      context: context,
      type: _getComposerType(),
      textController: _textController,
      onTextChanged: _onInputTextChanged,
      dbPeakList: _dbPeakList,
    ));
    widgets.addAll(buildRightComposerPart(
      context: context,
      onRecordAudioPressed: _onRecordAudioPressed,
      onRecordAudioStopped: _onAudioRecordingStopped,
      onRecordAudioStoppedLongPress: _onAudioRecordingStoppedLongPress,
      onRecordAudioLocked: _onAudioRecordingLocked,
      onRecordVideoPressed: _onRecordVideoPressed,
      onCaptureImagePressed: _onCaptureImagePressed,
      type: _getComposerType(),
      onSendText: _onPrepareMessageSend,
      text: _composingAudioTimer,
      isLocked: _isLocked,
      isStopped: _isStopped,
    ));
    return IconTheme(
      data: IconThemeData(color: CustomTheme.of(context).accent),
      child: Container(
        height: 60.0,
        margin: const EdgeInsets.symmetric(horizontal: composerHorizontalPadding),
        child: BlocProvider.value(
          value: _chatComposerBloc,
          child: Row(
            children: widgets,
          ),
        ),
      ),
    );
  }

  ComposerModeType _getComposerType() {
    if (_isComposingText) {
      return ComposerModeType.isComposing;
    } else {
      if (_composingAudioTimer != null) {
        return ComposerModeType.isVoiceRecording;
      }
    }
    return ComposerModeType.compose;
  }

  void _onInputTextChanged(String text) {
    setState(() {
      _isComposingText = text.length > 0;
    });
  }

  void _onPrepareMessageSend() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
    if (isInviteChat(widget.chatId)) {
      _messageListBloc.close();
      createChatFromMessage(context, widget.messageId, widget.chatId, _handleCreateChatSuccess);
    } else {
      _onMessageSend();
    }
  }

  _handleCreateChatSuccess(int chatId) {
    navigation.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => Chat(
          chatId: chatId,
          newMessage: _textController.text,
          newPath: _filePath,
          newFileType: getType(),
        ),
      ),
      ModalRoute.withName(Navigation.root),
      Navigatable(Type.chatList),
    );
  }

  void _onMessageSend() {
    String text = _textController.text;
    _textController.clear();
    if (_filePath.isEmpty) {
      _messageListBloc.add(SendMessage(text: text));
    } else {
      int type = getType();
      _messageListBloc.add(SendMessage(path: _filePath, fileType: type, text: text, isShared: widget.sharedData != null));
    }

    _closePreview();
    setState(() {
      _knownType = null;
      _isComposingText = false;
    });
  }

  int getType() {
    int type = 0;
    if (_knownType == null) {
      switch (_selectedFileType) {
        case FileType.IMAGE:
          type = ChatMsg.typeImage;
          break;
        case FileType.VIDEO:
          type = ChatMsg.typeVideo;
          break;
        case FileType.AUDIO:
          type = ChatMsg.typeAudio;
          break;
        case FileType.CUSTOM:
          if (_selectedExtension == "gif") {
            type = ChatMsg.typeGif;
          } else {
            type = ChatMsg.typeFile;
          }
          break;
        case FileType.ANY:
          type = ChatMsg.typeFile;
          break;
      }
    } else {
      type = _knownType;
    }
    return type;
  }

  _onRecordAudioPressed(TapDownDetails details) {
    print("[_ChatState._onRecordAudioPressed] fhaar - ");
    _chatComposerBloc.add(StartAudioRecording());
  }

  _onAudioRecordingStoppedLongPress(TapUpDetails details) {
    print("[_ChatState._onAudioRecordingStoppedLongPress] fhaar - ");
    _chatComposerBloc.add(StopAudioRecording());
  }

  _onAudioRecordingStopped() {
    print("[_ChatState._onAudioRecordingStopped] fhaar - ");
    _chatComposerBloc.add(StopAudioRecording());
  }

  _onAudioRecordingLocked() {
    setState(() {
      _isLocked = true;
    });
  }

  _onAudioRecordingAbort() {
    _chatComposerBloc.add(AbortAudioRecording());
  }

  _onCaptureImagePressed() {
    _chatComposerBloc.add(StartImageOrVideoRecording(pickImage: true));
  }

  _onRecordVideoPressed() {
    _chatComposerBloc.add(StartImageOrVideoRecording(pickImage: false));
  }

  void _showAttachmentChooser() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: AdaptiveIcon(icon: IconSource.image),
                title: Text(L10n.get(L.image)),
                onTap: () => _getFilePath(FileType.IMAGE),
              ),
              ListTile(
                leading: AdaptiveIcon(icon: IconSource.videoLibrary),
                title: Text(L10n.get(L.video)),
                onTap: () => _getFilePath(FileType.VIDEO),
              ),
              ListTile(
                leading: AdaptiveIcon(icon: IconSource.pictureAsPdf),
                title: Text(pdf),
                onTap: () => _getFilePath(FileType.CUSTOM, "pdf"),
              ),
              ListTile(
                leading: AdaptiveIcon(icon: IconSource.insertDriveFile),
                title: Text(L10n.get(L.file)),
                onTap: () => _getFilePath(FileType.ANY),
              ),
            ],
          );
        });
  }

  _getFilePath(FileType fileType, [String extension]) async {
    navigation.pop(context);
    String filePath = await FilePicker.getFilePath(type: fileType, fileExtension: extension);
    if (filePath == null) {
      return;
    }
    _fileName = Path.basename(filePath);

    _selectedFileType = fileType;
    _selectedExtension = extension;
    setState(() {
      _filePath = filePath != null ? filePath : "";
      _isComposingText = _filePath.isEmpty ? false : true;
    });
  }

  void _closePreview() {
    setState(() {
      if (widget.sharedData != null) {
        _messageListBloc.add(DeleteCacheFile(path: _filePath));
      }
      _filePath = "";
      _selectedExtension = "";
      if (_textController.text.isEmpty) {
        _isComposingText = false;
      }
    });
  }

  _chatTitleTapped() {
    navigation.push(
      context,
      MaterialPageRoute(builder: (context) {
        return BlocProvider.value(
          value: _chatBloc,
          child: ChatProfile(chatId: widget.chatId, messageId: widget.messageId),
        );
      }),
    );
  }

  void onPhonePressed() {
    if (_phoneNumbers == null || _phoneNumbers.isEmpty) {
      showInformationDialog(
        context: context,
        title: L10n.get(L.contactNoPhoneNumber),
        content: L10n.get(L.contactNoPhoneNumberText),
        navigatable: Navigatable(Type.contactNoNumberDialog),
      );
    } else {
      var phoneNumberList = ContactExtension.getPhoneNumberList(_phoneNumbers);
      if (phoneNumberList.length == 1) {
        callNumber(phoneNumberList.first);
      } else {
        var phoneNumberWidgetList = List<Widget>();
        phoneNumberList.forEach((phoneNumber) {
          phoneNumberWidgetList.add(SimpleDialogOption(
            child: Text(phoneNumber),
            onPressed: () {
              navigation.pop(context);
              callNumber(phoneNumber);
            },
          ));
        });
        showNavigatableDialog(
          context: context,
          navigatable: Navigatable(Type.contactStartCallDialog),
          dialog: SimpleDialog(
            title: new Text(L10n.get(L.chatChooseCallNumber)),
            children: phoneNumberWidgetList,
          ),
        );
      }
    }
  }

  void callNumber(String phoneNumber) {
    String parsedPhoneNumber = getPhoneNumberFromString(phoneNumber);
    launch("tel://$parsedPhoneNumber");
  }
}

class MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final int chatId;

  MessageList({@required this.scrollController, @required this.chatId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: BlocProvider.of<MessageListBloc>(context),
      builder: (context, state) {
        if (state is MessagesStateSuccess) {
          if (state.messageIds.length > 0) {
            return ListView.custom(
              controller: scrollController,
              padding: new EdgeInsets.all(8.0),
              reverse: true,
              childrenDelegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    int messageId = state.messageIds[index];
                    int nextMessageId;
                    if (index < (state.messageIds.length - 1)) {
                      nextMessageId = state.messageIds[index + 1];
                    }
                    bool hasDateMarker = state.dateMarkerIds.contains(messageId);
                    var key = createKey(messageId);
                    return ChatMessageItem(
                      chatId: chatId,
                      messageId: messageId,
                      isGroupChat: BlocProvider.of<ChatBloc>(context).isGroup,
                      hasDateMarker: hasDateMarker,
                      nextMessageId: nextMessageId,
                      key: key,
                    );
                  },
                  childCount: state.messageIds.length,
                  findChildIndexCallback: (Key key) {
                    final ValueKey valueKey = key;
                    var id = extractId(valueKey);
                    var indexOf = state.messageIds.indexOf(id);
                    return indexOf;
                  }),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(listItemPaddingBig),
              child: Center(
                child: Text(
                  L10n.get(L.chatNewPlaceholder),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
        } else {
          return StateInfo(showLoading: true);
        }
      },
    );
  }
}
