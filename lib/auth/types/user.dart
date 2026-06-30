// Copyright (c) 2015, 2025, Oracle and/or its affiliates.

//-----------------------------------------------------------------------------
//
// This software is dual-licensed to you under the Universal Permissive License
// (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
// 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
// either license.
//
// If you elect to accept the software under the Apache License, Version 2.0,
// the following applies:
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//-----------------------------------------------------------------------------

part of "../../auth.dart";

/// {@template persistence}
/// Types of persistence for auth state.
/// {@endtemplate}
enum Persistence {
  /// Local persistence.
  LOCAL,

  /// Indexed DB persistence.
  INDEXED_DB,

  /// Session persistence.
  SESSION,

  /// No persistence.
  NONE,
}

/// {@template action_code_settings}
/// Settings for action codes like email verification or password reset.
///
/// This class configures how action codes are handled.
///
/// {@endtemplate}
class ActionCodeSettings {
  /// Android package name.
  String? androidPackageName;

  /// Android minimum version.
  String? androidMinimumVersion;

  /// Whether to install Android app if not present.
  bool androidInstallApp;

  /// Dynamic link domain.
  String? dynamicLinkDomain;

  /// Whether to handle code in app.
  bool handleCodeInApp;

  /// iOS bundle ID.
  String? iOSBundleId;

  /// The URL for the action.
  String url;

  /// Constructs an [ActionCodeSettings].
  ///
  /// [androidPackageName] Optional Android package name.
  /// [androidMinimumVersion] Optional Android minimum version.
  /// [androidInstallApp] Whether to install app (default false).
  /// [dynamicLinkDomain] Optional dynamic link domain.
  /// [handleCodeInApp] Handle in app (default false).
  /// [iOSBundleId] Optional iOS bundle ID.
  /// [url] Required URL.
  ///
  /// Example:
  /// ```dart
  /// final settings = ActionCodeSettings(
  ///   url: 'https://example.com',
  ///   handleCodeInApp: true,
  /// );
  /// ```
  ActionCodeSettings({
    this.androidPackageName,
    this.androidMinimumVersion,
    this.androidInstallApp = false,
    this.dynamicLinkDomain,
    this.handleCodeInApp = false,
    this.iOSBundleId,
    required this.url,
  });

  /// Converts the settings to a map.
  ///
  /// Returns a map representation.
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      if (iOSBundleId != null) 'iOS': {'bundleId': iOSBundleId},
      'dynamicLinkDomain': dynamicLinkDomain,
      'url': url,
      'handleCodeInApp': handleCodeInApp,
      if (androidPackageName != null)
        'android': {
          'packageName': androidPackageName,
          'minimumVersion': androidMinimumVersion,
          'installApp': androidInstallApp,
        },
    };
  }

  @override
  /// Returns a string representation.
  String toString() {
    return '$ActionCodeSettings($asMap)';
  }
}

/// {@template user_credential}
/// Stores user's credential after sign-in.
///
/// {@endtemplate}
class UserCredential {
  /// The user.
  final User? _user;

  /// The credential.
  final AuthCredential? _credential;

  /// Constructs a [UserCredential].
  ///
  /// [user] The user.
  /// [credential] The credential.
  ///
  /// Example:
  /// ```dart
  /// final cred = UserCredential(user: myUser, credential: myCred);
  /// ```
  UserCredential({User? user, AuthCredential? credential})
    : _user = user,
      _credential = credential;

  /// Gets the user.
  User? get user => this._user;

  /// Gets the credential.
  AuthCredential? get credential => this._credential;

  @override
  /// Returns a string representation.
  String toString() {
    return 'UserCredential('
        'credential: $credential, '
        'user: $user)';
  }
}

/// {@template user_metadata}
/// Stores user's metadata like creation and last sign-in times.
///
/// {@endtemplate}
class UserMetadata {
  /// Creation timestamp.
  DateTime? _creationTimestamp;

  /// Last sign-in timestamp.
  DateTime? _lastSignInTime;

  /// Constructs a [UserMetadata].
  ///
  /// [creationTimestamp] Creation time.
  /// [lastSignInTime] Last sign-in time.
  ///
  /// Example:
  /// ```dart
  /// final meta = UserMetadata(DateTime.now(), DateTime.now());
  /// ```
  UserMetadata(this._creationTimestamp, this._lastSignInTime);

  /// Gets the creation time.
  DateTime? get creationTime => _creationTimestamp;

  /// Gets the last sign-in time.
  DateTime? get lastSignInTime => _lastSignInTime;

  @override
  /// Returns a string representation.
  String toString() {
    return 'UserMetadata(creationTime: $creationTime, lastSignInTime: $lastSignInTime)';
  }
}

/// {@template user_info}
/// Stores user information from providers.
///
/// {@endtemplate}
class UserInfo {
  /// Display name.
  String? _displayName;

  /// Email.
  String? _email;

  /// Phone number.
  String? _phoneNumber;

  /// Photo URL.
  String? _photoURL;

  /// UID.
  String? _uid;

  /// Provider ID.
  String _providerId;

  /// Constructs a [UserInfo] from data map.
  ///
  /// [data] Map containing user info.
  ///
  /// Example:
  /// ```dart
  /// final info = UserInfo({'uid': '123', 'email': 'user@example.com'});
  /// ```
  UserInfo(Map<dynamic, dynamic> data)
    : _uid = data["uid"],
      _displayName = data["displayName"],
      _email = data["email"],
      _phoneNumber = data["phoneNumber"],
      _photoURL = data["photoURL"],
      _providerId = data["providerId"];

  /// Gets the display name.
  String? get displayName => _displayName;

  /// Gets the email.
  String? get email => _email;

  /// Gets the phone number.
  String? get phoneNumber => _phoneNumber;

  /// Gets the photo URL.
  String? get photoURL => _photoURL;

  /// Gets the UID.
  String? get uid => _uid;

  /// Gets the provider ID.
  String get providerId => _providerId;

  @override
  /// Returns a string representation.
  String toString() {
    return '$UserInfo(displayName: $displayName, email: $email, phoneNumber: $phoneNumber, photoURL: $photoURL, providerId: $providerId, uid: $uid)';
  }
}

/// {@template user}
/// Represents a user.
///
/// This class holds user data and provides methods to update profile, password, etc.
///
/// {@endtemplate}
class User {
  /// Display name.
  String? _displayName;

  /// Email.
  final String? _email;

  /// UID.
  final String _uid;

  /// OCID.
  String? _ocid;

  /// Schemas.
  dynamic _schemas;

  /// Whether anonymous.
  bool _isAnonymous;

  /// Refresh token.
  String? _refreshToken;

  /// User helper.
  dynamic _userHelper;

  /// Options.
  final FusabaseOptions? _options;

  /// Auth instance.
  final FusabaseAuth _auth;

  /// Access token.
  IdTokenResult _accessToken;

  IdTokenResult? _fusabaseToken;

  /// Phone number.
  String? _phoneNumber;

  /// Photo URL.
  String? _photoURL;

  /// Provider data.
  List<UserInfo> _providerData;

  /// Metadata.
  UserMetadata _metadata;

  /// Log level.
  globals.LogLevel __logLevel;

  /// Tenant ID.
  String? _tenantId;

  /// Constructs a [User].
  ///
  /// [user] User data map.
  /// [accessToken] Access token.
  /// [refreshToken] Refresh token.
  /// [auth] Auth instance.
  ///
  /// Initializes various fields from user data.
  ///
  /// Example:
  /// ```dart
  /// final user = User(user: userData, accessToken: token, refreshToken: refresh, auth: auth);
  /// ```
  User({
    required dynamic user,
    required IdTokenResult accessToken,
    required refreshToken,
    required FusabaseAuth auth,
  }) : _auth = auth,
       _refreshToken = refreshToken,
       _accessToken = accessToken,
       _fusabaseToken = null,
       __logLevel = auth.app.logLevel,
       _ocid = user["ocid"],
       _schemas = user["schemas"],
       _phoneNumber =
           user["phoneNumbers"] != null
               ? user["phoneNumbers"][0]["value"]
               : null,
       _photoURL = user["photos"] != null ? user["photos"][0]["value"] : null,
       _displayName = user["displayName"],
       _metadata = UserMetadata(
         parseTimestampString(user["meta"]["created"]),
         parseTimestampString(user["meta"]["lastSignIn"]),
       ),
       _providerData = [
         UserInfo(<dynamic, dynamic>{
           "uid": user["id"],
           "displayName": user["displayName"],
           "email": user["emails"][0]["value"],
           "phoneNumber":
               user["phoneNumbers"] != null
                   ? user["phoneNumbers"][0]["value"]
                   : null,
           "photoURL":
               user["photos"] != null ? user["photos"][0]["value"] : null,
           "providerId": user["idp_name"],
         }),
       ],
       _email = user["emails"][0]["value"], // Look at this
       _uid = user["id"],
       _isAnonymous = false,
       _options = auth.options,
       _userHelper =
           auth.config.authType == 'idcs'
               ? IDCSUserHelper(
                 options: auth.options,
                 config: auth.config,
                 logLevel: auth.app.logLevel,
               )
               : ONPREMUserHelper(
                 options: auth.options,
                 config: auth.config,
                 logLevel: auth.app.logLevel,
               ) {
    _userHelper._setApp(auth.app);
  }

  /// Gets the display name.
  String? get displayName => this._displayName;

  /// Gets the email.
  String? get email => this._email;

  /// Gets the UID.
  String get uid => this._uid;

  /// Gets the phone number.
  String? get phoneNumber => this._phoneNumber;

  /// Gets the photo URL.
  String? get photoURL => this._photoURL;

  /// Gets the provider data.
  List<UserInfo> get providerData => this._providerData;

  /// Gets the metadata.
  UserMetadata get metadata => this._metadata;

  /// Gets the tenant ID.
  String? get tenantId => this._tenantId;

  /// Gets the refresh token.
  String? get refreshToken {
    return this._refreshToken;
  }

  /// Gets if the user is anonymous.
  bool get isAnonymous {
    return this._isAnonymous;
  }

  /// Gets the ID token quickly without refresh.
  ///
  /// Returns the current token string.
  // String getIdTokenResultFast() {
  //   return _userHelper.accessToken.token;
  // }

  /// Gets the ID token quickly without refresh.
  ///
  /// Returns the current token string.
  // String getFUSABASETokenFast() {
  //   return _userHelper.fusabaseToken.token;
  // }

  /// Gets the ID token, refreshing if necessary.
  ///
  /// [forceRefresh] Whether to force refresh (default false).
  ///
  /// Returns a [Future] with the token string.
  ///
  /// Example:
  /// ```dart
  /// String? token = await user.getIdToken(true);
  /// ```
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    IdTokenResult? laccessToken = await _auth.__getIdTokenResult(
      _auth.app.options.appID + globals.accessTokenKey,
    );
    String? lrefreshToken = await _auth.__getToken(
      _auth.app.options.appID + globals.refreshTokenKey,
    );
    if (forceRefresh || !_userHelper.vaidateAccessToken(laccessToken)) {
      dynamic tok = await _userHelper.refreshAccessToken(
        client: createClient(_auth.app),
        refreshToken: lrefreshToken,
      );
      _refreshToken = tok["refresh_token"];
      _accessToken = IdTokenResult(token: tok["access_token"]);
      laccessToken = IdTokenResult(token: tok["access_token"]);
      _auth.idTokenController.add(this);
      _auth.userController.add(this);
      _auth._syncLoginPersistence(
        tok["access_token"],
        tok["refresh_token"] ?? "",
      );
      await _auth.__setCredTokens({
        "accessToken": _accessToken,
        "refreshToken": tok["refresh_token"],
      });
    }
    return laccessToken?.token;
  }

  /// @nodoc
  Future<String?> getFUSABASEToken([bool forceRefresh = false]) async {
    if (forceRefresh || !_userHelper.vaidateFUSABASEToken(null)) {
      try {
        final token = await _userHelper.fetchFusabaseToken(
          client: createClient(_auth.app),
          url: "",
          user: this,
        );
        if (token != null && token != "") {
          _fusabaseToken = IdTokenResult(token: token);
        }
      } catch (e) {}
    }
    if (_fusabaseToken != null) {
      return _fusabaseToken?.token;
    }
    return null;
  }

  /// Gets the ID token result.
  ///
  /// [forceRefresh] Whether to force refresh (default false).
  ///
  /// Returns a [Future] with [IdTokenResult].
  ///
  /// Example:
  /// ```dart
  /// IdTokenResult result = await user.getIdTokenResult();
  /// ```
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    String accTok = await getIdToken(forceRefresh) ?? "";
    return IdTokenResult(token: accTok);
  }

  /// Updates the user's password.
  ///
  /// [oldPassword] Current password.
  /// [newPassword] New password.
  ///
  /// Returns a [Future] that completes when updated.
  ///
  /// Example:
  /// ```dart
  /// await user.updatePassword('oldPass', 'newPass');
  /// ```
  Future<void> updatePassword(String oldPassword, String newPass) async {
    await getIdToken();
    await _userHelper.updatePasswordHelper(
      client: createClient(_auth.app),
      user: this,
      newPassword: newPass,
      oldPassword: oldPassword,
    );
    _auth._syncLogoutPersistence();
  }

  /// Reloads the user data.
  ///
  /// Returns a [Future] that completes when reloaded.
  ///
  /// Example:
  /// ```dart
  /// await user.reload();
  /// ```
  Future<void> reload() async {
    if (refreshToken == null) {
      String errMessage = AuthErrorMessageTemplates.USER_REAUTHENTICATE;
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.INVALID_USER_TOK] ?? 999,
        message: errMessage,
      );
    }

    final userDetails = await _auth._authHelper.reloadUser(user: this);

    final User user = User(
      user: userDetails,
      auth: _auth,
      accessToken: _accessToken,
      refreshToken: refreshToken,
    );
    await user.getFUSABASEToken();

    _auth.__updateCurrentUser(user);
  }

  /// Updates the display name.
  ///
  /// [displayName] New display name.
  ///
  /// Returns a [Future] that completes when updated.
  ///
  /// Example:
  /// ```dart
  /// await user.updateDisplayName('New Name');
  /// ```
  Future<void> updateDisplayName(String? displayName) async {
    if (displayName == null || displayName == this.displayName) {
      return;
    }
    await _userHelper.updateProfileNameHelper(
      client: createClient(_auth.app),
      user: this,
      displayName: displayName,
    );
    await reload();
  }

  /// Updates the phone number.
  ///
  /// [phoneNumber] New phone number.
  ///
  /// Returns a [Future] that completes when updated.
  ///
  /// Example:
  /// ```dart
  /// await user.updatePhoneNumber('1234567890');
  /// ```
  Future<void> updatePhoneNumber(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber == this.phoneNumber) {
      return;
    }
    await _userHelper.updatePhoneNumberHelper(
      client: createClient(_auth.app),
      user: this,
      phoneNumber: phoneNumber,
    );
    await reload();
  }

  /// Updates the photo URL.
  ///
  /// [photoURL] New photo URL.
  ///
  /// Returns a [Future] that completes when updated.
  ///
  /// Example:
  /// ```dart
  /// await user.updatePhotoURL('https://example.com/photo.jpg');
  /// ```
  Future<void> updatePhotoURL(String? photoURL) async {
    if (photoURL == null || photoURL == this.photoURL) {
      return;
    }
    await _userHelper.updatePhotoURLHelper(
      client: createClient(_auth.app),
      user: this,
      photoURL: photoURL,
    );
    await reload();
  }

  /// Updates the profile.
  ///
  /// [displayName] Optional new display name.
  /// [photoURL] Optional new photo URL.
  ///
  /// Returns a [Future] that completes when updated.
  ///
  /// Example:
  /// ```dart
  /// await user.updateProfile(displayName: 'New Name', photoURL: 'url');
  /// ```
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    await updateDisplayName(displayName);
    await updatePhotoURL(photoURL);
  }

  /// Sends email verification.
  ///
  /// [actionCodeSettings] Optional settings.
  ///
  /// Returns a [Future] that completes when sent.
  ///
  /// Example:
  /// ```dart
  /// await user.sendEmailVerification();
  /// ```
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    await getIdToken();
    await _userHelper.sendEmailVerificationHelper(
      client: createClient(_auth.app),
      user: this,
      email: email,
      id: uid,
    );
  }

  /// Links the user account with the given credentials.
  ///
  /// [credential] The auth credential to link with.
  ///
  /// Returns a [Future] containing the user credential.
  ///
  /// Example:
  /// ```dart
  /// var cred = await user.linkWithCredential(myCredential);
  /// ```
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    await _userHelper.linkWithCredentialHelper(
      client: createClient(_auth.app),
      user: this,
      credential: credential,
    );
    await reload();
    var newCreds = UserCredential(user: this, credential: credential);
    return newCreds;
  }

  /// Links the user account with a popup-based OAuth flow.
  ///
  /// [provider] The auth provider to link with.
  ///
  /// Returns a [Future] containing the user credential.
  ///
  /// Example:
  /// ```dart
  /// var cred = await user.linkWithPopup(GoogleAuthProvider());
  /// ```
  Future<UserCredential> linkWithPopup(AuthProvider provider) async {
    var tokensObj = await _userHelper.socialLink(provider);
    var idToken = tokensObj["id_token"];
    if (provider is GoogleAuthProvider) {
      return await linkWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } else if (provider is FacebookAuthProvider) {
      return await linkWithCredential(
        FacebookAuthProvider.credential(idToken: idToken),
      );
    } else if (provider is GithubAuthProvider) {
      return await linkWithCredential(
        GithubAuthProvider.credential(idToken: idToken),
      );
    }
    return UserCredential(user: null, credential: null);
  }

  /// Initiates linking the user account with a redirect-based OAuth flow.
  ///
  /// [provider] The auth provider to link with.
  ///
  /// Returns a [Future] that completes when the redirect is initiated.
  ///
  /// Example:
  /// ```dart
  /// await user.linkWithRedirect(GoogleAuthProvider());
  /// ```
  Future<void> linkWithRedirect(AuthProvider provider) async {
    dynamic res = await _auth._authHelper.generatePKCE(provider);

    // if (!kIsWeb) {
    //   await _auth.__setToken(_auth.app.options.appID + globals.codeKey, res["code"]);
    // }
    await _auth.__setToken(
      _auth.app.options.appID + globals.loginKey,
      globals.redirectKey,
    );
    await _auth.__setToken(
      _auth.app.options.appID + globals.providerKey,
      provider.providerId,
    );
    await _auth.__setToken(
      _auth.app.options.appID + globals.codeVerifierKey,
      res["codeVerifier"],
    );
    await _userHelper.linkWithRedirectHelper(provider, res);
  }

  /// Unlinks the user from a provider.
  ///
  /// [providerId] The provider ID to unlink.
  ///
  /// Returns a [Future] containing the user.
  ///
  /// Example:
  /// ```dart
  /// var updatedUser = await user.unlink('google.com');
  /// ```
  Future<User> unlink(providerId) async {
    await _userHelper.unlinkHelper(
      client: createClient(_auth.app),
      user: this,
      providerId: providerId,
    );
    await reload();
    return this;
  }

  @override
  /// Returns a string representation of the user.
  String toString() {
    return '$User('
        'displayName: $displayName, '
        'email: $email, '
        'isAnonymous: $isAnonymous, '
        'metadata: $metadata, '
        'phoneNumber: $phoneNumber, '
        'photoURL: $photoURL, '
        'providerData, $providerData, '
        'refreshToken: $refreshToken, '
        'tenantId: $tenantId, '
        'uid: $uid)';
  }
}
