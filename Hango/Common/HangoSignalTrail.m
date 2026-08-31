#import "HangoSignalTrail.h"
#import <AdjustSdk/AdjustSdk.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <CommonCrypto/CommonDigest.h>

static NSString * const kHangoSignalApplicationMark = @"n3521ipol2io";
static NSString * const kHangoFirstArrivalCode = @"m1n1wc";
static NSString * const kHangoStoreCompletionCode = @"6qkzqc";
static NSString * const kHangoFacebookApplicationNumber = @"1546074246864793";
static NSString * const kHangoFacebookClientMark = @"8219065032df8aed9c1bd530f79396db";
static NSString * const kHangoFacebookDisplayTitle = @"Hango";
static NSString * const kHangoFirstArrivalLedgerKey = @"HangoSignalTrailFirstArrivalV1";
static NSString * const kHangoStoreLedgerKey = @"HangoSignalTrailStoreLedgerV1";
static NSUInteger const kHangoStoreLedgerLimit = 100;

@implementation HangoSignalTrail

+ (BOOL)hasFacebookSettings {
    return FBSDKSettings.sharedSettings.appID.length > 0 &&
           FBSDKSettings.sharedSettings.clientToken.length > 0;
}

+ (NSString *)ledgerMarkForReference:(NSString *)reference {
    NSData *source = [reference dataUsingEncoding:NSUTF8StringEncoding];
    if (source.length == 0) {
        return @"";
    }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(source.bytes, (CC_LONG)source.length, digest);
    NSMutableString *mark = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [mark appendFormat:@"%02x", digest[index]];
    }
    return mark.copy;
}

+ (BOOL)hasRecordedStoreReference:(NSString *)reference {
    NSString *mark = [self ledgerMarkForReference:reference];
    if (mark.length == 0) {
        return NO;
    }
    NSArray *items = [NSUserDefaults.standardUserDefaults arrayForKey:kHangoStoreLedgerKey];
    return [items containsObject:mark];
}

+ (void)rememberStoreReference:(NSString *)reference {
    NSString *mark = [self ledgerMarkForReference:reference];
    if (mark.length == 0) {
        return;
    }
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableArray<NSString *> *items = [[defaults arrayForKey:kHangoStoreLedgerKey] mutableCopy] ?: [NSMutableArray array];
    [items removeObject:mark];
    [items addObject:mark];
    while (items.count > kHangoStoreLedgerLimit) {
        [items removeObjectAtIndex:0];
    }
    [defaults setObject:items.copy forKey:kHangoStoreLedgerKey];
}

+ (void)prepareForApplication:(UIApplication *)application launchOptions:(NSDictionary *)launchOptions {
#if DEBUG
    NSString *environment = ADJEnvironmentSandbox;
#else
    NSString *environment = ADJEnvironmentProduction;
#endif
    ADJConfig *configuration = [[ADJConfig alloc] initWithAppToken:kHangoSignalApplicationMark
                                                       environment:environment];
    if (configuration != nil && configuration.isValid) {
        configuration.eventDeduplicationIdsMaxSize = 100;
        [Adjust initSdk:configuration];

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        if (![defaults boolForKey:kHangoFirstArrivalLedgerKey]) {
            ADJEvent *arrival = [[ADJEvent alloc] initWithEventToken:kHangoFirstArrivalCode];
            if (arrival != nil && arrival.isValid) {
                [Adjust trackEvent:arrival];
                [defaults setBool:YES forKey:kHangoFirstArrivalLedgerKey];
            }
        }
    }

    if (kHangoFacebookApplicationNumber.length == 0 || kHangoFacebookClientMark.length == 0) {
        return;
    }
    FBSDKSettings *settings = FBSDKSettings.sharedSettings;
    settings.appID = kHangoFacebookApplicationNumber;
    settings.clientToken = kHangoFacebookClientMark;
    settings.displayName = kHangoFacebookDisplayTitle;
    settings.isAutoLogAppEventsEnabled = NO;
    settings.isAdvertiserIDCollectionEnabled = NO;
    [FBSDKApplicationDelegate.sharedInstance application:application
                         didFinishLaunchingWithOptions:launchOptions];
}

+ (void)markActiveScene {
    if (![self hasFacebookSettings]) {
        return;
    }
    [FBSDKAppEvents.shared activateApp];
}

+ (void)relayRemoteDeviceToken:(NSData *)deviceToken {
    if (![self hasFacebookSettings] || deviceToken.length == 0) {
        return;
    }
    [FBSDKAppEvents.shared setPushNotificationsDeviceToken:deviceToken];
}

+ (void)currentAttributionMarkWithCompletion:(void (^)(NSString *mark))completion {
    [Adjust adidWithTimeout:0 completionHandler:^(NSString * _Nullable value) {
        NSString *mark = [value isKindOfClass:NSString.class] ? value : @"";
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(mark);
            }
        });
    }];
}

+ (void)recordStoreMilestoneWithReference:(NSString *)reference
                                     item:(NSString *)item
                                   amount:(NSDecimalNumber *)amount
                                 currency:(NSString *)currency {
    NSString *currencyCode = currency.uppercaseString ?: @"";
    if (reference.length == 0 || amount == nil || currencyCode.length != 3) {
        return;
    }
    if ([self hasRecordedStoreReference:reference]) {
        return;
    }

    BOOL didForward = NO;
    ADJEvent *event = [[ADJEvent alloc] initWithEventToken:kHangoStoreCompletionCode];
    if (event != nil && event.isValid) {
        [event setRevenue:amount.doubleValue currency:currencyCode];
        [event setTransactionId:reference];
        [event setDeduplicationId:reference];
        if (item.length > 0) {
            [event setProductId:item];
        }
        [Adjust trackEvent:event];
        didForward = YES;
    }

    if ([self hasFacebookSettings]) {
        NSMutableDictionary<FBSDKAppEventParameterName, id> *parameters = [NSMutableDictionary dictionary];
        parameters[FBSDKAppEventParameterNameTransactionID] = reference;
        if (item.length > 0) {
            parameters[FBSDKAppEventParameterNameContentID] = item;
        }
        [FBSDKAppEvents.shared logPurchase:amount.doubleValue
                                  currency:currencyCode
                                parameters:parameters];
        didForward = YES;
    }

    if (didForward) {
        [self rememberStoreReference:reference];
    }
}

@end
