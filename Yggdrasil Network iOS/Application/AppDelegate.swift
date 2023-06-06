import UIKit

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

