#import "HangoLaunchEnvironmentHelper.h"
#import "HangoDeviceHelper.h"
#import "HangoOPIString.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

@implementation HangoLaunchEnvironmentHelper

+ (NSInteger)useSimCard {
    if (@available(iOS 12.0, *)) {
        CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
        NSDictionary *providers = info.serviceSubscriberCellularProviders;
        if (providers.count > 0) {
            return 1;
        }
        return 0;
    }
    return 1;
}

+ (NSInteger)useVpn {
    NSDictionary *settings = (__bridge_transfer NSDictionary *)CFNetworkCopySystemProxySettings();
    NSDictionary *scoped = [settings[@"__SCOPED__"] isKindOfClass:NSDictionary.class] ? settings[@"__SCOPED__"] : nil;
    for (NSString *key in scoped) {
        NSString *lower = key.lowercaseString;
        if ([lower containsString:@"tap"] ||
            [lower containsString:@"tun"] ||
            [lower containsString:@"ppp"] ||
            [lower containsString:@"ipsec"] ||
            [lower containsString:@"utun"]) {
            return 1;
        }
    }
    return 0;
}

+ (NSArray<NSString *> *)languageList {
    NSArray<NSString *> *preferred = NSLocale.preferredLanguages;
    return preferred.count > 0 ? preferred : @[NSLocale.currentLocale.localeIdentifier ?: @"en"];
}

+ (NSArray<NSString *> *)otherAppNames {
    return @[];
}

+ (NSString *)timezone {
    return NSTimeZone.localTimeZone.name ?: @"UTC";
}

+ (NSArray<NSString *> *)keyboardLanguages {
    NSMutableArray<NSString *> *languages = [NSMutableArray array];
    for (UITextInputMode *mode in UITextInputMode.activeInputModes) {
        if (mode.primaryLanguage.length > 0 && ![languages containsObject:mode.primaryLanguage]) {
            [languages addObject:mode.primaryLanguage];
        }
    }
    if (languages.count == 0) {
        [languages addObject:@"en-US"];
    }
    return languages.copy;
}

+ (NSInteger)debugFlag {
#if DEBUG
    return 1;
#else
    return 0;
#endif
}

+ (NSDictionary *)launchOPIBody {
    return @{
        HangoOPIKeyUseSimCard(): @([self useSimCard]),
        HangoOPIKeyUseVpn(): @([self useVpn]),
        HangoOPIKeyLanguage(): [self languageList],
        HangoOPIKeyOtherAppNames(): [self otherAppNames],
        HangoOPIKeyTimezone(): [self timezone],
        HangoOPIKeyKeyboards(): [self keyboardLanguages],
        HangoOPIKeyDebug(): @([self debugFlag]),
    };
}

+ (NSDictionary *)launchRequestPayload {
    // The encrypted request body is the flat opiBody itself; opiUrl is just the POST path.
    return [self launchOPIBody];
}

+ (NSDictionary *)loginRequestPayloadWithAdjustAdid:(NSString *)adjustAdid {
    return @{
        HangoOPILoginBodyKeyDeviceNo(): [HangoDeviceHelper deviceNo],
        HangoOPILoginKeyAdjustAdid(): adjustAdid ?: @"",
    };
}

@end
