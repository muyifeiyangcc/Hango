//
//  AppDelegate.h
//  Hango
//
//  Created by myfy on 2026/6/29.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/// Facebook / Adjust — deferred until after launcho so launch is the first network use.
- (void)startDeferredSDKs;

/// Resolves the Adjust adid for login (cached, or fetched via Adjust SDK).
- (void)resolveAdjustAdidWithCompletion:(void (^)(NSString *adid))completion;

@end
