import UIKit

#if os(iOS)
class PlatformAppDelegate: UIResponder, UIApplicationDelegate {}
#elseif os(OSX)
class PlatformAppDelegate: NSObject, NSApplicationDelegate {}
#endif

@UIApplicationMain
class AppDelegate: CrossPlatformAppDelegate {
    var window: UIWindow?

    let configDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch
        self.vpnTunnelProviderManagerInit()
        return true
    }
}

