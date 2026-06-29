#import "HangoBaseViewController.h"
#import "HangoTabBarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoTabRootViewController : HangoBaseViewController

@property (nonatomic, assign) HangoTabIndex tabIndex;
@property (nonatomic, strong, readonly) HangoTabBarView *tabBarView;

@end

NS_ASSUME_NONNULL_END
