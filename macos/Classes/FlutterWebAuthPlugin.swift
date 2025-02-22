import AuthenticationServices
import SafariServices
import FlutterMacOS

@available(OSX 10.15, *)
public class FlutterWebAuthPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_web_auth", binaryMessenger: registrar.messenger)
        let instance = FlutterWebAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "authenticate" {
            let url = URL(string: (call.arguments as! Dictionary<String, AnyObject>)["url"] as! String)!
            let callbackURLScheme = (call.arguments as! Dictionary<String, AnyObject>)["callbackUrlScheme"] as! String
            let preferEphemeral = (call.arguments as! Dictionary<String, AnyObject>)["preferEphemeral"] as! Bool

            var keepMe: Any? = nil
            let completionHandler = { (url: URL?, err: Error?) in
                keepMe = nil

                if let err = err {
                    if case ASWebAuthenticationSessionError.canceledLogin = err {
                        result(FlutterError(code: "CANCELED", message: "User canceled login", details: nil))
                        return
                    }

                    result(FlutterError(code: "EUNKNOWN", message: err.localizedDescription, details: nil))
                    return
                }

                result(url!.absoluteString)
            }

            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)

            guard let provider = NSApplication.shared.keyWindow!.contentViewController as? FlutterViewController else {
                result(FlutterError(code: "FAILED", message: "Failed to aquire root FlutterViewController" , details: nil))
                return
            }

            session.presentationContextProvider = provider
            session.prefersEphemeralWebBrowserSession = preferEphemeral

            session.start()
            keepMe = session
        } else if (call.method == "cleanUpDanglingCalls") {
            // we do not keep track of old callbacks on macOS, so nothing to do here
            result(nil)
        } else if (call.method == "getCallbackUrl") {
            // we do not keep track of old callbacks on macOS, so nothing to do here
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}

@available(OSX 10.15, *)
extension FlutterViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
}
