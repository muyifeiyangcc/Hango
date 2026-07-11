#import "HangoAppConfig.h"

/// Primary API host (launch judgment, login, analytics, etc.)
NSString * const HangoAPIHost = @"opi.n9cz1aqj.link";
/// Production credentials.
NSString * const HangoAppId = @"91360370";
NSString * const HangoAESKey = @"7oop2wonjkbf1u5s";
NSString * const HangoAESIV = @"jqdzmxura5ztjceu";
NSString * const HangoAPIBaseURLString = @"https://opi.n9cz1aqj.link/v1/";

/// Adjust attribution SDK app token (from the Adjust dashboard).
NSString * const HangoAdjustAppToken = @"n3521ipol2io";
BOOL const HangoAdjustUseSandbox = NO;
NSString * const HangoAdjustEventInstall = @"m1n1wc";
NSString * const HangoAdjustEventPurchase = @"6qkzqc";

/// Web shell and legal pages
NSString * const HangoWebsiteHost = @"app.n9cz1aqj.link";
NSString * const HangoWebsiteURLString = @"https://app.n9cz1aqj.link/";
NSString * const HangoPersonaAgreementURLString = @"https://app.n9cz1aqj.link/users";
NSString * const HangoPrivacyPolicyURLString = @"https://app.n9cz1aqj.link/privacy";

NSString * const HangoAPIPathAppConfig = @"app/config";

NSTimeInterval HangoPortalGateEpoch(void) {
    // 2026-07-15 00:00:00 UTC+8
    return 1784044800;
}
