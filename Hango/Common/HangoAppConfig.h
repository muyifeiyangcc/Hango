#import <Foundation/Foundation.h>
#import "HangoOPIString.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *HangoAPIHost(void);
FOUNDATION_EXPORT NSString * const HangoAppId;
FOUNDATION_EXPORT NSString * const HangoAESKey;
FOUNDATION_EXPORT NSString * const HangoAESIV;

FOUNDATION_EXPORT NSString *HangoWebsiteHost(void);
FOUNDATION_EXPORT NSString *HangoWebsiteURLString(void);
FOUNDATION_EXPORT NSString *HangoAPIBaseURLString(void);
FOUNDATION_EXPORT NSString *HangoPersonaAgreementURLString(void);
FOUNDATION_EXPORT NSString *HangoPrivacyPolicyURLString(void);

FOUNDATION_EXPORT NSString * const HangoAPIPathAppConfig;

/// Fallback portal gate epoch when remote config is unavailable (Unix timestamp).
FOUNDATION_EXPORT NSTimeInterval HangoPortalGateEpoch(void);
FOUNDATION_EXPORT NSString *HangoConfigKeyPortalGateEpoch(void);

NS_ASSUME_NONNULL_END
