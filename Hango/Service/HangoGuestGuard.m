#import "HangoGuestGuard.h"
#import "HangoSessionManager.h"
#import "HangoAppRouter.h"
#import "HangoWelcomeViewController.h"
#import "HangoEULAViewController.h"

@implementation HangoGuestGuard

+ (BOOL)needsLogin {
    return ![HangoSessionManager shared].isLoggedIn;
}

+ (BOOL)isOnAuthEntryScreen {
    UIViewController *visible = [HangoAppRouter topViewController];
    if ([visible isKindOfClass:[HangoWelcomeViewController class]]) {
        return YES;
    }
    if ([visible isKindOfClass:[HangoEULAViewController class]]) {
        return ((HangoEULAViewController *)visible).isLaunchGate;
    }
    return NO;
}

+ (BOOL)requireLogin {
    if (![self needsLogin]) {
        return YES;
    }

    if ([self isOnAuthEntryScreen]) {
        return NO;
    }

    [HangoAppRouter showAuthEntry];
    return NO;
}

@end
