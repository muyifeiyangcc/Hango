#import "HangoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoPurchaseDecorViewController : HangoBaseViewController
@property (nonatomic, copy, nullable) NSString *decorImageName;
@property (nonatomic, copy, nullable) void (^onPurchase)(void);
@property (nonatomic, copy, nullable) void (^onRecharge)(void);
@property (nonatomic, copy, nullable) void (^onCancel)(void);
@end

NS_ASSUME_NONNULL_END
