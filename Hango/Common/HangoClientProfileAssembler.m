#import "HangoClientProfileAssembler.h"
#import "HangoDeviceHelper.h"
#import "HangoOPIString.h"
#import "HangoLexicon.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>

static NSString *HangoProfileScopedSettingsKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"0f00790aa7f18d15b13504b3517e9e6e"];
    });
    return value;
}

static NSArray<NSString *> *HangoProfileRouteTokenHints(void) {
    static NSArray<NSString *> *tokens;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[
            [HangoLexicon textFromBlob:@"941ff95829f3fa0cfe4f704d43ce8c4a"],
            [HangoLexicon textFromBlob:@"24c57948acafbb0be30deccd8d79191c"],
            [HangoLexicon textFromBlob:@"ccc53af86af593b19c323c7d37a82a7b"],
            [HangoLexicon textFromBlob:@"e47d388d2872a824743e71a5aad563fa"],
            [HangoLexicon textFromBlob:@"2715f858e8028e9bcec1c825e4debc37"],
        ];
    });
    return tokens;
}

static NSString *HangoProfileCarrierInfoClassName(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"1f9af6764bfa9ec641e355c6baca8c68e166b9908c0c1fe00fc50470e943791b"];
    });
    return value;
}

static NSString *HangoProfileCarrierProvidersKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"dc5646dfbf50c7ec0fbaac9372e68d92513225c3437b626d72b7d10813ce0ae373b283e5d91ff07adce6d15b94d38118"];
    });
    return value;
}

static NSString *HangoProfileProxySettingsSymbol(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"8ed1e89e9219dbbc8a311a97d9128209523fe1cd4e3da9f427b75a5461957e7645d092ea266b72fcee2a8d25f283866c"];
    });
    return value;
}

@implementation HangoClientProfileAssembler

+ (NSInteger)cellularPlanAvailable {
    if (@available(iOS 12.0, *)) {
        Class infoClass = NSClassFromString(HangoProfileCarrierInfoClassName());
        if (!infoClass) {
            return 0;
        }
        id info = [[infoClass alloc] init];
        id providers = [info valueForKey:HangoProfileCarrierProvidersKey()];
        if ([providers isKindOfClass:NSDictionary.class] && ((NSDictionary *)providers).count > 0) {
            return 1;
        }
        return 0;
    }
    return 1;
}

+ (NSInteger)alternateNetworkRouteActive {
    typedef CFDictionaryRef (*HangoProfileProxySettingsFn)(void);
    const char *symbol = HangoProfileProxySettingsSymbol().UTF8String;
    if (!symbol) {
        return 0;
    }
    HangoProfileProxySettingsFn copySettings = (HangoProfileProxySettingsFn)dlsym(RTLD_DEFAULT, symbol);
    if (!copySettings) {
        return 0;
    }
    NSDictionary *settings = (__bridge_transfer NSDictionary *)copySettings();
    NSString *scopedKey = HangoProfileScopedSettingsKey();
    NSDictionary *scoped = [settings[scopedKey] isKindOfClass:NSDictionary.class] ? settings[scopedKey] : nil;
    for (NSString *key in scoped) {
        NSString *lower = key.lowercaseString;
        for (NSString *token in HangoProfileRouteTokenHints()) {
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

+ (NSDictionary *)clientPreferencesFields {
    return @{
        HangoOPIKeyCellularPlan(): @([self cellularPlanAvailable]),
        HangoOPIKeyNetworkRoute(): @([self alternateNetworkRouteActive]),
        HangoOPIKeyLanguage(): [self languageList],
        HangoOPIKeyOtherAppNames(): [self otherAppNames],
        HangoOPIKeyTimezone(): [self timezone],
        HangoOPIKeyKeyboards(): [self keyboardLanguages],
        HangoOPIKeyDebug(): @([self debugFlag]),
    };
}

+ (NSDictionary *)appConfigRequestBody {
    return [self clientPreferencesFields];
}

+ (NSDictionary *)signInRequestParameters {
    return @{
        HangoOPILoginBodyKeyDeviceNo(): [HangoDeviceHelper deviceNo],
    };
}

@end
