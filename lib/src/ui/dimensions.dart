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

import 'dart:core';

// Flutter defaults
const buttonThemeMinWidth = 88.0; // https://api.flutter.dev/flutter/material/ButtonTheme/ButtonTheme.html

// Global
const zero = 0.0;
const dividerHeight = 1.0;
const avatarBorderRadiusMultiplier = 0.67;

// Progress
const verticalPaddingSmall = 8.0;
const verticalPadding = 16.0;

// List
const listItemHeight = 48.0;
const listItemPaddingBig = 16.0;
const listItemPadding = 16.0;
const listItemPaddingSmall = 4.0;
const listItemHeaderFontSize = 16.0;
const listAvatarRadius = 20.0;
const listAvatarDiameter = listAvatarRadius * 2;
const listAvatarTextPadding = 16.0;
const listStateInfoHorizontalPadding = 24.0;
const listStateInfoVerticalPadding = 16.0;
const listEmptyVerticalPadding = 16.0;
const listEmptyTopPadding = 24.0;
const listEmptyHorizontalPadding = 40.0;

const listInviteUnreadIndicatorFontSize = 12.0;
const listInviteUnreadIndicatorBorderRadius = 16.0;

// AppBar
const appBarAvatarTextPadding = 16.0;
const appBarElevationDefault = 4.0;

// Icons
const iconPadlockBottomPadding = 2.0;
const iconPadlockSize = 10.0;
const iconTextPadding = 4.0;
const iconFormPadding = 8.0;
const iconSize = 18.0;
const iconMessagePlaySize = 24.0;
const superellipseIconDefaultBackgroundSize = 32.0;
const superellipseIconDefaultSize = 24.0;
const iconSelectedSize = 24.0;
const iconDismissiblePadding = 20.0;

// Chat
const composerHorizontalPadding = 8.0;
const composerTextFieldPadding = 8.0;
const composeTextBorderRadius = 24.0;

// Chat profile
const chatProfileDividerPadding = 8.0;
const chatProfileVerticalPadding = 16.0;
const chatProfileButtonPadding = 8.0;

// Edit/Add contact
const editAddContactTopPadding = 32.0;
const editAddContactVerticalPadding = 32.0;
const editAddContactBigVerticalPadding = 72.0;

//Attachment preview
const attachmentDividerPadding = 4.0;
const previewMaxSize = 100.0;
const previewDefaultIconSize = 100.0;
const previewCloseIconBorderRadius = 20.0;
const previewCloseIconSize = 30.0;
const previewFileNamePadding = 4.0;
const audioFileImageWidth = 176.0;
const videoPreviewIconBackgroundWidth = 48.0;
const videoPreviewIconBackgroundHeight = 48.0;
const videoPreviewTimePositionBottom = 8.0;
const videoPreviewTimePositionLeft = 12.0;
const videoPreviewTimeBorderRadius = 24.0;
const videoPreviewTimePaddingVertical = 2.0;
const videoPreviewTimePaddingHorizontal = 8.0;

// Forms
const formHorizontalPadding = 16.0;
const formVerticalPadding = 16.0;

//GroupHeader
const groupHeaderTopPadding = 10.0;
const groupHeaderTopPaddingBig = 24.0;
const groupHeaderHorizontalPadding = 16.0;
const groupHeaderBottomPadding = 4.0;

//SettingsItem
const settingsItemHorizontalPadding = 20.0;
const settingsItemVerticalPadding = 8.0;
const settingsItemIconTextPadding = 16.0;

// Messages
const messagesHorizontalPadding = 8.0;
const messagesVerticalPadding = 8.0;
const messagesVerticalInnerPadding = 11.0;
const messagesVerticalOuterPadding = 16.0;
const messagesHorizontalInnerPadding = 16.0;
const messagesBoxRadius = 18.0;
const messagesBoxRadiusSmall = 2.0;
const messagesBlurRadius = 2.0;
const messagesFileIconSize = 30.0;
const messagesElevation = 3.0;

// Profile
const profileVerticalPadding = 8.0;
const profileSectionsVerticalPadding = 36.0;
const profileAvatarPlaceholderIconSize = 60.0;
const profileAvatarMaxRadius = 64.0;
const profileAvatarSize = 128.0;
const profileAvatarBorderRadius = 20.0;

const profileEditPhotoButtonRightPosition = 12.0;
const profileEditPhotoButtonBottomPosition = 24.0;

const editUserAvatarVerticalPadding = 24.0;
const editUserAvatarEditIconSize = 36.0;
const editUserAvatarImageMaxSize = 512;
const editUserAvatarRatio = 1.0;

// Login
const loginLogoSize = 136.0;
const loginHorizontalPadding16dp = 16.0;
const loginHorizontalPadding = 40.0;
const loginVerticalPadding = 28.0;
const loginVerticalPaddingBig = 56.0;
const loginTopPadding = 28.0;
const loginButtonWidth = 200.0;
const loginVerticalPadding8dp = 8.0;
const loginVerticalPadding12dp = 12.0;
const loginVerticalPadding24dp = 24.0;
const loginProviderIconSize = 40.0;
const loginManualSettingsSubTitlePadding = 8.0;
const loginManualSettingsPadding = 20.0;
const loginTermsAndConditionsHeightFactor = 5.0;
const loginProviderIconSizeBig = 150.0;
const loginErrorOverlayLeftPadding = 12.0;
const loginErrorOverlayIconSize = 24.0;
const loginErrorOverlayHeight = 40.0;
const loginListItemHeight = 64.0;
const loginListItemDividerHeight = 0.0;
const loginOtherProviderButtonRadius = 22.0;
const loginLogoTextPadding = 16.0;
const loginWaveTopBottomPadding = 32.0;
const loginSignInButtonHeight = 40.0;
const loginButtonPadding = 24.0;
const loginRichTextButtonPadding = 64.0;
const loginRichTextBottomPadding = 32.0;

//Password changed
const passwordChangedTitleInfoPadding = 8.0;
const passwordChangedInfoFormPadding = 24.0;
const passwordChangedFormButtonPadding = 28.0;
const passwordChangedFormFieldPadding = 12.0;

//Error banner
const errorBannerPositionLeft = 0.0;
const errorBannerPositionRight = 0.0;
const errorBannerPositionTop = 24.0;
const errorBannerElevation = 4.0;
