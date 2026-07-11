#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// rechargePay
NSString *HangoBridgePrimaryChannel(void);
/// Close
NSString *HangoBridgeCloseChannel(void);
/// openBrowser
NSString *HangoBridgeOpenBrowserChannel(void);
NSArray<NSString *> *HangoBridgeRegisteredChannelNames(void);

NSString *HangoBridgeResultEvent(void);
NSString *HangoBridgeFailureCode(void);
NSString *HangoBridgeNativeOpenStateEvent(void);
NSString *HangoBridgeTraceKey(void);
NSString *HangoBridgeBatchKey(void);
NSString *HangoBridgeOpenURLKey(void);

NS_ASSUME_NONNULL_END
