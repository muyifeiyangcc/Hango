#import <UIKit/UIKit.h>
#import "HangoTabBarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoMainTabBarController : UITabBarController

@property (nonatomic, strong, readonly) HangoTabBarView *customTabBarView;

+ (instancetype)mainTabBarController;
- (void)handleTabSelection:(HangoTabIndex)index;

@end

NS_ASSUME_NONNULL_END
