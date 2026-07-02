#import "AppDelegate.h"
#import "HangoIAPManager.h"
#import "HangoKeyboardManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [HangoKeyboardManager install];
    [[HangoIAPManager shared] start];
    return YES;
}

@end
