#import <Foundation/Foundation.h>
#import "HangoOPIString.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const HangoAPIHost;
FOUNDATION_EXPORT NSString * const HangoAppId;
FOUNDATION_EXPORT NSString * const HangoAESKey;
FOUNDATION_EXPORT NSString * const HangoAESIV;
/// Adjust attribution SDK app token. Replace with the real token from the
/// Adjust dashboard before release.
FOUNDATION_EXPORT NSString * const HangoAdjustAppToken;
/// NO for production (`ADJEnvironmentProduction`), YES for sandbox testing.
FOUNDATION_EXPORT BOOL const HangoAdjustUseSandbox;
/// Adjust event token fired once on first install (attribution callback).
FOUNDATION_EXPORT NSString * const HangoAdjustEventInstall;
/// Adjust event token fired on a successful purchase (with revenue).
FOUNDATION_EXPORT NSString * const HangoAdjustEventPurchase;

FOUNDATION_EXPORT NSString * const HangoWebsiteHost;
FOUNDATION_EXPORT NSString * const HangoWebsiteURLString;
FOUNDATION_EXPORT NSString * const HangoAPIBaseURLString;
FOUNDATION_EXPORT NSString * const HangoPersonaAgreementURLString;
FOUNDATION_EXPORT NSString * const HangoPrivacyPolicyURLString;

FOUNDATION_EXPORT NSString * const HangoAPIPathAppConfig;

/// Fallback portal gate epoch when remote config is unavailable (Unix timestamp).
FOUNDATION_EXPORT NSTimeInterval HangoPortalGateEpoch(void);

NS_ASSUME_NONNULL_END
