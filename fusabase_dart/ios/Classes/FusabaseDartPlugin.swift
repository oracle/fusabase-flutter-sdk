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

import AuthenticationServices
import UIKit
import SafariServices
import Security
import Flutter

public class FusabaseDartPlugin: NSObject, FlutterPlugin {
    public static func register(with fusabase_registrar: FlutterPluginRegistrar) {
        let fusabase_channel = FlutterMethodChannel(name: "fusabase_dart_auth", binaryMessenger: fusabase_registrar.messenger())
        let fusabase_instance = FusabaseDartPlugin()
        fusabase_registrar.addMethodCallDelegate(fusabase_instance, channel: fusabase_channel)
        fusabase_registrar.addApplicationDelegate(fusabase_instance)
    }

    var fusabase_completionHandler: ((URL?, Error?) -> Void)?
    @available(iOS 13, *)
    private var fusabase_presentationContextProvider: FusabasePresentationContextProvider?

    public func handle(_ fusabase_call: FlutterMethodCall, result: @escaping FlutterResult) {
        if fusabase_call.method == "fusabaseauthenticate",
           let fusabase_arguments = fusabase_call.arguments as? [String: AnyObject],
           let fusabase_urlString = fusabase_arguments["url"] as? String,
           let fusabase_url = URL(string: fusabase_urlString),
           let fusabase_callbackURLScheme = fusabase_arguments["callbackUrlScheme"] as? String,
           let fusabase_options = fusabase_arguments["options"] as? [String: AnyObject] {
            
            var fusabase_sessionToKeepAlive: Any?
            fusabase_completionHandler = { (fusabase_url: URL?, fusabase_err: Error?) in
                self.fusabase_completionHandler = nil
                if #available(iOS 13, *) {
                    self.fusabase_presentationContextProvider = nil
                }
                
                if fusabase_sessionToKeepAlive != nil {
                    if #available(iOS 12, *) {
                        (fusabase_sessionToKeepAlive as! ASWebAuthenticationSession).cancel()
                    } else if #available(iOS 11, *) {
                        (fusabase_sessionToKeepAlive as! SFAuthenticationSession).cancel()
                    }
                    fusabase_sessionToKeepAlive = nil
                }

                if let fusabase_err = fusabase_err {
                    if #available(iOS 12, *), case ASWebAuthenticationSessionError.canceledLogin = fusabase_err {
                        result(FlutterError(code: "USER_CANCELED", message: "Login cancelled by the user!", details: nil))
                        return
                    }
                    if #available(iOS 11, *), case SFAuthenticationError.canceledLogin = fusabase_err {
                        result(FlutterError(code: "USER_CANCELED", message: "Login cancelled by the user!", details: nil))
                        return
                    }
                    result(FlutterError(code: "UNKNOWN", message: fusabase_err.localizedDescription, details: nil))
                    return
                }

                guard let fusabase_url = fusabase_url else {
                    result(FlutterError(code: "UNKNOWN", message: "Inappropriate url", details: nil))
                    return
                }
                result(fusabase_url.absoluteString)
            }
            
            if #available(iOS 12, *) {
                var fusabase_session: ASWebAuthenticationSession?
                if #available(iOS 17.4, *), fusabase_callbackURLScheme == "https" {
                    guard let fusabase_host = fusabase_options["httpsHost"] as? String else {
                        result(FlutterError.fusabaseinvalidHttpsHostError)
                        return
                    }
                    guard let fusabase_path = fusabase_options["httpsPath"] as? String else {
                        result(FlutterError.fusabaseinvalidHttpsPathError)
                        return
                    }
                    fusabase_session = ASWebAuthenticationSession(
                        url: fusabase_url,
                        callback: ASWebAuthenticationSession.Callback.https(host: fusabase_host, path: fusabase_path),
                        completionHandler: fusabase_completionHandler!
                    )
                } else {
                    fusabase_session = ASWebAuthenticationSession(
                        url: fusabase_url,
                        callbackURLScheme: fusabase_callbackURLScheme,
                        completionHandler: fusabase_completionHandler!
                    )
                }
                let fusabase_finalSession = fusabase_session!
                
                if #available(iOS 13, *) {
                    guard var fusabase_rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController ?? UIApplication.shared.keyWindow?.rootViewController else {
                        result(FlutterError.fusabaseacquireRootViewControllerFailed)
                        return
                    }
                    
                    while let fusabase_presentedViewController = fusabase_rootViewController.presentedViewController {
                        fusabase_rootViewController = fusabase_presentedViewController
                    }
                    
                    if let fusabase_nav = fusabase_rootViewController as? UINavigationController {
                        fusabase_rootViewController = fusabase_nav.visibleViewController ?? fusabase_rootViewController
                    }
                    
                    let fusabase_contextProvider = FusabasePresentationContextProvider(
                        viewController: fusabase_rootViewController
                    )
                    self.fusabase_presentationContextProvider = fusabase_contextProvider
                    fusabase_finalSession.presentationContextProvider = fusabase_contextProvider
                    if let fusabase_preferEphemeral = fusabase_options["preferEphemeral"] as? Bool {
                        fusabase_finalSession.prefersEphemeralWebBrowserSession = fusabase_preferEphemeral
                    }
                }
                fusabase_finalSession.start()
                fusabase_sessionToKeepAlive = fusabase_finalSession
            } else if #available(iOS 11, *) {
                let fusabase_session = SFAuthenticationSession(
                    url: fusabase_url,
                    callbackURLScheme: fusabase_callbackURLScheme,
                    completionHandler: fusabase_completionHandler!
                )
                fusabase_session.start()
                fusabase_sessionToKeepAlive = fusabase_session
            } else {
                result(FlutterError(code: "FAILED", message: "This plugin does currently not support iOS lower than iOS 11", details: nil))
            }
        } else if fusabase_call.method == "fusabasecleanUpDanglingCalls" {
            result(nil)
        } else if fusabase_call.method == "pkceredirectgenerate" {
            do {
                let codeVerifier = try PKCEHelper.generateCodeVerifier()
                let codeChallenge = try PKCEHelper.generateCodeChallenge(codeVerifier: codeVerifier)
                
                result([
                    "codeVerifier": codeVerifier,
                    "codeChallenge": codeChallenge
                ])
            } catch {
                result(FlutterError(code: "FAILED", message: "Verifier generation failed", details: nil))
            }
        } else if fusabase_call.method == "setValue" {

            guard let fusabase_arguments = fusabase_call.arguments as? [String: AnyObject],
                let key = fusabase_arguments["key"] as? String,
                let value = fusabase_arguments["value"] as? String else {
                result(false)
                return
            }

            let success = setValue(key: key, value: value)
            result(success)

        } else if fusabase_call.method == "getValue" {

            guard let fusabase_arguments = fusabase_call.arguments as? [String: AnyObject],
                let key = fusabase_arguments["key"] as? String else {
                result(nil)
                return
            }

            let value = getValue(key: key)
            result(value)

        } else if fusabase_call.method == "removeValue" {

            guard let fusabase_arguments = fusabase_call.arguments as? [String: AnyObject],
                let key = fusabase_arguments["key"] as? String else {
                result(false)
                return
            }

            let success = removeValue(key: key)
            result(success)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    public func application(
        _ fusabase_application: UIApplication,
        continue fusabase_userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        switch fusabase_userActivity.activityType {
        case NSUserActivityTypeBrowsingWeb:
            guard let fusabase_url = fusabase_userActivity.webpageURL, let fusabase_completionHandler = fusabase_completionHandler else {
                return false
            }
            fusabase_completionHandler(fusabase_url, nil)
            return true
        default:
            return false
        }
    }

    private func setValue(key: String, value: String) -> Bool {
    let data = value.data(using: .utf8)!

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data
    ]

    SecItemDelete(query as CFDictionary)
    return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
  }

  private func getValue(key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data else { return nil }

    return String(data: data, encoding: .utf8)
  }

  private func removeValue(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key
    ]
    return SecItemDelete(query as CFDictionary) == errSecSuccess
  }
}



@available(iOS 13, *)
private final class FusabasePresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return viewController?.view.window ?? UIWindow()
    }
}

fileprivate extension FlutterError {
    
    static var fusabaseinvalidHttpsPathError: FlutterError {
        return FlutterError(
            code: "OBAAS_AUTH_INVALID_HTTPS_PATH_ERROR",
            message: "Can't get path for the this scheme",
            details: nil
        )
    }

    static var fusabaseinvalidHttpsHostError: FlutterError {
        return FlutterError(
            code: "OBAAS_AUTH_INVALID_HTTPS_HOST_ERROR",
            message: "Can't get host for this scheme",
            details: nil
        )
    }

    static var fusabaseacquireRootViewControllerFailed: FlutterError {
        return FlutterError(
            code: "OBAAS_AUTH_ACQUIRE_ROOT_VIEW_CONTROLLER_FAILED",
            message: "Can't get controller for this scheme",
            details: nil
        )
    }
}
