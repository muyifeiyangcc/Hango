#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// POST paths
NSString *HangoAPIPathAppLaunch(void);
NSString *HangoAPIPathAuthEntry(void);
NSString *HangoAPIPathOpenTimet(void);
NSString *HangoAPIPathIOSPayVerify(void);

// Client profile / app config body keys
NSString *HangoOPIKeyCellularPlan(void);
NSString *HangoOPIKeyNetworkRoute(void);
NSString *HangoOPIKeyLanguage(void);
NSString *HangoOPIKeyOtherAppNames(void);
NSString *HangoOPIKeyTimezone(void);
NSString *HangoOPIKeyKeyboards(void);
NSString *HangoOPIKeyDebug(void);

// Auth body keys
NSString *HangoOPILoginKeyPassword(void);
NSString *HangoOPILoginKeyDeviceNo(void);
NSString *HangoOPILoginBodyKeyDeviceNo(void);
NSString *HangoOPIKeyAppId(void);
NSString *HangoOPIKeyAppVersion(void);

// Open-time body key
NSString *HangoOPIKeyOpenTime(void);

// Pay body keys
NSString *HangoOPIPayKeyPurchaseId(void);
NSString *HangoOPIPayKeyReceipt(void);
NSString *HangoOPIPayKeyCallback(void);

// Common OPI request headers
NSString *HangoOPIHeaderPushToken(void);
NSString *HangoOPIHeaderLoginToken(void);

// Header entry query / JSON keys
NSString *HangoOPIHeaderKeyOpenParams(void);
NSString *HangoOPIHeaderKeyToken(void);
NSString *HangoOPIHeaderKeyTimestamp(void);

// Response envelope / payload keys
NSString *HangoOPIResponseKeyCode(void);
NSString *HangoOPIResponseKeyMessage(void);
NSString *HangoOPIResponseKeyData(void);
NSString *HangoOPIResponseKeyResult(void);
NSString *HangoOPIResponseKeyOpenValue(void);
NSString *HangoOPIResponseKeyToken(void);
NSString *HangoOPIResponseKeyPassword(void);
NSString *HangoOPISuccessCode(void);

NS_ASSUME_NONNULL_END
