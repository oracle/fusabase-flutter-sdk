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

/// {@template fusabase_auth}
/// The entry point for accessing authentication features.
///
/// This class provides methods for signing in, signing out, and managing user sessions.
/// {@endtemplate}
class FusabaseAuth {
  /// The options for the FUSABASE app.
  /// @nodoc
  final FusabaseOptions? options;

  /// The configuration for authentication.
  dynamic config;

  /// The tenant ID.
  String? tenantId;

  /// The associated FUSABASE app instance.
  final FusabaseApp app;

  /// The current authenticated user.
  /// @nodoc
  User? _currentUser;

  /// Gets the current authenticated user.
  User? get currentUser => _currentUser;

  /// The authentication helper.
  /// @nodoc
  dynamic _authHelper;

  /// Stream controller for user changes.
  /// @nodoc
  final controller = StreamController<User?>();

  /// Stream controller for ID token changes.
  /// @nodoc
  final idTokenController = StreamController<User?>();

  /// Stream controller for user changes.
  /// @nodoc
  final userController = StreamController<User?>();

  /// The log level.
  /// @nodoc
  globals.LogLevel __logLevel;

  /// The persistence manager.
  /// @nodoc
  dynamic _persistenceManager;

  /// @nodoc
  late final Future<void> _initFuture;

  /// Constructs an [FusabaseAuth] instance.
  ///
  /// [app] The FUSABASE app instance.
  ///
  /// Initializes configuration, persistence, and helpers based on app options.
  ///
  /// Returns the [FusabaseAuth] instance.
  ///
  /// Example:
  /// ```dart
  /// final auth = FusabaseAuth(app: myApp);
  /// ```
  FusabaseAuth({required this.app})
    : options = app.options,
      __logLevel = app.logLevel,
      config = getConfig(app),
      _persistenceManager = PersistenceManager(
        name: "${app.options.appID}_AUTH_STORE",
      ),
      _authHelper =
          app.config?.authType == 'base' || app.config?.authType == 'ldap'
              ? ONPREMAuthHelper(
                options: app.options,
                config: getConfig(app),
                logLevel: app.logLevel,
              )
              : IDCSAuthHelper(
                options: app.options,
                config: getConfig(app),
                logLevel: app.logLevel,
              ) {
    _authHelper._setApp(app);
    _initFuture = __initialLogin();

    if (kIsWeb) {
      void handleMessage(dynamic data) {
        try {
          dynamic message = jsonDecode(data);
          if (message["name"] == "${app.options.appID}localLogin") {
            _handleLocalLogin(message["at"], message["rt"]);
          } else if (message["name"] == "${app.options.appID}indexedDBLogin") {
            _handleIndexedDBLogin(message["at"], message["rt"]);
          } else if (message["name"] == "${app.options.appID}otherLogin") {
            _handleOtherLogin();
          } else if (message["name"] == "${app.options.appID}localLogout") {
            _handleLogout();
          }
        } catch (e) {}
      }

      _initFuture
          .whenComplete(() {
            _persistenceManager.listener.onMessage.listen((dynamic event) {
              handleMessage(event.data);
            });
          })
          .catchError((_) {
            // Startup errors are still surfaced through _initFuture awaiters.
          });
    }
  }

  /// Factory constructor to get an instance for a specific app.
  ///
  /// [app] The FUSABASE app instance.
  ///
  /// Returns an [FusabaseAuth] instance associated with the app.
  ///
  /// Example:
  /// ```dart
  /// final auth = FusabaseAuth.instanceFor(app: myApp);
  /// ```
  factory FusabaseAuth.instanceFor({required FusabaseApp app}) {
    app.auth ??= FusabaseAuth(app: app);
    return app.auth ?? FusabaseAuth(app: app);
  }

  /// Gets the default FusabaseAuth instance for the default app.
  ///
  /// Returns:
  /// The default [FusabaseAuth] instance.
  ///
  /// Example:
  /// ```dart
  /// var auth = FusabaseAuth.instance;
  /// ```
  static FusabaseAuth get instance {
    return FusabaseAuth.instanceFor(app: Fusabase.app());
  }

  /// Syncs login persistence across tabs or windows.
  ///
  /// [at] Access token.
  /// [rt] Refresh token.
  ///
  /// Broadcasts login event based on persistence type.
  /// @nodoc
  void _syncLoginPersistence(String at, String rt) {
    if (kIsWeb) {
      if (_persistenceManager.persistence.type == Persistence.LOCAL) {
        _persistenceManager.makeEvent(
          jsonEncode({
            "name": "${app.options.appID}localLogin",
            "at": at,
            "rt": rt,
          }),
        );
      } else if (_persistenceManager.persistence.type ==
          Persistence.INDEXED_DB) {
        _persistenceManager.makeEvent(
          jsonEncode({
            "name": "${app.options.appID}indexedDBLogin",
            "at": at,
            "rt": rt,
          }),
        );
      } else {
        _persistenceManager.makeEvent(
          jsonEncode({"name": "${app.options.appID}otherLogin"}),
        );
      }
    }
  }

  /// Gets the persistence manager.
  ///
  /// Returns the [PersistenceManager] instance.
  /// @nodoc
  PersistenceManager get persistentManager {
    return _persistenceManager;
  }

  /// Syncs logout persistence across tabs or windows.
  ///
  /// Broadcasts logout event for local and indexedDB persistence.
  /// @nodoc
  void _syncLogoutPersistence() {
    if (kIsWeb) {
      if (_persistenceManager.persistence.type == Persistence.LOCAL ||
          _persistenceManager.persistence.type == Persistence.INDEXED_DB) {
        _persistenceManager.makeEvent(
          jsonEncode({"name": "${app.options.appID}localLogout"}),
        );
      }
    }
  }

  /// Sets the persistence type for authentication state.
  ///
  /// [persistence] The persistence type to set.
  ///
  /// Handles switching persistence, migrating tokens if needed.
  ///
  /// Returns a [Future] that completes with a boolean indicating success.
  ///
  /// Example:
  /// ```dart
  /// bool success = await auth.setPersistence(Persistence.LOCAL);
  /// ```
  Future<bool> setPersistence(Persistence persistence) async {
    await _initFuture;
    IdTokenResult? accessToken;
    String? refreshToken;
    String? loginState;
    String? verifier;
    String? providerId;

    if (!kIsWeb) {
      throw FusabaseAuthException(
        message: AuthErrorMessageTemplates.PERSISTENCE_WEB_ONLY,
        code: 'invalid-persistence',
      );
    }
    try {
      accessToken = await __getIdTokenResult(
        app.options.appID + globals.accessTokenKey,
      );
      refreshToken = await __getToken(
        app.options.appID + globals.refreshTokenKey,
      );
    } catch (e) {
      //do nothing
    }

    for (var j = 0; j < 4; j++) {
      if (accessToken != null && refreshToken != null) {
        break;
      }

      switch (j) {
        case 0:
          _persistenceManager.setLocalPersistence();
          break;
        case 1:
          _persistenceManager.setIndexedDBPersistence();
          break;
        case 2:
          _persistenceManager.setSessionPersistence();
          break;
        case 3:
          _persistenceManager.setInMemoryPersistence();
          break;
      }

      accessToken = await __getIdTokenResult(
        app.options.appID + globals.accessTokenKey,
      );
      refreshToken = await __getToken(
        app.options.appID + globals.refreshTokenKey,
      );
    }

    await __removeCredTokens();

    if (accessToken == null || refreshToken == null) {
      await _signOutOnEvent();
      return _persistenceManager.setPersistence(persistence);
    } else {
      dynamic res = await _persistenceManager.setPersistence(persistence);
      if (!res) {
        await __setCredTokens({
          "accessToken": accessToken,
          "refreshToken": refreshToken,
        });
        return false;
      }
      await __setCredTokens({
        "accessToken": accessToken,
        "refreshToken": refreshToken,
      });
      _syncLoginPersistence(accessToken.token, refreshToken);
      dynamic userDetails;
      try {
        userDetails = await _authHelper.getUserDetails(
          accessToken: accessToken,
        );
      } catch (e) {
        __updateCurrentUser(null);
        return true;
      }

      final User user = User(
        user: userDetails,
        auth: this,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await user.getFUSABASEToken();
      __updateCurrentUser(user);
      return true;
    }
  }

  /// Handles local login from message event.
  ///
  /// [at] Access token.
  /// [rt] Refresh token.
  ///
  /// Switches to local persistence and signs in.
  ///
  /// Returns a [Future] that completes when login is handled.
  /// @nodoc
  Future<void> _handleLocalLogin(String at, String rt) async {
    if (_persistenceManager.persistence.type != Persistence.LOCAL) {
      await _signOutOnEvent();
    }
    _persistenceManager.setLocalPersistence();

    IdTokenResult? accessToken = IdTokenResult(token: at);
    String? refreshToken = rt;

    await _signInOnEvent(accessToken, refreshToken);
  }

  /// Handles IndexedDB login from message event.
  ///
  /// [at] Access token.
  /// [rt] Refresh token.
  ///
  /// Switches to indexedDB persistence and signs in.
  ///
  /// Returns a [Future] that completes when login is handled.
  /// @nodoc
  Future<void> _handleIndexedDBLogin(String at, String rt) async {
    if (_persistenceManager.persistence.type != Persistence.INDEXED_DB) {
      await _signOutOnEvent();
    }
    _persistenceManager.setIndexedDBPersistence();

    IdTokenResult? accessToken = IdTokenResult(token: at);
    String? refreshToken = rt;

    await _signInOnEvent(accessToken, refreshToken);
  }

  /// Handles other login types from message event.
  ///
  /// Signs out if current persistence is local or indexedDB.
  ///
  /// Returns a [Future] that completes when handled.
  /// @nodoc
  Future<void> _handleOtherLogin() async {
    if (_persistenceManager.persistence.type == Persistence.LOCAL ||
        _persistenceManager.persistence.type == Persistence.INDEXED_DB) {
      await _signOutOnEvent();
    }
  }

  /// Handles logout from message event.
  ///
  /// Signs out if current persistence is local or indexedDB.
  ///
  /// Returns a [Future] that completes when handled.
  /// @nodoc
  Future<void> _handleLogout() async {
    if (_persistenceManager.persistence.type == Persistence.LOCAL ||
        _persistenceManager.persistence.type == Persistence.INDEXED_DB) {
      await _signOutOnEvent();
    }
  }

  /// Performs initial login from persisted state.
  ///
  /// Checks for persisted tokens, refreshes if needed, and sets current user.
  /// @nodoc
  Future<void> __initialLogin() async {
    IdTokenResult? access_token = await __getIdTokenResult(
      app.options.appID + globals.accessTokenKey,
    );
    String? refresh_token = await __getToken(
      app.options.appID + globals.refreshTokenKey,
    );

    if ((access_token == null || refresh_token == null) && kIsWeb) {
      _persistenceManager.setSessionPersistence();
      access_token = await __getIdTokenResult(
        app.options.appID + globals.accessTokenKey,
      );
      refresh_token = await __getToken(
        app.options.appID + globals.refreshTokenKey,
      );
    }

    if (access_token == null || refresh_token == null) {
      __updateCurrentUser(null);
      _persistenceManager = PersistenceManager(
        name: "${app.options.appID}_AUTH_STORE",
      );
      return;
    }

    dynamic _helper =
        this.config.authType == 'idcs'
            ? IDCSUserHelper(
              options: options,
              config: config,
              logLevel: app.logLevel,
            )
            : ONPREMUserHelper(
              options: options,
              config: config,
              logLevel: app.logLevel,
            );
    _helper._setApp(app);

    if (_helper.vaidateAccessToken(access_token) == false) {
      await __removeCredTokens();

      try {
        dynamic tok = await _helper.refreshAccessToken(
          client: createClient(app),
          refreshToken: refresh_token,
        );
        refresh_token = tok["refresh_token"];
        access_token = IdTokenResult(token: tok["access_token"]);
      } catch (e) {
        __updateCurrentUser(null);
        return;
      }

      await __setCredTokens({
        "accessToken": access_token,
        "refreshToken": refresh_token,
      });

      if (access_token?.token != "" && refresh_token != "") {
        _syncLoginPersistence(access_token?.token ?? "", refresh_token ?? "");
      }
    }

    if (access_token == null || refresh_token == null) {
      return;
    }

    dynamic userDetails;

    try {
      userDetails = await _authHelper.getUserDetails(accessToken: access_token);
    } catch (e) {
      __updateCurrentUser(null);
      return;
    }

    final User user = User(
      user: userDetails,
      auth: this,
      accessToken: access_token,
      refreshToken: refresh_token,
    );
    await user.getFUSABASEToken();
    __updateCurrentUser(user);
  }

  /// Signs out without triggering events.
  ///
  /// Removes tokens and updates current user to null.
  ///
  /// Returns a [Future] that completes when signed out.
  /// @nodoc
  Future<void> _signOutOnEvent() async {
    try {
      await __removeCredTokens();
    } catch (e) {
      //do nothing
    }
    __updateCurrentUser(null);
  }

  /// Signs in without triggering events.
  ///
  /// [accessToken] The access token result.
  /// [refreshToken] The refresh token.
  ///
  /// Fetches user details, creates user and credential, persists tokens, updates current user.
  ///
  /// Returns a [Future] with [UserCredential] or null on failure.
  /// @nodoc
  Future<UserCredential?> _signInOnEvent(
    IdTokenResult accessToken,
    String refreshToken,
  ) async {
    dynamic userDetails;

    try {
      userDetails = await _authHelper.getUserDetails(accessToken: accessToken);
    } catch (e) {
      __updateCurrentUser(null);
      return null;
    }

    final User user = User(
      user: userDetails,
      auth: this,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await user.getFUSABASEToken();

    AuthCredential credential = EmailAuthProvider.credential(email: "");
    if (userDetails["idp_name"] == "UserNamePassword") {
      credential = EmailAuthProvider.credential(email: user.email ?? "");
    } else {
      if (userDetails["idp_name"].startsWith("google")) {
        credential = GoogleAuthProvider.credential(
          accessToken: accessToken.token,
        );
      } else if (userDetails["idp_name"].startsWith("github")) {
        credential = GithubAuthProvider.credential(
          accessToken: accessToken.token,
        );
      } else if (userDetails["idp_name"].startsWith("facebook")) {
        credential = FacebookAuthProvider.credential(
          accessToken: accessToken.token,
        );
      } else if (userDetails["idp_name"].startsWith("saml_") ||
          userDetails["idp_name"].startsWith("oidc_")) {
        credential = OAuthCredential(
          providerId: userDetails["idp_name"],
          signInMethod: userDetails["idp_name"],
          accessToken: accessToken.token,
          idToken: null,
        );
      } else if (userDetails["idp_name"].startsWith("idcs")) {
        credential = IDCSAuthProvider.credential(
          accessToken: accessToken.token,
        );
      }
    }

    final userCred = UserCredential(user: user, credential: credential);

    await __setCredTokens({
      "accessToken": accessToken,
      "refreshToken": refreshToken,
    });

    __updateCurrentUser(user);

    return userCred;
  }

  /// Internal function for getting the ID token result from persistence.
  ///
  /// [key] The storage key.
  ///
  /// Returns a [Future] with [IdTokenResult] or null if not found.
  /// @nodoc
  Future<IdTokenResult?> __getIdTokenResult(String key) async {
    String? token = await _persistenceManager.getToken(key);
    if (token == null) {
      return null;
    }
    return IdTokenResult(token: token);
  }

  /// Internal function for getting a token from persistence.
  ///
  /// [key] The storage key.
  ///
  /// Returns a [Future] with the token string or null if not found.
  /// @nodoc
  Future<String?> __getToken(String key) async {
    String? token = await _persistenceManager.getToken(key);
    if (token == null) {
      return null;
    }
    return token;
  }

  /// Internal function for setting a token in persistence.
  ///
  /// [key] The storage key.
  /// [value] The token value.
  ///
  /// Returns a [Future] with boolean indicating success.
  /// @nodoc
  Future<bool> __setToken(String key, String value) {
    return _persistenceManager.setToken(key, value);
  }

  /// Internal function for removing a token from persistence.
  ///
  /// [key] The storage key.
  ///
  /// Returns a [Future] with boolean indicating success.
  /// @nodoc
  Future<bool> __removeToken(String key) {
    return _persistenceManager.removeToken(key);
  }

  /// Internal function for getting a token from local storage.
  ///
  /// [key] The storage key.
  ///
  /// Returns a [Future] with the token string or null if not found.
  /// @nodoc
  Future<String?> __getLStoreToken(String key) async {
    String? token = await _persistenceManager.getLStoreToken(key);
    if (token == null) {
      return null;
    }
    return token;
  }

  /// Internal function for setting a token in local storage.
  ///
  /// [key] The storage key.
  /// [value] The token value.
  ///
  /// Returns a [Future] with boolean indicating success.
  /// @nodoc
  Future<bool> __setLStoreToken(String key, String value) {
    return _persistenceManager.setLStoreToken(key, value);
  }

  /// Internal function for removing a token from local storage.
  ///
  /// [key] The storage key.
  ///
  /// Returns a [Future] with boolean indicating success.
  /// @nodoc
  Future<bool> __removeLStoreToken(String key) {
    return _persistenceManager.removeLStoreToken(key);
  }

  /// Internal function to update the current user and notify streams.
  ///
  /// [currentUser] The new current user (or null).
  /// @nodoc
  void __updateCurrentUser(User? currentUser) {
    _currentUser = currentUser;
    controller.add(currentUser);
    idTokenController.add(currentUser);
    userController.add(currentUser);
  }

  /// Internal function to set credential tokens in persistence.
  ///
  /// [credDetails] Map containing accessToken and refreshToken.
  ///
  /// Returns a [Future] with boolean indicating success.
  /// @nodoc
  Future<bool> __setCredTokens(Map<String, dynamic> credDetails) async {
    if (credDetails["accessToken"] == null ||
        credDetails["refreshToken"] == null) {
      return false;
    }
    dynamic res1 = await __setToken(
      app.options.appID + globals.accessTokenKey,
      credDetails["accessToken"].token,
    );
    dynamic res2 = await __setToken(
      app.options.appID + globals.refreshTokenKey,
      credDetails["refreshToken"],
    );
    return res1 && res2;
  }

  /// Internal function to remove credential tokens from persistence.
  ///
  /// Returns a [Future] that completes when tokens are removed.
  /// @nodoc
  Future<void> __removeCredTokens() async {
    Object? tokenRemovalError;
    StackTrace? tokenRemovalStackTrace;

    try {
      await __removeToken(app.options.appID + globals.accessTokenKey);
    } catch (error, stackTrace) {
      tokenRemovalError = error;
      tokenRemovalStackTrace = stackTrace;
    }

    try {
      await __removeToken(app.options.appID + globals.refreshTokenKey);
    } catch (error, stackTrace) {
      tokenRemovalError ??= error;
      tokenRemovalStackTrace ??= stackTrace;
    }

    if (tokenRemovalError != null) {
      Error.throwWithStackTrace(tokenRemovalError, tokenRemovalStackTrace!);
    }
  }

  /// Creates a new user with the provided email and password.
  ///
  /// [email] The user's email address.
  /// [password] The user's password.
  ///
  /// Registers the user and signs them in.
  ///
  /// Returns a [Future] containing the [UserCredential] with the new user.
  ///
  /// Throws [FusabaseAuthException] if email or password is invalid or registration fails.
  ///
  /// Example:
  /// ```dart
  /// UserCredential credential = await auth.createUserWithEmailAndPassword(
  ///   email: 'user@example.com',
  ///   password: 'password123'
  /// );
  /// ```
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _initFuture;
    if (email == "" || password == "") {
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
        message: AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.INVALID_PARAM,
          ['email or password'],
        ),
        authType: null,
        stackTrace: null,
      );
    }
    await _authHelper.registerUser(
      client: createClient(app),
      email: email,
      password: password,
      url: "",
    );

    return signInWithEmailAndPassword(email: email, password: password);
  }

  /// Internal helper to create UserCredential after registration.
  ///
  /// [userData] Data from registration including tokens and user details.
  ///
  /// Creates user, credential, persists tokens, updates current user.
  ///
  /// Returns the [UserCredential].
  /// @nodoc
  Future<UserCredential> _createCredentials(dynamic userData) async {
    IdTokenResult accessToken = userData["access_token"];
    String refreshToken = userData["refresh_token"];
    final userDetails = userData["userDetails"];
    final User user = User(
      user: userDetails,
      auth: this,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await user.getFUSABASEToken();

    final AuthCredential creds = EmailAuthProvider.credential(
      email: user.email ?? "",
    );
    final userCred = UserCredential(user: user, credential: creds);

    await __setCredTokens({
      "accessToken": accessToken,
      "refreshToken": refreshToken,
    });
    __updateCurrentUser(user);
    _syncLoginPersistence(accessToken.token, refreshToken);
    return userCred;
  }

  /// Signs in a user with email and password.
  ///
  /// [email] The user's email address.
  /// [password] The user's password.
  ///
  /// Authenticates the user and sets up session.
  ///
  /// Returns a [Future] containing the [UserCredential].
  ///
  /// Throws [FusabaseAuthException] if email or password is invalid or authentication fails.
  ///
  /// Example:
  /// ```dart
  /// UserCredential credential = await auth.signInWithEmailAndPassword(
  ///   email: 'user@example.com',
  ///   password: 'password123'
  /// );
  /// ```
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _initFuture;
    if (email == "" || password == "") {
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
        message: AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.INVALID_PARAM,
          ['email or password'],
        ),
        authType: null,
        stackTrace: null,
      );
    }
    final credDetails = await this._authHelper.authenticateAndGetDetails(
      email: email,
      password: password,
    );
    final User user = User(
      user: credDetails["userDetails"],
      auth: this,
      accessToken: credDetails["accessToken"],
      refreshToken: credDetails["refreshToken"],
    );

    await __setCredTokens({
      "accessToken": credDetails["accessToken"],
      "refreshToken": credDetails["refreshToken"],
    });
    await user.getFUSABASEToken();

    final AuthCredential creds = EmailAuthProvider.credential(email: email);
    final userCred = UserCredential(user: user, credential: creds);

    __updateCurrentUser(user);

    _syncLoginPersistence(
      credDetails["accessToken"].token,
      credDetails["refreshToken"],
    );

    return userCred;
  }

  /// Signs in using a popup window.
  ///
  /// [provider] The authentication provider (e.g. GoogleAuthProvider).
  ///
  /// Opens popup for provider sign in.
  ///
  /// Returns a [Future] containing the [UserCredential].
  ///
  /// Example:
  /// ```dart
  /// UserCredential credential = await auth.signInWithPopup(GoogleAuthProvider());
  /// ```
  Future<UserCredential> signInWithPopup(dynamic provider) async {
    await _initFuture;
    dynamic res = await this._authHelper.signInWithBrowserHelper(provider);
    final authnToken = null;

    final access_token = IdTokenResult(token: res["access_token"]);
    final refresh_token = res["refresh_token"];

    final userDetails = await _authHelper.getUserDetails(
      accessToken: access_token,
    );

    final User user = User(
      user: userDetails,
      auth: this,
      accessToken: access_token,
      refreshToken: refresh_token,
    );
    await user.getFUSABASEToken();

    var userCred;

    if (provider is GoogleAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: GoogleAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is FacebookAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: FacebookAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is GithubAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: GithubAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is SAMLAuthProvider || provider is OAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: provider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is IDCSAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: IDCSAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    }

    await __setCredTokens({
      "accessToken": access_token,
      "refreshToken": refresh_token,
    });
    __updateCurrentUser(user);
    return userCred;
  }

  /// Signs in using credentials.
  ///
  /// [credential] The AuthCredential from provider.
  ///
  /// Authenticates using the credential.
  ///
  /// Returns a [Future] containing the [UserCredential].
  ///
  /// Example:
  /// ```dart
  /// UserCredential credential = await auth.signInWithCredential(myCredential);
  /// ```
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    await _initFuture;
    final credDetails = await _authHelper.signInWithCredentialHelper(
      client: createClient(app),
      credential: credential,
    );

    final access_token = IdTokenResult(token: credDetails["access_token"]);
    final refresh_token = credDetails["refresh_token"];
    final userDetails = await _authHelper.getUserDetails(
      accessToken: access_token,
    );

    final User user = User(
      user: userDetails,
      auth: this,
      accessToken: access_token,
      refreshToken: refresh_token,
    );
    await user.getFUSABASEToken();
    var userCred;
    final authnToken = null;

    if (credential is GoogleAuthCredential) {
      userCred = UserCredential(
        user: user,
        credential: GoogleAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (credential is FacebookAuthCredential) {
      userCred = UserCredential(
        user: user,
        credential: FacebookAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (credential is GithubAuthCredential) {
      userCred = UserCredential(
        user: user,
        credential: GithubAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (credential is IDCSAuthCredential) {
      userCred = UserCredential(
        user: user,
        credential: IDCSAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    }

    await __setCredTokens({
      "accessToken": access_token,
      "refreshToken": refresh_token,
    });
    __updateCurrentUser(user);
    return userCred;
  }

  /// Initiates sign in with redirect.
  ///
  /// [provider] The authentication provider.
  ///
  /// Redirects to provider sign in page.
  ///
  /// Returns a [Future] that completes when redirect is initiated.
  ///
  /// Example:
  /// ```dart
  /// await auth.signInWithRedirect(GoogleAuthProvider());
  /// ```
  Future<void> signInWithRedirect(AuthProvider provider) async {
    await _initFuture;
    dynamic res = await _authHelper.generatePKCE(provider);

    await __setLStoreToken(
      app.options.appID + globals.loginKey,
      globals.redirectKey,
    );
    await __setLStoreToken(
      app.options.appID + globals.providerKey,
      provider.providerId,
    );
    await __setLStoreToken(
      app.options.appID + globals.codeVerifierKey,
      res["codeVerifier"],
    );
    await _authHelper.signInWithRedirectHelper(provider, res);
  }

  /// Gets the result of a redirect sign in.
  ///
  /// Retrieves result after redirect back from provider.
  ///
  /// Returns a [Future] containing the [UserCredential].
  ///
  /// Example:
  /// ```dart
  /// UserCredential credential = await auth.getRedirectResult();
  /// ```
  Future<UserCredential> getRedirectResult() async {
    await _initFuture;
    String? loginState = await __getLStoreToken(
      app.options.appID + globals.loginKey,
    );
    if (loginState != globals.redirectKey) {
      return UserCredential(user: null, credential: null);
    }
    String? code;
    if (kIsWeb) {
      code = await _authHelper.getCodeFromURL();
    } else {
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: AuthErrorMessageTemplates.METHOD_NOT_IMPLEMENTED,
        authType: config.authType.toUpperCase(),
      );
    }
    String? verifier = await __getLStoreToken(
      app.options.appID + globals.codeVerifierKey,
    );
    String? providerId = await __getLStoreToken(
      app.options.appID + globals.providerKey,
    );

    if (code == null || verifier == null || providerId == null || code == "") {
      return UserCredential(user: null, credential: null);
    }

    dynamic res = await _authHelper.getTokensAfterRedirect(
      client: createClient(app),
      code: code,
      verifier: verifier,
    );

    if (res != null && res["id_token"] != null && res["access_token"] == null) {
      if (providerId == GoogleAuthProvider.PROVIDER_ID) {
        return await _currentUser!.linkWithCredential(
          GoogleAuthProvider.credential(idToken: res["id_token"]),
        );
      } else if (providerId == FacebookAuthProvider.PROVIDER_ID) {
        return await _currentUser!.linkWithCredential(
          FacebookAuthProvider.credential(idToken: res["id_token"]),
        );
      } else if (providerId == GithubAuthProvider.PROVIDER_ID) {
        return await _currentUser!.linkWithCredential(
          GithubAuthProvider.credential(idToken: res["id_token"]),
        );
      }
    }

    final authnToken = null;

    final access_token = IdTokenResult(token: res["access_token"]);
    final refresh_token = res["refresh_token"];

    final userDetails = await _authHelper.getUserDetails(
      accessToken: access_token,
    );

    final User user = User(
      user: userDetails,
      auth: this,
      accessToken: access_token,
      refreshToken: refresh_token,
    );
    await user.getFUSABASEToken();

    var userCred;
    dynamic provider = _authHelper.getProvider(providerId);

    if (provider is GoogleAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: GoogleAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is FacebookAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: FacebookAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is GithubAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: GithubAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is SAMLAuthProvider || provider is OAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: provider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    } else if (provider is IDCSAuthProvider) {
      userCred = UserCredential(
        user: user,
        credential: IDCSAuthProvider.credential(
          accessToken: access_token.token,
          idToken: authnToken,
        ),
      );
    }

    await __setCredTokens({
      "accessToken": access_token,
      "refreshToken": refresh_token,
    });
    __updateCurrentUser(user);
    // if (!kIsWeb) {
    //   await __removeToken(app.options.appID + globals.codeKey);
    // }
    await __removeLStoreToken(app.options.appID + globals.codeVerifierKey);
    if (kIsWeb) {
      _authHelper.removeCodeParamFromUrl();
    }
    return userCred;
  }

  /// Signs out the current user.
  ///
  /// Performs sign out and clears persistence.
  ///
  /// Returns a [Future] that completes when signed out.
  ///
  /// Example:
  /// ```dart
  /// await auth.signOut();
  /// ```
  Future<void> signOut() async {
    await _initFuture;
    try {
      await _authHelper.performSignOut(currentUser?.refreshToken);
    } finally {
      try {
        await __removeCredTokens();
      } finally {
        __updateCurrentUser(null);
        _syncLogoutPersistence();
      }
    }
  }

  /// Sends a password reset email.
  ///
  /// [email] The email address.
  ///
  /// Sends reset link to the email.
  ///
  /// Returns a [Future] that completes when email is sent.
  ///
  /// Throws [FusabaseAuthException] on failure.
  ///
  /// Example:
  /// ```dart
  /// await auth.sendPasswordResetEmail(email: 'user@example.com');
  /// ```
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _initFuture;
    await _authHelper.sendPasswordResetEmailHelper(
      client: createClient(app),
      email: email,
    );
  }

  /// Verifies a password reset code.
  ///
  /// [code] The reset code from email.
  ///
  /// Returns a [Future] containing the associated email.
  ///
  /// Throws [FusabaseAuthException] if code is invalid.
  ///
  /// Example:
  /// ```dart
  /// String email = await auth.verifyPasswordResetCode('resetCode');
  /// ```
  Future<String> verifyPasswordResetCode(String code) async {
    await _initFuture;
    return await _authHelper.verifyPasswordResetCodeHelper(
      client: createClient(app),
      code: code,
    );
  }

  /// Confirms password reset with a new password.
  ///
  /// [code] The reset code.
  /// [newPassword] The new password.
  ///
  /// Resets the password using the code.
  ///
  /// Returns a [Future] that completes when password is reset.
  ///
  /// Throws [FusabaseAuthException] on failure.
  ///
  /// Example:
  /// ```dart
  /// await auth.confirmPasswordReset(code: 'resetCode', newPassword: 'newPass');
  /// ```
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _initFuture;
    await _authHelper.confirmPasswordResetHelper(
      client: createClient(app),
      code: code,
      newPassword: newPassword,
    );
  }

  /// Provides a stream of authentication state changes.
  ///
  /// Streams changes to the signed-in user.
  ///
  /// Returns a [Stream] of [User?] values.
  ///
  /// Example:
  /// ```dart
  /// auth.authStateChanges().listen((user) {
  ///   if (user != null) print('Signed in');
  /// });
  /// ```
  Stream<User?> authStateChanges() => controller.stream;

  /// Provides a stream of ID token changes.
  ///
  /// Streams changes when ID token is refreshed.
  ///
  /// Returns a [Stream] of [User?] values.
  ///
  /// Example:
  /// ```dart
  /// auth.idTokenChanges().listen((user) {
  ///   // Handle token change
  /// });
  /// ```
  Stream<User?> idTokenChanges() => idTokenController.stream;

  /// Provides a stream of user changes.
  ///
  /// Streams changes to the user profile.
  ///
  /// Returns a [Stream] of [User?] values.
  ///
  /// Example:
  /// ```dart
  /// auth.userChanges().listen((user) {
  ///   // Handle user change
  /// });
  /// ```
  Stream<User?> userChanges() => userController.stream;

  @override
  /// Returns a string representation of the auth instance.
  String toString() {
    return 'FusabaseAuth(app: ${app.name})';
  }
}

/// Gets the configuration for authentication.
///
/// [app] The FUSABASE app instance.
///
/// Determines config based on auth type.
///
/// Returns the configuration object.
/// @nodoc
dynamic getConfig(FusabaseApp app) {
  dynamic projectConfig = app.options;
  FusabaseOptions options = app.options;

  if (projectConfig.authType == "idcs") {
    return IDCSConfig(
      domainURL:
          "${options.ordsHost}_/baas-services/idm/idcs/${projectConfig.projectID}/",
      authID: projectConfig.authID ?? "",
      projectID: projectConfig.projectID,
      authType: app.options.authType,
      idcsDomainURL: projectConfig.idcsDomainURL ?? "",
    );
  }

  return ONPREMConfig(
    domainURL:
        "${options.ordsHost}_/baas-services/idm/onprem/${projectConfig.projectID}/",
    authID: projectConfig.authID ?? "",
    projectID: projectConfig.projectID,
    authType: app.options.authType,
  );
}
