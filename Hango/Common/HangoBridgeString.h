#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NSString *HangoBridgePrimaryChannel(void);
NSString *HangoBridgeCloseChannel(void);
NSString *HangoBridgeOpenBrowserChannel(void);
NSArray<NSString *> *HangoBridgeRegisteredChannelNames(void);

NSString *HangoBridgeResultEvent(void);
NSString *HangoBridgeFailureCode(void);
NSString *HangoBridgeWelcomePageOpenStateEvent(void);
NSString *HangoBridgeTraceKey(void);
NSString *HangoBridgeBatchKey(void);
NSString *HangoBridgeOpenURLKey(void);

NS_ASSUME_NONNULL_END
