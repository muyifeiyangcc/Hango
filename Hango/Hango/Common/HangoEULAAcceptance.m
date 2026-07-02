#import "HangoEULAAcceptance.h"

static NSString * const kHangoLaunchEULAAcceptedKey = @"HangoLaunchEULAAccepted";

@implementation HangoEULAAcceptance

+ (BOOL)hasAcceptedLaunchEULA {
    return [NSUserDefaults.standardUserDefaults boolForKey:kHangoLaunchEULAAcceptedKey];
}

+ (void)markLaunchEULAAccepted {
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:kHangoLaunchEULAAcceptedKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
