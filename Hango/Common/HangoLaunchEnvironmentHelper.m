#import "HangoLaunchEnvironmentHelper.h"
#import "HangoDeviceHelper.h"
#import "HangoOPIString.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

static NSString *HangoDecodeEnvBytes(const uint8_t *bytes, NSUInteger length) {
    if (length == 0) {
        return @"";
    }
    NSMutableData *data = [NSMutableData dataWithLength:length];
    uint8_t *out = data.mutableBytes;
    const uint8_t key = 0x5A;
    for (NSUInteger i = 0; i < length; i++) {
        out[i] = bytes[i] ^ key;
    }
    return [[NSString alloc] initWithBytes:out length:length encoding:NSUTF8StringEncoding] ?: @"";
}

static NSString *HangoEnvScopedSettingsKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x05, 0x05, 0x09, 0x19, 0x15, 0x0A, 0x1F, 0x1E, 0x05, 0x05 };
        value = HangoDecodeEnvBytes(bytes, sizeof(bytes));
    });
    return value;
}

static NSArray<NSString *> *HangoEnvPathTokenHints(void) {
    static NSArray<NSString *> *tokens;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t tap[] = { 0x2E, 0x3B, 0x2A };
        static const uint8_t tun[] = { 0x2E, 0x2F, 0x34 };
        static const uint8_t ppp[] = { 0x2A, 0x2A, 0x2A };
        static const uint8_t ipsec[] = { 0x33, 0x2A, 0x29, 0x3F, 0x39 };
        static const uint8_t utun[] = { 0x2F, 0x2E, 0x2F, 0x34 };
        tokens = @[
            HangoDecodeEnvBytes(tap, sizeof(tap)),
            HangoDecodeEnvBytes(tun, sizeof(tun)),
            HangoDecodeEnvBytes(ppp, sizeof(ppp)),
            HangoDecodeEnvBytes(ipsec, sizeof(ipsec)),
            HangoDecodeEnvBytes(utun, sizeof(utun)),
        ];
    });
    return tokens;
}

@implementation HangoLaunchEnvironmentHelper

+ (NSInteger)r5k8dPresence {
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

+ (NSInteger)w3p7nScopeFlag {
    NSDictionary *settings = (__bridge_transfer NSDictionary *)CFNetworkCopySystemProxySettings();
    NSString *scopedKey = HangoEnvScopedSettingsKey();
    NSDictionary *scoped = [settings[scopedKey] isKindOfClass:NSDictionary.class] ? settings[scopedKey] : nil;
    for (NSString *key in scoped) {
        NSString *lower = key.lowercaseString;
        for (NSString *token in HangoEnvPathTokenHints()) {
            if ([lower containsString:token]) {
                return 1;
            }
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
        HangoOPIKeyR5k8d(): @([self r5k8dPresence]),
        HangoOPIKeyW3p7n(): @([self w3p7nScopeFlag]),
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

+ (NSDictionary *)loginRequestPayload {
    return @{
        HangoOPILoginBodyKeyDeviceNo(): [HangoDeviceHelper deviceNo],
    };
}

@end
