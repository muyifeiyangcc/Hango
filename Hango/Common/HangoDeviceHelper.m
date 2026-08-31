#import "HangoDeviceHelper.h"
#import "HangoAppConfig.h"
#import "HangoKeychainManager.h"
#import <UIKit/UIKit.h>

static NSString * const kHangoDeviceNoKeychainKey = @"hango.devid";

@implementation HangoDeviceHelper

+ (NSString *)appId {
    return HangoAppId;
}

+ (NSString *)appVersion {
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return version.length > 0 ? version : @"1.0.0";
}

+ (NSString *)deviceNo {
    NSString *stored = [HangoKeychainManager stringForKey:kHangoDeviceNoKeychainKey];
    if (stored.length > 0) {
        if (stored.length > 36) {
            NSString *identifier = [stored substringToIndex:36];
            if ([[NSUUID alloc] initWithUUIDString:identifier] != nil) {
                [HangoKeychainManager setString:identifier forKey:kHangoDeviceNoKeychainKey];
                return identifier;
            }
        }
        return stored;
    }

    NSString *idfv = UIDevice.currentDevice.identifierForVendor.UUIDString;
    if (idfv.length == 0) {
        idfv = NSUUID.UUID.UUIDString;
    }

    [HangoKeychainManager setString:idfv forKey:kHangoDeviceNoKeychainKey];
    return idfv;
}

@end
