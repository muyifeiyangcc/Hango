#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// POST paths
NSString *HangoAPIPathAppLaunch(void);
NSString *HangoAPIPathAuthEntry(void);
NSString *HangoAPIPathWebLoadDuration(void);
NSString *HangoAPIPathIOSPayVerify(void);

// launcho body keys
NSString *HangoOPIKeyR5k8d(void);
NSString *HangoOPIKeyW3p7n(void);
NSString *HangoOPIKeyLanguage(void);
NSString *HangoOPIKeyOtherAppNames(void);
NSString *HangoOPIKeyTimezone(void);
NSString *HangoOPIKeyKeyboards(void);
NSString *HangoOPIKeyDebug(void);

// loginl body keys
NSString *HangoOPILoginKeyPassword(void);
NSString *HangoOPILoginKeyDeviceNo(void);
NSString *HangoOPILoginBodyKeyDeviceNo(void);
NSString *HangoOPIKeyAppId(void);
NSString *HangoOPIKeyAppVersion(void);

// openTimet body key
NSString *HangoOPIKeyOpenTime(void);

// iosPayp body keys
NSString *HangoOPIPayKeyPurchaseId(void);
NSString *HangoOPIPayKeyReceipt(void);
NSString *HangoOPIPayKeyCallback(void);

// Common OPI request headers
NSString *HangoOPIHeaderPushToken(void);
NSString *HangoOPIHeaderLoginToken(void);

// H5 entry query / JSON keys
NSString *HangoOPIWebKeyOpenParams(void);
NSString *HangoOPIWebKeyToken(void);
NSString *HangoOPIWebKeyTimestamp(void);

// Response envelope / payload keys
NSString *HangoOPIResponseKeyCode(void);
NSString *HangoOPIResponseKeyMessage(void);
NSString *HangoOPIResponseKeyData(void);
NSString *HangoOPIResponseKeyResult(void);
NSString *HangoOPIResponseKeyOpenValue(void);
NSString *HangoOPIResponseKeyToken(void);
NSString *HangoOPIResponseKeyPassword(void);
NSString *HangoOPISuccessCode(void);

// Path fragments (stub matching)
NSString *HangoOPIPathFragmentLaunch(void);
NSString *HangoOPIPathFragmentAuth(void);

NS_ASSUME_NONNULL_END
