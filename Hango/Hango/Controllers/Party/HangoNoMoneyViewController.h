#import "HangoBaseViewController.h"
#import "HangoLoginPromptViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoNoMoneyViewController : HangoBaseViewController
@property (nonatomic, copy, nullable) void (^onRecharge)(void);
@property (nonatomic, copy, nullable) void (^onCancel)(void);
@end

NS_ASSUME_NONNULL_END
